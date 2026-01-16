local InventoryHelper = require("src.helpers.inventory_helper")
local HeldStackView = require("src.ui.held_stack_view")

local InventoryStateManager = {
   isOpen = false,
   views = {},
   heldStack = nil,
   heldStackView = nil,
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

   -- Destroy held stack view
   if self.heldStackView then
      self.heldStackView:destroy()
      self.heldStackView = nil
   end

   -- Destroy FlexLove elements (except toolbar which is always visible)
   for _, view in ipairs(self.views) do
      if view and view.destroy then
         -- Don't destroy toolbar or equipment view
         if view.id ~= "toolbar" and view.id ~= "equipment" then
            view:destroy()
         end
      end
   end

   self.heldStack = nil
   self.isOpen = false
   self.views = {}
end

function InventoryStateManager:returnHeldStack()
   local heldStack = self.heldStack
   if heldStack and heldStack.sourceInventory then
      local slot = heldStack.sourceInventory.slots[heldStack.sourceSlot]
      if slot then
         slot.itemId = heldStack.itemId
         slot.quantity = heldStack.quantity
      end
   end
end

function InventoryStateManager:getSlotUnderMouse(mouse_x, mouse_y)
   for _, view in ipairs(self.views) do
      local slotInfo = view:getSlotUnderMouse(mouse_x, mouse_y)
      if slotInfo then
         return slotInfo
      end
   end

   return nil
end

--- Handle a click on an inventory slot (main entry point for click logic)
--- @param mouse_x number The x position of the mouse_x
--- @param mouse_y number The y position of the mouse_y
--- @param userdata table|nil Optional userdata from clicked element (to avoid redundant hit detection)
--- @return boolean Success
function InventoryStateManager:handleSlotClick(mouse_x, mouse_y, userdata)
   local slotInfo

   -- If userdata provided (from slot element click), use it directly
   if userdata and userdata.slotIndex and userdata.view then
      local view = userdata.view
      local slotIndex = userdata.slotIndex
      local slots = view.inventory.slots
      if slots and slots[slotIndex] then
         slotInfo = {
            view = view,
            slotIndex = slotIndex,
            slot = slots[slotIndex],
         }
      end
   else
      -- Fallback: do hit detection (for clicks not from slot elements)
      slotInfo = self:getSlotUnderMouse(mouse_x, mouse_y)
   end

   if not slotInfo then
      return false
   end

   local inventory = slotInfo.view.inventory
   local slotIndex = slotInfo.slotIndex
   local slot = slotInfo.slot

   -- If holding an item, try to place/swap/stack
   if self.heldStack then
      return self:placeItemInSlot(slotIndex, inventory)
   elseif slot.itemId then
      return self:pickItemFromSlot(slotIndex, inventory)
   end

   return false
end

--- Pick up an item from a slot (internal method - assumes heldStack is nil)
--- @param slotIndex number The slot index to pick from
--- @param inventory table The inventory to pick from
--- @return boolean Success
function InventoryStateManager:pickItemFromSlot(slotIndex, inventory)
   local slot = inventory.slots[slotIndex]
   if not slot or not slot.itemId then return false end

   -- Pick up the entire stack
   self.heldStack = {
      itemId = slot.itemId,
      quantity = slot.quantity,
      sourceInventory = inventory,
      sourceSlot = slotIndex,
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
local function updateHeldStack(self, itemId, quantity, inventory, slotIndex)
   self.heldStack.itemId = itemId
   self.heldStack.quantity = quantity
   self.heldStack.sourceInventory = inventory
   self.heldStack.sourceSlot = slotIndex

   if self.heldStackView then
      self.heldStackView:updateStack(self.heldStack)
   end
end

--- Place the held item into a slot (handles empty slots, stacking, and swapping)
--- @param inventory table The inventory to place into
--- @param slotIndex number The slot index to place into
--- @return boolean Success
function InventoryStateManager:placeItemInSlot(slotIndex, inventory)
   local slot = inventory.slots[slotIndex]
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

   updateHeldStack(self, tempItem, tempQuantity, inventory, slotIndex)
   return true
end

function InventoryStateManager:draw()
   for i = 1, #self.views do
      local view = self.views[i]
      if view then
         view:draw()
      end
   end
end

--- Draw the held stack (should be called AFTER FlexLove.draw())
function InventoryStateManager:drawHeldStack()
   if self.heldStackView then
      self.heldStackView:draw()
   end
end

function InventoryStateManager:update(dt)
   -- Update held stack view position to follow cursor
   if self.heldStackView then
      self.heldStackView:update(dt)
   end
end

return InventoryStateManager
