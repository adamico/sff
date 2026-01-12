local InventoryHelper = require("src.helpers.inventory_helper")
local HeldStackView = require("src.ui.held_stack_view")

local MachineStateManager = {
   isOpen = false,
   screen = nil,
   views = {}, -- Inventory views (player inventory, toolbar)
   heldStack = nil,
   heldStackView = nil,
}

--- Open the machine screen along with inventory views
--- @param screen table The MachineScreen instance
--- @param views table Array of InventoryView instances (player inventory, toolbar)
function MachineStateManager:open(screen, views)
   self.isOpen = true
   self.screen = screen
   self.views = views or {}
end

function MachineStateManager:close()
   if self.heldStack then
      self:returnHeldStack()
      love.mouse.setVisible(true)
   end

   -- Destroy held stack view
   if self.heldStackView then
      self.heldStackView:destroy()
      self.heldStackView = nil
   end

   -- Destroy FlexLove elements
   if self.screen and self.screen.destroy then
      self.screen:destroy()
   end

   -- Destroy view elements (except toolbar which is always visible)
   for _, view in ipairs(self.views) do
      if view and view.destroy then
         -- Don't destroy toolbar - it's managed separately by render_ui_system
         if view.id ~= "toolbar" then
            view:destroy()
         end
      end
   end

   self.heldStack = nil
   self.isOpen = false
   self.screen = nil
   self.views = {}
end

function MachineStateManager:returnHeldStack()
   local held_stack = self.heldStack
   if held_stack and held_stack.source_inventory then
      local slotType = held_stack.source_slot_type
      local slot = InventoryHelper.getSlot(held_stack.source_inventory, held_stack.source_slot, slotType)
      if slot then
         slot.item_id = held_stack.item_id
         slot.quantity = held_stack.quantity
      end
   end
end

--- Get slot info under mouse from machine screen or inventory views
--- @param mouse_x number
--- @param mouse_y number
--- @return table|nil slot_info with inventory reference
function MachineStateManager:getSlotUnderMouse(mouse_x, mouse_y)
   -- Check machine screen first
   if self.screen then
      local slot_info = self.screen:getSlotUnderMouse(mouse_x, mouse_y)
      if slot_info then
         -- Add inventory reference for machine screen slots
         slot_info.inventory = self:getMachineInventory()
         slot_info.source = "machine"
         return slot_info
      end
   end

   -- Check inventory views
   for _, view in ipairs(self.views) do
      local slot_info = view:getSlotUnderMouse(mouse_x, mouse_y)
      if slot_info then
         slot_info.inventory = view.inventory
         slot_info.source = "inventory"
         return slot_info
      end
   end

   return nil
end

function MachineStateManager:getMachineInventory()
   if not self.screen or not self.screen.entityId then return nil end
   return Evolved.get(self.screen.entityId, FRAGMENTS.Inventory)
end

--- Handle a click on any slot (machine or inventory)
--- @param mouse_x number The x position of the mouse
--- @param mouse_y number The y position of the mouse
--- @param userdata table|nil Optional userdata from clicked element (to avoid redundant hit detection)
--- @return boolean Success
function MachineStateManager:handleSlotClick(mouse_x, mouse_y, userdata)
   local slot_info

   -- If userdata provided (from slot element click), use it directly
   if userdata and userdata.slotIndex then
      if userdata.screen then
         -- Machine screen slot (has slotType)
         local screen = userdata.screen
         local slotIndex = userdata.slotIndex
         local slotType = userdata.slotType
         local inventory = screen:getInventory()
         if inventory then
            local slot = InventoryHelper.getSlot(inventory, slotIndex, slotType)
            if slot then
               slot_info = {
                  screen = screen,
                  inventory = inventory,
                  slotIndex = slotIndex,
                  slot = slot,
                  slotType = slotType
               }
            end
         end
      elseif userdata.view then
         -- Inventory view slot (no slotType, uses .slots)
         local view = userdata.view
         local slotIndex = userdata.slotIndex
         local slots = view.inventory.slots
         if slots and slots[slotIndex] then
            slot_info = {
               view = view,
               inventory = view.inventory,
               slotIndex = slotIndex,
               slot = slots[slotIndex],
               slotType = nil -- No slot type for simple inventories
            }
         end
      end
   else
      -- Fallback: do hit detection (for clicks not from slot elements)
      slot_info = self:getSlotUnderMouse(mouse_x, mouse_y)
   end

   if not slot_info then return false end

   local inventory = slot_info.inventory
   if not inventory then return false end

   local slot_index = slot_info.slotIndex
   local slotType = slot_info.slotType -- Can be nil for simple inventories
   local slot = slot_info.slot

   -- If holding an item, try to place/swap/stack
   if self.heldStack then
      return self:placeItemInSlot(slot_index, slotType, inventory)
   elseif slot and slot.item_id then
      return self:pickItemFromSlot(slot_index, slotType, inventory)
   end

   return false
