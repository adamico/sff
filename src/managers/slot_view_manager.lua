local InventoryHelper = require("src.helpers.inventory_helper")
local InventoryHandlers = require("src.config.inventory_action_handlers").Handlers
local HeldStackView = require("src.ui.held_stack_view")

local SlotViewManager = Class("SlotViewManager")

-- ============================================================================
-- Initialization
-- ============================================================================

function SlotViewManager:initialize()
   self.isOpen = false
   self.views = {}
   self.heldStack = nil
   self.heldStackView = nil
   self.hoveredSlotUserData = nil
end

--- Open views (inventory, machine, or any mix)
--- @param views table Array of view instances
function SlotViewManager:open(views)
   self.isOpen = true
   self.views = views or {}
end

function SlotViewManager:close()
   if self.heldStack then
      self:returnHeldStack()
      love.mouse.setVisible(true)
   end

   -- Destroy held stack view
   if self.heldStackView then
      self.heldStackView:destroy()
      self.heldStackView = nil
   end

   -- Destroy view elements (except persistent views like toolbar and equipment)
   for _, view in ipairs(self.views) do
      if view and view.destroy then
         local isToolbar = view.id == "toolbar"
         local isEquipment = view.id and string.find(view.id, "^equipment")
         if not isToolbar and not isEquipment then
            view:destroy()
         end
      end
   end

   self.heldStack = nil
   self.isOpen = false
   self.views = {}
end

-- ============================================================================
-- Slot Transfer Primitives
-- ============================================================================

--- Transfer items from source slot to destination slot, respecting stack limits.
--- Updates both slots in place.
--- @param srcSlot table Source slot {itemId, quantity}
--- @param dstSlot table Destination slot {itemId, quantity}
--- @param amount number|nil Amount to transfer (defaults to srcSlot.quantity)
--- @return number Amount actually transferred
local function transfer(srcSlot, dstSlot, amount)
   if not srcSlot.itemId then return 0 end
   amount = amount or srcSlot.quantity

   -- Empty dst or same item: stack
   if not dstSlot.itemId or dstSlot.itemId == srcSlot.itemId then
      local added = InventoryHelper.stackIntoSlot(dstSlot, srcSlot.itemId, amount)
      srcSlot.quantity = srcSlot.quantity - added
      if srcSlot.quantity <= 0 then
         srcSlot.itemId = nil
         srcSlot.quantity = 0
      end
      return added
   end

   return 0 -- Different items, can't stack
end

--- Swap contents of two slots entirely.
--- Returns false if both slots are empty (nothing to swap).
--- @param slotA table First slot
--- @param slotB table Second slot
--- @return boolean True if swap occurred
local function swap(slotA, slotB)
   -- Guard: don't swap nothing with nothing
   if not slotA.itemId and not slotB.itemId then
      return false
   end

   slotA.itemId, slotB.itemId = slotB.itemId, slotA.itemId
   slotA.quantity, slotB.quantity = slotB.quantity, slotA.quantity
   return true
end

--- Try to transfer from source to destination; if blocked by different item, swap instead.
--- @param srcSlot table Source slot
--- @param dstSlot table Destination slot
--- @return boolean True if any operation succeeded
local function transferOrSwap(srcSlot, dstSlot)
   -- Try transfer first (handles empty dst or same item)
   if not dstSlot.itemId or dstSlot.itemId == srcSlot.itemId then
      return transfer(srcSlot, dstSlot) > 0
   end

   -- Different items: swap
   return swap(srcSlot, dstSlot)
end

-- ============================================================================
-- Action Handling
-- ============================================================================

