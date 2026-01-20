local InventoryHelper = require("src.helpers.inventory_helper")
local HeldStackView = require("src.ui.held_stack_view")

local BaseViewManager = Class("BaseViewManager")

function BaseViewManager:pickOrPlace(slotInfo)
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
      return self:pickItemFromSlot(slotIndex, slotType, inventory, slot.quantity)
   end

   return false
end

--- Pick up an item from a slot (internal method - assumes heldStack is nil)
--- @param slotIndex number The slot index to pick from
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @param inventory table The inventory to pick from
--- @return boolean Success
function BaseViewManager:pickItemFromSlot(slotIndex, slotType, inventory, quantity)
   local slot = InventoryHelper.getSlot(inventory, slotIndex, slotType)
   if not slot or not slot.itemId then return false end

   local pickedQuantity = quantity
   local remainingQuantity = slot.quantity - pickedQuantity
   -- Pick up the entire stack
   self.heldStack = {
      itemId = slot.itemId,
      quantity = pickedQuantity,
      sourceInventory = inventory,
      sourceSlot = slotIndex,
      sourceSlotType = slotType,
   }

   -- Create held stack view
   self.heldStackView = HeldStackView:new(self.heldStack)

   -- Clear the slot
   if remainingQuantity <= 0 then
      slot.itemId = nil
   end
   slot.quantity = remainingQuantity
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
function BaseViewManager:placeItemInSlot(slotIndex, slotType, inventory)
   local slot = InventoryHelper.getSlot(inventory, slotIndex, slotType)
   if not slot then return false end

   -- Check if the held item can be placed in this slot type (category constraints)
   if not InventoryHelper.canPlaceItem(inventory, self.heldStack.itemId, slotType) then
      return false
   end

   -- Empty slot or same item - try to stack using the canonical helper
   if not slot.itemId or slot.itemId == self.heldStack.itemId then
      local amountAdded = InventoryHelper.stackIntoSlot(slot, self.heldStack.itemId, self.heldStack.quantity)

      if amountAdded > 0 then
         local remaining = self.heldStack.quantity - amountAdded

         if remaining <= 0 then
            -- Everything was placed
            clearHeldStack(self)
         else
            -- Partial placement - update held stack
            self.heldStack.quantity = remaining
            self.heldStack.sourceInventory = inventory
            self.heldStack.sourceSlot = slotIndex
            self.heldStack.sourceSlotType = slotType
         end
         return true
      end
      return false -- Couldn't add any (slot was full)
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

function BaseViewManager:returnHeldStack()
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

function BaseViewManager:pickHalf(slotInfo)
   local slot = slotInfo.slot
   if not slot or not slot.itemId then return false end

   local slotQuantity = slot.quantity
   if slotQuantity <= 1 then return false end
   local quantity = math.floor(slotQuantity / 2)
   self:pickItemFromSlot(slotInfo.slotIndex, slotInfo.slotType, slotInfo.inventory, quantity)
end

function BaseViewManager:pickOne(slotInfo)
   self:pickItemFromSlot(slotInfo.slotIndex, slotInfo.slotType, slotInfo.inventory, 1)
end

--- Get the source identifier for transfer routing
--- @param slotInfo table The slot info containing view
--- @return string sourceId Identifier like "player_inventory", "machine:input", etc.
local function getTransferSourceId(slotInfo)
   -- View-based slots use the view ID
   if slotInfo.view then
      local viewId = slotInfo.view.id or ""
      -- Normalize equipment views to a single category
      if string.find(viewId, "^equipment") then
         return "equipment"
      elseif string.find(viewId, "^machine") then
         local sourceId = "machine:"..(slotInfo.slotType or "input")
         return sourceId
      end

      return viewId
   end

   return "unknown"
end

--- Transfer target resolvers - each returns {inventory, slotType} or nil
local TransferTargets = {
   --- Player's main inventory
   player_inventory = function(self)
      local inv = Evolved.get(ENTITIES.Player, FRAGMENTS.Inventory)
      return inv and {inventory = inv, slotType = "default"} or nil
   end,

   --- Player's toolbar
   toolbar = function(self)
      local inv = Evolved.get(ENTITIES.Player, FRAGMENTS.Toolbar)
      return inv and {inventory = inv, slotType = "default"} or nil
   end,

   --- Machine input slots (if machine screen is open)
   machine = function(self)
      local view = self:findViewById("machine")
      if view and view.inventory then
         return {inventory = view.inventory, slotType = "input"}
      end
      return nil
   end,

   --- Target inventory view (storage/chest if open)
   target_inventory = function(self)
      local view = self:findViewById("target_inventory")
      if view and view.inventory then
         return {inventory = view.inventory, slotType = "default"}
      end
      return nil
   end,
}

--- Transfer rules: source → ordered list of target resolvers (first available wins)
local TransferRules = {
   ["player_inventory"] = {"machine", "target_inventory", "toolbar"},
   ["toolbar"]          = {"player_inventory"},
   ["target_inventory"] = {"player_inventory"},
   ["equipment"]        = {"player_inventory"},
   ["machine:input"]    = {"player_inventory"},
   ["machine:output"]   = {"player_inventory"},
}

function BaseViewManager:quickTransfer(slotInfo)
   local slot = slotInfo.slot
   if not slot or not slot.itemId then return false end

   -- Determine source and look up transfer rules
   local sourceId = getTransferSourceId(slotInfo)
   local targetKeys = TransferRules[sourceId]

   if not targetKeys then
      Log.warn("quickTransfer: No transfer rules for source: "..sourceId)
      return false
   end

   -- Find first available target
   local targetInventory = nil
   local targetSlotType = nil

   for _, targetKey in ipairs(targetKeys) do
      local resolver = TransferTargets[targetKey]
      if resolver then
         local result = resolver(self)
         if result then
            targetInventory = result.inventory
            targetSlotType = result.slotType
            break
         end
      end
   end

   if not targetInventory then
      Log.debug("No target inventory found")
      return false
   end

   -- Try to add the item to the target inventory (supports partial transfers)
   local amountAdded = InventoryHelper.addItem(targetInventory, slot.itemId, slot.quantity, targetSlotType)

   if amountAdded > 0 then
      -- Subtract transferred amount from source slot
      slot.quantity = slot.quantity - amountAdded

      -- Clear slot if empty
      if slot.quantity <= 0 then
         slot.itemId = nil
         slot.quantity = 0
      end

      return true
   end

   return false
end

--- Find a view by its ID in the currently open views
--- @param viewId string The view ID to find
--- @return table|nil The view if found, nil otherwise
function BaseViewManager:findViewById(viewId)
   if not self.views then return nil end

   for _, view in ipairs(self.views) do
      if view and view.id == viewId then
         return view
      end
   end

   return nil
end

function BaseViewManager:getSlotUnderMouse(mouseX, mouseY)
   for _, view in ipairs(self.views) do
      local slotInfo = view:getSlotUnderMouse(mouseX, mouseY)
      if slotInfo then
         return slotInfo
      end
   end

   return nil
end

return BaseViewManager