end

--- Pick up an item from a slot (internal method - assumes heldStack is nil)
--- @param slot_index number The slot index to pick from
--- @param slotType string|nil The type of slot (input, output, catalyst) or nil for simple inventories
--- @param inventory table The inventory to pick from
--- @return boolean Success
function MachineStateManager:pickItemFromSlot(slot_index, slotType, inventory)
   -- Handle both typed slots (machine) and simple slots (inventory)
   local slot = InventoryHelper.getSlot(inventory, slot_index, slotType)
   if not slot or not slot.item_id then return false end

   -- Pick up the entire stack
   self.heldStack = {
      item_id = slot.item_id,
      quantity = slot.quantity,
      source_inventory = inventory,
      source_slot = slot_index,
      source_slot_type = slotType,
   }

   -- Create held stack view
   self.heldStackView = HeldStackView:new(self.heldStack)

   -- Clear the slot
   slot.item_id = nil
   slot.quantity = 0
   love.mouse.setVisible(false)
   return true
end

--- Place the held item into a slot (handles empty slots, stacking, and swapping)
--- @param slot_index number The slot index to place into
--- @param slotType string|nil The type of slot or nil for simple inventories
--- @param inventory table The inventory to place into
--- @return boolean Success
function MachineStateManager:placeItemInSlot(slot_index, slotType, inventory)
   -- Handle both typed slots (machine) and simple slots (inventory)
   local slot = InventoryHelper.getSlot(inventory, slot_index, slotType)
   if not slot then return false end

   -- Empty slot - place the item
   if not slot.item_id then
      slot.item_id = self.heldStack.item_id
      slot.quantity = self.heldStack.quantity
      if self.heldStackView then
         self.heldStackView:destroy()
         self.heldStackView = nil
      end
      self.heldStack = nil
      love.mouse.setVisible(true)
      return true
   end

   -- Slot has same item - try stack them
   if slot.item_id == self.heldStack.item_id then
      local max_stack_size = InventoryHelper.getMaxStackQuantity(slot.item_id)
      if slot.quantity + self.heldStack.quantity <= max_stack_size then
         slot.quantity = slot.quantity + self.heldStack.quantity
         if self.heldStackView then
            self.heldStackView:destroy()
            self.heldStackView = nil
         end
         self.heldStack = nil
         love.mouse.setVisible(true)
         return true
      else
         if slot.quantity >= max_stack_size then return false end

         local remaining_space = max_stack_size - slot.quantity
         local new_held_quantity = self.heldStack.quantity - remaining_space
         self.heldStack = new_held_quantity <= 0 and nil or
            {
               item_id = self.heldStack.item_id,
               quantity = new_held_quantity,
               source_inventory = inventory,
               source_slot = slot_index,
               source_slot_type = slotType
            }
         slot.quantity = max_stack_size
         love.mouse.setVisible(true)
         return true
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
   self.heldStack.source_slot_type = slotType

   -- Update held stack view
   if self.heldStackView then
      self.heldStackView:updateStack(self.heldStack)
   end
   return true
end

function MachineStateManager:draw()
   -- Draw inventory views first (they appear below machine screen)
   for _, view in ipairs(self.views) do
      if view then
         view:draw()
      end
   end

   -- Draw machine screen on top
   if self.screen then
      self.screen:draw()
   end
end

--- Draw the held stack (should be called AFTER FlexLove.draw())
function MachineStateManager:drawHeldStack()
   if self.heldStackView then
      self.heldStackView:draw()
   end
end

function MachineStateManager:update(dt)
   -- Update held stack view position to follow cursor
   if self.heldStackView then
      self.heldStackView:update(dt)
   end
end

return MachineStateManager
