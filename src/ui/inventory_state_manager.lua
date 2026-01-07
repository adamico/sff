local InventoryLayout = require("src.config.inventory_layout")

local InventoryStateManager = {
   isOpen = false,
   playerInventory = nil,
   targetInventory = nil,
   layout = InventoryLayout,
   positions = nil,
   heldStack = nil,
}

function InventoryStateManager:open(player_inventory, target_inventory)
   self.isOpen = true
   self.playerInventory = player_inventory
   self.targetInventory = target_inventory or nil
   self.positions = self.layout:getInventoryPositions(target_inventory ~= nil)
end

function InventoryStateManager:close()
   self.isOpen = false
   self.playerInventory = nil
   self.targetInventory = nil
   self.positions = nil
   self.heldStack = nil
end

--- Detect which slot was clicked based on mouse coordinates
--- @param mouse_x number Mouse x position
--- @param mouse_y number Mouse y position
--- @return table|nil Slot info {inventory_type = "player"|"target", slot_index = number, item = table|nil}
function InventoryStateManager:getSlotAt(mouse_x, mouse_y)
   if not self.isOpen or not self.positions then
      return nil
   end

   -- Check player inventory
   local player_slot = self:checkInventorySlots(
      mouse_x, mouse_y,
      self.positions.player.x,
      self.positions.player.y,
      self.playerInventory.input_slots
   )

   if player_slot then
      return {
         inventory_type = "player",
         slot_index = player_slot.index,
         item = player_slot.item
      }
   end

   -- Check target inventory if it exists
   if self.targetInventory and self.positions.target then
      local target_slot = self:checkInventorySlots(
         mouse_x, mouse_y,
         self.positions.target.x,
         self.positions.target.y,
         self.targetInventory.input_slots
      )

      if target_slot then
         return {
            inventory_type = "target",
            slot_index = target_slot.index,
            item = target_slot.item
         }
      end
   end

   return nil
end

--- Check if mouse is over any slot in an inventory
--- @param mouse_x number Mouse x position
--- @param mouse_y number Mouse y position
--- @param base_x number Inventory base x position
--- @param base_y number Inventory base y position
--- @param slots table Array of slots
--- @return table|nil Slot info {index = number, item = table|nil}
function InventoryStateManager:checkInventorySlots(mouse_x, mouse_y, base_x, base_y, slots)
   for i = 1, #slots do
      local slot_x, slot_y = self.layout:getSlotPosition(i, base_x, base_y)

      if self.layout:isPointInSlot(mouse_x, mouse_y, slot_x, slot_y) then
         return {
            index = i,
            item = slots[i].item_id and slots[i] or nil
         }
      end
   end

   return nil
end

--- Handle a click on an inventory slot (main entry point for click logic)
--- @param slot_index number The slot index that was clicked
--- @param inventory_type string "player" or "target"
--- @return boolean Success
function InventoryStateManager:handleSlotClick(slot_index, inventory_type)
   local inventory = inventory_type == "player" and self.playerInventory or self.targetInventory
   if not inventory then return false end

   local slot = inventory.input_slots[slot_index]
   if not slot then return false end

   -- If holding an item, try to place/swap/stack
   if self.heldStack then
      return self:placeItemInSlot(slot_index, inventory_type)
   else
      -- Not holding anything, try to pick up
      if slot.item_id then
         return self:pickItemFromSlot(slot_index, inventory_type) ~= nil
      end
   end

   return false
end

--- Pick up an item from a slot (internal method - assumes heldStack is nil)
--- @param slot_index number The slot index to pick from
--- @param inventory_type string "player" or "target"
--- @return table|nil The picked item stack
function InventoryStateManager:pickItemFromSlot(slot_index, inventory_type)
   local inventory = inventory_type == "player" and self.playerInventory or self.targetInventory
   if not inventory then return nil end

   local slot = inventory.input_slots[slot_index]
   if not slot or not slot.item_id then return nil end

   -- Pick up the entire stack
   self.heldStack = {
      item_id = slot.item_id,
      quantity = slot.quantity,
      source_inventory = inventory_type,
      source_slot = slot_index
   }

   -- Clear the slot
   slot.item_id = nil
   slot.quantity = 0

   -- Hide the mouse cursor
   love.mouse.setVisible(false)
   return self.heldStack
end

--- Place the held item into a slot (handles empty slots, stacking, and swapping)
--- @param slot_index number The slot index to place into
--- @param inventory_type string "player" or "target"
--- @return boolean Success
function InventoryStateManager:placeItemInSlot(slot_index, inventory_type)
   if not self.heldStack then return false end

   local inventory = inventory_type == "player" and self.playerInventory or self.targetInventory
   if not inventory then return false end

   local slot = inventory.input_slots[slot_index]
   if not slot then return false end

   -- Empty slot - place the item
   if not slot.item_id then
      slot.item_id = self.heldStack.item_id
      slot.quantity = self.heldStack.quantity
      self.heldStack = nil
      love.mouse.setVisible(true)
      return true
   end

   -- Slot has same item - stack them
   if slot.item_id == self.heldStack.item_id then
      -- TODO: Add max stack size logic here
      slot.quantity = slot.quantity + self.heldStack.quantity
      self.heldStack = nil
      return true
   end

   -- Slot has different item - swap them
   local temp = {
      item_id = slot.item_id,
      quantity = slot.quantity
   }

   slot.item_id = self.heldStack.item_id
   slot.quantity = self.heldStack.quantity

   self.heldStack.item_id = temp.item_id
   self.heldStack.quantity = temp.quantity
   self.heldStack.source_inventory = inventory_type
   self.heldStack.source_slot = slot_index

   return true
end

--- Drop the held item (return it to its source or discard it)
function InventoryStateManager:dropHeldItem()
   if not self.heldStack then return end

   -- Try to return to source slot if it exists
   if self.heldStack.source_inventory and self.heldStack.source_slot then
      local success = self:placeItemInSlot(
         self.heldStack.source_slot,
         self.heldStack.source_inventory
      )
      if success then return end
   end

   -- TODO: Handle dropping item (maybe emit an event or find empty slot)
   self.heldStack = nil
end

return InventoryStateManager