--- Handle toolbar move action
--- @param toolbarSlotIndex number
function SlotViewManager:handleToolbarMove(toolbarSlotIndex)
   if not self.hoveredSlotUserData then return false end

   -- Resolve source slot info
   local userdata = self.hoveredSlotUserData
   local sourceSlotInfo = self:resolveSlotInfo(userdata)
   if not sourceSlotInfo then return false end

   local sourceSlot = sourceSlotInfo.slot

   -- Get toolbar slot
   local toolbar = Evolved.get(ENTITIES.Player, FRAGMENTS.Toolbar)
   local toolbarSlot = InventoryHelper.getSlot(toolbar, toolbarSlotIndex)
   if not toolbarSlot then return false end

   -- Guard: nothing to transfer or swap
   if not sourceSlot.itemId and not toolbarSlot.itemId then return false end

   -- Permission checks
   if not InventoryHelper.canRemove(sourceSlotInfo.inventory) then return false end
   if sourceSlot.itemId and not InventoryHelper.canPlaceItem(toolbar, sourceSlot.itemId) then return false end
   if toolbarSlot.itemId and not InventoryHelper.canPlaceItem(sourceSlotInfo.inventory, toolbarSlot.itemId) then return false end

   return transferOrSwap(sourceSlot, toolbarSlot)
end

--- Handle a click on any slot (main entry point for click logic)
--- @param userdata table Userdata from clicked element
--- @return boolean Success
function SlotViewManager:handleAction(userdata)
   local slotInfo = self:resolveSlotInfo(userdata)
   if not slotInfo then return false end

   local action = userdata and userdata.action
   local handler = InventoryHandlers[action]
   if handler then
      return handler(self, slotInfo, userdata)
   end

   return false
end

--- Resolve slot info from userdata
--- @param userdata table|nil
--- @return table|nil slotInfo
function SlotViewManager:resolveSlotInfo(userdata)
   if not userdata then return end

   local slotInfo
   local view = userdata.view
   local slotIndex = userdata.slotIndex
   local inventoryType = userdata.inventoryType

   -- Get inventory - handles both InventoryView and MachineView
   local inventory
   if inventoryType and view.getInventory then
      inventory = view:getInventory(inventoryType)
   else
      inventory = view:getInventory()
   end

   if not inventory then return end

   local slot = InventoryHelper.getSlot(inventory, slotIndex)
   if not slot then return end

   slotInfo = {
      view = view,
      inventory = inventory,
      inventoryType = inventoryType,
      slotIndex = slotIndex,
      slot = slot,
   }

   return slotInfo
end

-- ============================================================================
-- Pick/Place Operations
-- ============================================================================

function SlotViewManager:pickOrPlace(slotInfo)
   local inventory = slotInfo.inventory
   local slotIndex = slotInfo.slotIndex
   local slot = slotInfo.slot

   if not slot then return false end

   -- Check access mode for insert operations
   if self.heldStack then
      if not InventoryHelper.canInsert(inventory) then
         return false
      end
      return self:placeItemInSlot(slotIndex, inventory)
   elseif slot.itemId then
      if not InventoryHelper.canRemove(inventory) then
         return false
      end
      return self:pickItemFromSlot(slotIndex, inventory, slot.quantity)
   end

   return false
end

