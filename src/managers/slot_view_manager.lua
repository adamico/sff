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
-- Action Handling
-- ============================================================================

--- Handle a click on any slot (main entry point for click logic)
--- @param mouseX number The x position of the mouse
--- @param mouseY number The y position of the mouse
--- @param userdata table Userdata from clicked element
--- @return boolean Success
function SlotViewManager:handleAction(mouseX, mouseY, userdata)
   local slotInfo = self:resolveSlotInfo(mouseX, mouseY, userdata)
   if not slotInfo then return false end

   local action = userdata and userdata.action
   local handler = InventoryHandlers[action]
   if handler then
      return handler(self, slotInfo, userdata)
   end

   return false
end

--- Resolve slot info from userdata or mouse position
--- @param mouseX number
--- @param mouseY number
--- @param userdata table|nil
--- @return table|nil slotInfo
function SlotViewManager:resolveSlotInfo(mouseX, mouseY, userdata)
   local slotInfo

   if userdata and userdata.slotIndex and userdata.view then
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
   else
      slotInfo = self:getSlotUnderMouse(mouseX, mouseY)
   end

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

   -- Check if the held item can be placed in this inventory (category constraints)
   if not InventoryHelper.canPlaceItem(inventory, self.heldStack.itemId) then
      return false
   end

   -- Empty slot or same item - try to stack
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
         end
         return true
      end
      return false -- Couldn't add any (slot was full)
   end

   -- Slot has different item - swap them
   local tempItem = slot.itemId
   local tempQuantity = slot.quantity

   -- Check if the slot item can go back to where the held item came from
   if self.heldStack.sourceInventory then
      if not InventoryHelper.canPlaceItem(self.heldStack.sourceInventory, tempItem) then
         return false
      end
   end

   slot.itemId = self.heldStack.itemId
   slot.quantity = self.heldStack.quantity

   updateHeldStack(self, tempItem, tempQuantity, inventory, slotIndex)
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

   -- Try to add the item to the target inventory
   local amountAdded = InventoryHelper.addItem(targetInventory, slot.itemId, slot.quantity)

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
