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
   local heldStack = self.heldStack
   if heldStack and heldStack.sourceInventory then
      local slotType = heldStack.sourceSlotType
      local slot = InventoryHelper.getSlot(heldStack.sourceInventory, heldStack.sourceSlot, slotType)
      if slot then
         slot.itemId = heldStack.itemId
         slot.quantity = heldStack.quantity
      end
   end
end

--- Get slot info under mouse from machine screen or inventory views
--- @param mouse_x number
--- @param mouse_y number
--- @return table|nil slotInfo with inventory reference
function MachineStateManager:getSlotUnderMouse(mouse_x, mouse_y)
   -- Check machine screen first
   if self.screen then
      local slotInfo = self.screen:getSlotUnderMouse(mouse_x, mouse_y)
      if slotInfo then
         -- Add inventory reference for machine screen slots
         slotInfo.inventory = self:getMachineInventory()
         slotInfo.source = "machine"
         return slotInfo
      end
   end

   -- Check inventory views
   for _, view in ipairs(self.views) do
      local slotInfo = view:getSlotUnderMouse(mouse_x, mouse_y)
      if slotInfo then
         slotInfo.inventory = view.inventory
         slotInfo.source = "inventory"
         return slotInfo
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
   local slotInfo

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
               slotInfo = {
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
            slotInfo = {
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
      slotInfo = self:getSlotUnderMouse(mouse_x, mouse_y)
   end

   if not slotInfo then return false end

   local inventory = slotInfo.inventory
   if not inventory then return false end

   local slotIndex = slotInfo.slotIndex
   local slotType = slotInfo.slotType -- Can be nil for simple inventories
   local slot = slotInfo.slot

   -- If holding an item, try to place/swap/stack
   if self.heldStack then
      return self:placeItemInSlot(slotIndex, slotType, inventory)
   elseif slot and slot.itemId then
      return self:pickItemFromSlot(slotIndex, slotType, inventory)
   end

   return false
end

--- Pick up an item from a slot (internal method - assumes heldStack is nil)
--- @param slotIndex number The slot index to pick from
--- @param slotType string|nil The type of slot (input, output, catalyst) or nil for simple inventories
--- @param inventory table The inventory to pick from
--- @return boolean Success
function MachineStateManager:pickItemFromSlot(slotIndex, slotType, inventory)
   -- Handle both typed slots (machine) and simple slots (inventory)
   local slot = InventoryHelper.getSlot(inventory, slotIndex, slotType)
   if not slot or not slot.itemId then return false end

   -- Pick up the entire stack
   self.heldStack = {
      itemId = slot.itemId,
      quantity = slot.quantity,
      sourceInventory = inventory,
      sourceSlot = slotIndex,
      sourceSlotType = slotType,
   }

   -- Create held stack view
   self.heldStackView = HeldStackView:new(self.heldStack)

   -- Clear the slot
   slot.itemId = nil
   slot.quantity = 0
   love.mouse.setVisible(false)
   return true
end

--- Clear the held stack and show cursor
local function clearHeldStack(self)
   if self.heldStackView then
      self.heldStackView:destroy()
      self.heldStackView = nil
   end
   self.heldStack = nil
   love.mouse.setVisible(true)
end

--- Update held stack with new data
local function updateHeldStack(self, itemId, quantity, inventory, slotIndex, slotType)
   self.heldStack.itemId = itemId
   self.heldStack.quantity = quantity
   self.heldStack.sourceInventory = inventory
   self.heldStack.sourceSlot = slotIndex
   self.heldStack.sourceSlotType = slotType

   if self.heldStackView then
      self.heldStackView:updateStack(self.heldStack)
   end
end

--- Place the held item into a slot (handles empty slots, stacking, and swapping)
--- @param slotIndex number The slot index to place into
--- @param slotType string|nil The type of slot or nil for simple inventories
--- @param inventory table The inventory to place into
--- @return boolean Success
function MachineStateManager:placeItemInSlot(slotIndex, slotType, inventory)
   -- Handle both typed slots (machine) and simple slots (inventory)
   local slot = InventoryHelper.getSlot(inventory, slotIndex, slotType)
   if not slot then return false end

   -- Empty slot - place the item
   if not slot.itemId then
      slot.itemId = self.heldStack.itemId
      slot.quantity = self.heldStack.quantity
      clearHeldStack(self)
      return true
   end

   -- Slot has same item - try to stack them
   if slot.itemId == self.heldStack.itemId then
      local maxStackSize = InventoryHelper.getMaxStackQuantity(slot.itemId)
      local total = slot.quantity + self.heldStack.quantity

      if total <= maxStackSize then
         -- Everything fits - merge stacks
         slot.quantity = total
         clearHeldStack(self)
         return true
      else
         -- Partial stack - fill slot and keep remainder
         if slot.quantity >= maxStackSize then return false end

         local remainingSpace = maxStackSize - slot.quantity
         local newHeldQuantity = self.heldStack.quantity - remainingSpace
         slot.quantity = maxStackSize

         if newHeldQuantity <= 0 then
            clearHeldStack(self)
         else
            self.heldStack.quantity = newHeldQuantity
            self.heldStack.sourceInventory = inventory
            self.heldStack.sourceSlot = slotIndex
            self.heldStack.sourceSlotType = slotType
            love.mouse.setVisible(true)
         end
         return true
      end
   end

   -- Slot has different item - swap them
   local tempItem = slot.itemId
   local tempQuantity = slot.quantity

   slot.itemId = self.heldStack.itemId
   slot.quantity = self.heldStack.quantity

   updateHeldStack(self, tempItem, tempQuantity, inventory, slotIndex, slotType)
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
