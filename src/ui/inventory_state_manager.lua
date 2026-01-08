local SLOT_SIZE = 32
local BORDER_COLOR = {1, 1, 1, 0.8}
local BACKGROUND_COLOR = {0.5, 0.45, 0.5, 0.8}

local InventoryStateManager = {
   isOpen = false,
   views = {}, -- Array of active InventoryView instances
   heldStack = nil,
}

function InventoryStateManager:open(views)
   self.isOpen = true
   self.views = views or {}
end

function InventoryStateManager:close()
   if self.heldStack then
      self:returnHeldStack()
      love.mouse.setVisible(true)
   end

   self.heldStack = nil
   self.isOpen = false
   self.views = {}
end

function InventoryStateManager:returnHeldStack()
   local held_stack = self.heldStack
   if held_stack and held_stack.source_inventory then
      local slot = held_stack.source_inventory.input_slots[held_stack.source_slot]
      if slot then
         slot.item_id = held_stack.item_id
         slot.quantity = held_stack.quantity
      end
   end
end

function InventoryStateManager:getSlotUnderMouse(mouse_x, mouse_y)
   for _, view in ipairs(self.views) do
      local slot_info = view:getSlotUnderMouse(mouse_x, mouse_y)
      if slot_info then
         return slot_info
      end
   end
   return nil
end

--- Handle a click on an inventory slot (main entry point for click logic)
--- @param mouse_x number The x position of the mouse_x
--- @param mouse_y number The y position of the mouse_y
--- @return boolean Success
function InventoryStateManager:handleSlotClick(mouse_x, mouse_y)
   local slot_info = self:getSlotUnderMouse(mouse_x, mouse_y)
   if not slot_info then return false end

   local inventory = slot_info.view.inventory
   local slot_index = slot_info.slotIndex
   local slot = slot_info.slot

   -- If holding an item, try to place/swap/stack
   if self.heldStack then
      return self:placeItemInSlot(slot_index, inventory)
   elseif slot.item_id then
      return self:pickItemFromSlot(slot_index, inventory)
   end

   return false
end

--- Pick up an item from a slot (internal method - assumes heldStack is nil)
--- @param slot_index number The slot index to pick from
--- @param inventory InventoryComponent The inventory to pick from
--- @return boolean Success
function InventoryStateManager:pickItemFromSlot(slot_index, inventory)
   local slot = inventory.input_slots[slot_index]
   if not slot or not slot.item_id then return false end

   -- Pick up the entire stack
   self.heldStack = {
      item_id = slot.item_id,
      quantity = slot.quantity,
      source_inventory = inventory,
      source_slot = slot_index
   }

   -- Clear the slot
   slot.item_id = nil
   slot.quantity = 0
   love.mouse.setVisible(false)
   return true
end

--- Place the held item into a slot (handles empty slots, stacking, and swapping)
--- @param inventory InventoryComponent The inventory to place into
--- @param slot_index number The slot index to place into
--- @return boolean Success
function InventoryStateManager:placeItemInSlot(slot_index, inventory)
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
      love.mouse.setVisible(true)
      return true
   end

   -- Slot has different item - swap them
   local temp = {item_id = slot.item_id, quantity = slot.quantity}
   slot.item_id = self.heldStack.item_id
   slot.quantity = self.heldStack.quantity
   self.heldStack.item_id = temp.item_id
   self.heldStack.quantity = temp.quantity
   self.heldStack.source_inventory = inventory
   self.heldStack.source_slot = slot_index
   return true
end

function InventoryStateManager:draw()
   for _, view in ipairs(self.views) do
      view:draw()
   end
   self:drawHeldStack()
end

function InventoryStateManager:drawHeldStack()
   if not self.heldStack then return end

   local lg = love.graphics
   local mx, my = love.mouse.getPosition()
   local size = SLOT_SIZE
   local offset = size / 2
   lg.setColor(BORDER_COLOR)
   lg.rectangle("fill", mx - offset, my - offset, size, size)
   lg.setColor(BACKGROUND_COLOR)
   lg.rectangle("fill", mx - offset + 2, my - offset + 2, size - 4, size - 4)
   lg.setColor(1, 1, 1)
   lg.print(string.sub(self.heldStack.item_id, 1, 1), mx - offset + 2, my - offset + 2)
   if self.heldStack.quantity and self.heldStack.quantity > 1 then
      lg.print(tostring(self.heldStack.quantity), mx, my)
   end
end

return InventoryStateManager
