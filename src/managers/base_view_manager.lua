local InventoryHelper = require("src.helpers.inventory_helper")
local HeldStackView = require("src.ui.held_stack_view")

local BaseSlotManager = Class("BaseSlotManager")

function BaseSlotManager:pickOrPlace(slotInfo)
   local inventory = slotInfo.inventory
   local slotIndex = slotInfo.slotIndex
   local slotType = slotInfo.slotType
   local slot = slotInfo.slot

   if not slot then return false end

   -- If holding an item, try to place/swap/stack
   if self.heldStack then
      return self:placeItemInSlot(slotIndex, slotType, inventory)
      -- If slot has an item, pick it up
   elseif slot.itemId then
      return self:pickItemFromSlot(slotIndex, slotType, inventory)
   end

   return false
end

--- Pick up an item from a slot (internal method - assumes heldStack is nil)
--- @param slotIndex number The slot index to pick from
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @param inventory table The inventory to pick from
--- @return boolean Success
function BaseSlotManager:pickItemFromSlot(slotIndex, slotType, inventory)
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
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @param inventory table The inventory to place into
--- @return boolean Success
function BaseSlotManager:placeItemInSlot(slotIndex, slotType, inventory)
   local slot = InventoryHelper.getSlot(inventory, slotIndex, slotType)
   if not slot then return false end

   -- Check if the held item can be placed in this slot type (category constraints)
   if not InventoryHelper.canPlaceItem(inventory, self.heldStack.itemId, slotType) then
      return false
   end

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
   -- First check if the swap is valid in both directions
   local tempItem = slot.itemId
   local tempQuantity = slot.quantity

   -- Check if the slot item can go back to where the held item came from
   if self.heldStack.sourceInventory and self.heldStack.sourceSlotType then
      if not InventoryHelper.canPlaceItem(self.heldStack.sourceInventory, tempItem, self.heldStack.sourceSlotType) then
         return false
      end
   end

   slot.itemId = self.heldStack.itemId
   slot.quantity = self.heldStack.quantity

   updateHeldStack(self, tempItem, tempQuantity, inventory, slotIndex, slotType)
   return true
end

function BaseSlotManager:returnHeldStack()
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

function BaseSlotManager:getSlotUnderMouse(mouseX, mouseY)
   -- Check machine screen first
   if self.screen then
      local slotInfo = self.screen:getSlotUnderMouse(mouseX, mouseY)
      if slotInfo then
         slotInfo.inventory = self.screen:getInventory()
         return slotInfo
      end
   end

   for _, view in ipairs(self.views) do
      local slotInfo = view:getSlotUnderMouse(mouseX, mouseY)
      if slotInfo then
         return slotInfo
      end
   end

   return nil
end

return BaseSlotManager
