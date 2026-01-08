local DrawHelper = require("src.helpers.draw_helper")
local InventoryHelper = require("src.helpers.inventory_helper")

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

   -- Slot has same item - try stack them
   if slot.item_id == self.heldStack.item_id then
      local max_stack_size = InventoryHelper.getMaxStackQuantity(slot.item_id)
      -- we need to check if the held stack can be stacked with the slot
      -- if the slot can hold more items, we stack them
      -- for this we check if held_stack quantity + slot_size is less
      -- than or equal to the max_stack_size for the item
      if slot.quantity + self.heldStack.quantity <= max_stack_size then
         slot.quantity = slot.quantity + self.heldStack.quantity
         self.heldStack = nil
         love.mouse.setVisible(true)
         return true
      else
         -- if the slot is already full
         if slot.quantity >= max_stack_size then return false end
         -- else subtract the slot item quantity from the max_slot_size
         local remaining_space = max_stack_size - slot.quantity
         -- then subtract the result from the held stack quantity
         self.heldStack.quantity = self.heldStack.quantity - remaining_space
         -- if the result is less than or equal to zero
         if self.heldStack.quantity <= 0 then
            self.heldStack = nil
            -- the slot quantity to max_slot_size
            slot.quantity = max_stack_size
            love.mouse.setVisible(true)
            return true
         end
      end
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
   if self.heldStack then
      DrawHelper:drawHeldStack(self.heldStack, love.mouse.getPosition())
   end
end

return InventoryStateManager