--- Pick up an item from a slot
--- @param slotIndex number The slot index to pick from
--- @param inventory table The inventory to pick from
--- @param quantity number The quantity to pick
--- @return boolean Success
function SlotViewManager:pickItemFromSlot(slotIndex, inventory, quantity)
   local slot = InventoryHelper.getSlot(inventory, slotIndex)
   if not slot or not slot.itemId then return false end

   local pickedQuantity = quantity
   local remainingQuantity = slot.quantity - pickedQuantity
   -- Pick up the stack
   self.heldStack = {
      itemId = slot.itemId,
      quantity = pickedQuantity,
      sourceInventory = inventory,
      sourceSlot = slotIndex,
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
--- @param slotIndex number The slot index to place into
--- @param inventory table The inventory to place into
--- @return boolean Success
function SlotViewManager:placeItemInSlot(slotIndex, inventory)
   local slot = InventoryHelper.getSlot(inventory, slotIndex)
   if not slot then return false end

   -- Permission checks
   if not InventoryHelper.canPlaceItem(inventory, self.heldStack.itemId) then
      return false
   end
   if slot.itemId and self.heldStack.sourceInventory then
      if not InventoryHelper.canPlaceItem(self.heldStack.sourceInventory, slot.itemId) then
         return false
      end
   end

   -- Try transfer first (empty slot or same item)
   if not slot.itemId or slot.itemId == self.heldStack.itemId then
      local amountAdded = transfer(self.heldStack, slot)
      if amountAdded > 0 then
         if not self.heldStack.itemId then
            -- Everything was placed
            clearHeldStack(self)
         else
            -- Partial placement - update source tracking
            self.heldStack.sourceInventory = inventory
            self.heldStack.sourceSlot = slotIndex
         end
         return true
      end
      return false
   end

   -- Different items - swap
   swap(self.heldStack, slot)
   updateHeldStack(self, self.heldStack.itemId, self.heldStack.quantity, inventory, slotIndex)
   return true
end

function SlotViewManager:returnHeldStack()
   local heldStack = self.heldStack
   if heldStack and heldStack.sourceInventory then
      local slot = InventoryHelper.getSlot(heldStack.sourceInventory, heldStack.sourceSlot)
      if slot then
         slot.itemId = heldStack.itemId
         slot.quantity = heldStack.quantity
      end
   end
end

function SlotViewManager:pickHalf(slotInfo)
   local slot = slotInfo.slot
   if not slot or not slot.itemId then return false end
   if not InventoryHelper.canRemove(slotInfo.inventory) then return false end

   local slotQuantity = slot.quantity
   if slotQuantity <= 1 then return false end
   local quantity = math.floor(slotQuantity / 2)
   self:pickItemFromSlot(slotInfo.slotIndex, slotInfo.inventory, quantity)
end

function SlotViewManager:pickOne(slotInfo)
   if not InventoryHelper.canRemove(slotInfo.inventory) then return false end
   self:pickItemFromSlot(slotInfo.slotIndex, slotInfo.inventory, 1)
end

-- ============================================================================
-- Quick Transfer
-- ============================================================================

--- Get the source identifier for transfer routing
--- @param slotInfo table The slot info containing view
--- @return string sourceId Identifier like "player_inventory", "machine:input", etc.
local function getTransferSourceId(slotInfo)
   if slotInfo.view then
      local viewId = slotInfo.view.id or ""
      -- Normalize equipment views to a single category
      if string.find(viewId, "^equipment") then
         return "equipment"
      elseif string.find(viewId, "^machine") then
         local inventoryType = slotInfo.inventoryType or "input"
         return "machine:"..inventoryType
      end

      return viewId
   end

   return "unknown"
end

--- Transfer target resolvers - each returns {inventory} or nil
local TransferTargets = {
   player_inventory = function(self)
      local inv = Evolved.get(ENTITIES.Player, FRAGMENTS.Inventory)
      return inv and {inventory = inv} or nil
   end,

   toolbar = function(self)
      local inv = Evolved.get(ENTITIES.Player, FRAGMENTS.Toolbar)
      return inv and {inventory = inv} or nil
   end,

   machine = function(self)
      local view = self:findViewById("machine")
      if view and view.inputInventory then
         return {inventory = view.inputInventory}
      end
      return nil
   end,

   target_inventory = function(self)
      local view = self:findViewById("target_inventory")
      if view and view.inventory then
         return {inventory = view.inventory}
      end
      return nil
   end,
}

--- Transfer rules: source → ordered list of target resolvers
local TransferRules = {
   ["player_inventory"] = {"machine", "target_inventory", "toolbar"},
   ["toolbar"]          = {"player_inventory"},
   ["target_inventory"] = {"player_inventory"},
   ["equipment"]        = {"player_inventory"},
   ["machine:input"]    = {"player_inventory"},
   ["machine:output"]   = {"player_inventory"},
}

function SlotViewManager:quickTransfer(slotInfo)
   local slot = slotInfo.slot
   if not slot or not slot.itemId then return false end

   -- Check if we can remove from source
   if not InventoryHelper.canRemove(slotInfo.inventory) then
      return false
   end

   -- Determine source and look up transfer rules
   local sourceId = getTransferSourceId(slotInfo)
   local targetKeys = TransferRules[sourceId]

   if not targetKeys then
      Log.warn("quickTransfer: No transfer rules for source: "..sourceId)
      return false
   end

   -- Find first available target that allows insert
   local targetInventory = nil

   for _, targetKey in ipairs(targetKeys) do
      local resolver = TransferTargets[targetKey]
      if resolver then
         local result = resolver(self)
         if result and InventoryHelper.canInsert(result.inventory) then
            targetInventory = result.inventory
            break
         end
      end
   end

   if not targetInventory then
      Log.debug("No target inventory found")
      return false
   end

   -- Transfer to the target inventory (uses addItem which finds best slots)
   local amountAdded = InventoryHelper.addItem(targetInventory, slot.itemId, slot.quantity)
   if amountAdded > 0 then
      slot.quantity = slot.quantity - amountAdded
      if slot.quantity <= 0 then
         slot.itemId = nil
         slot.quantity = 0
      end
      return true
   end

   return false
end

-- ============================================================================
-- Collect Stack (Double Click)
-- ============================================================================

--- Collect items of the same type from other slots in the inventory.
--- This is triggered by double-clicking a slot (Minecraft-style stacking).
--- Works in two modes:
--- 1. Not holding: collect matching items into the clicked slot
--- 2. Holding: collect matching items into the held stack
--- @param slotInfo table The slot info for the clicked slot
--- @return boolean True if any items were collected
function SlotViewManager:collectStack(slotInfo)
   -- Check if we can modify this inventory
   if not InventoryHelper.canRemove(slotInfo.inventory) then
      return false
   end

   local slots = InventoryHelper.getSlots(slotInfo.inventory)
   if not slots then return false end

   -- Determine target slot and skip index based on mode
   local targetSlot, skipIndex
   if self.heldStack then
      targetSlot = self.heldStack
      skipIndex = nil -- Don't skip any slot when collecting into held stack
   else
      targetSlot = slotInfo.slot
      skipIndex = slotInfo.slotIndex -- Skip the target slot itself
   end

   if not targetSlot or not targetSlot.itemId then return false end

   local targetItemId = targetSlot.itemId
   local collected = false

   -- Iterate through all slots and transfer matching items to target
   for i, srcSlot in ipairs(slots) do
      if i ~= skipIndex and srcSlot.itemId == targetItemId then
         local transferred = transfer(srcSlot, targetSlot)
         if transferred > 0 then
            collected = true
         end
      end
   end

   -- Update held stack view if we collected into it
   if collected and self.heldStack and self.heldStackView then
      self.heldStackView:updateStack(self.heldStack)
   end

   return collected
end

-- ============================================================================
-- View Utilities
-- ============================================================================

--- Find a view by its ID
--- @param viewId string The view ID to find
--- @return table|nil The view if found
function SlotViewManager:findViewById(viewId)
   if not self.views then return nil end

   for _, view in ipairs(self.views) do
      if view and view.id == viewId then
         return view
      end
   end

   return nil
end

function SlotViewManager:getSlotUnderMouse(mouseX, mouseY)
   for _, view in ipairs(self.views) do
      local slotInfo = view:getSlotUnderMouse(mouseX, mouseY)
      if slotInfo then
         return slotInfo
      end
   end

   return nil
end

-- ============================================================================
-- Rendering
-- ============================================================================

function SlotViewManager:draw()
   for _, view in ipairs(self.views) do
      if view then
         view:draw()
      end
   end
end

function SlotViewManager:drawHeldStack()
   if self.heldStackView then
      self.heldStackView:draw()
   end
end

function SlotViewManager:update(dt)
   if self.heldStackView then
      self.heldStackView:update(dt)
   end
end

return SlotViewManager:new()
