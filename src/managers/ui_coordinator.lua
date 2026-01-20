-- ============================================================================
-- UI Coordinator
-- ============================================================================
-- Central coordinator for all UI views and state
-- Manages view creation, positioning, and lifecycle

local InventoryHelper = require("src.helpers.inventory_helper")
local InventoryView = require("src.ui.inventory_view")
local MachineView = require("src.ui.machine_view")
local SlotViewManager = require("src.managers.slot_view_manager")
local InputState = require("src.states.input_state")
local get = Evolved.get

-- ============================================================================
-- Layout Constants (centralized)
-- ============================================================================

local UI = require("src.config.ui_constants")

local CENTERED_X = UI.VIEWPORT_WIDTH / 2 - UI.INV_WIDTH / 2
local TOOLBAR_Y = UI.VIEWPORT_HEIGHT - UI.TOOLBAR_HEIGHT - 4
local EQUIPMENT_X = 4
local PLAYER_INV_Y = TOOLBAR_Y - UI.GAP - UI.INV_HEIGHT

-- ============================================================================
-- Cached Views (persistent)
-- ============================================================================

local toolbarView = nil
local weaponSlotView = nil
local armorSlotView = nil

local function createToolbarView(toolbar)
   if not toolbar then return nil end

   if not toolbarView then
      toolbarView = InventoryView:new(toolbar, {
         id = "toolbar",
         columns = UI.COLUMNS,
         rows = UI.TOOLBAR_ROWS,
         x = CENTERED_X,
         y = TOOLBAR_Y
      })
   end

   return toolbarView
end

--- Creates equipment views for weapon and armor slots.
--- @param weaponSlot table The weapon slot inventory
--- @param armorSlot table The armor slot inventory
--- @return table Array of InventoryView instances for equipment
local function createEquipmentViews(weaponSlot, armorSlot)
   local views = {}
   local currentY = TOOLBAR_Y
   local viewX = EQUIPMENT_X
   local viewHeight = UI.SLOT_SIZE + UI.PADDING * 2

   -- Armor slot view (displayed above weapon)
   if armorSlot then
      if not armorSlotView then
         local maxSlots = armorSlot.maxSlots or 1
         armorSlotView = InventoryView:new(armorSlot, {
            id = "equipment_armor",
            columns = maxSlots,
            rows = 1,
            x = viewX,
            y = currentY
         })
      end
      table.insert(views, armorSlotView)
      currentY = currentY - viewHeight - 4
   end

   -- Weapon slot view
   if weaponSlot then
      if not weaponSlotView then
         local maxSlots = weaponSlot.maxSlots or 1
         weaponSlotView = InventoryView:new(weaponSlot, {
            id = "equipment_weapon",
            columns = maxSlots,
            rows = 1,
            x = viewX,
            y = currentY
         })
      end
      table.insert(views, weaponSlotView)
   end

   return views
end

local function createPlayerInventoryView(playerInventory)
   if not playerInventory then return nil end

   return InventoryView:new(playerInventory, {
      id = "player_inventory",
      columns = UI.COLUMNS,
      rows = UI.INV_ROWS,
      x = CENTERED_X,
      y = PLAYER_INV_Y
   })
end

local function createTargetInventoryView(targetInventory, entityId)
   if not targetInventory then return nil end

   local slots = InventoryHelper.getSlots(targetInventory)
   if not slots then return nil end

   local slotCount = #slots
   local targetColumns = math.min(slotCount, UI.COLUMNS)
   local targetRows = math.ceil(slotCount / targetColumns)

   local targetWidth = targetColumns * UI.SLOT_SIZE + UI.PADDING * 2
   local targetHeight = targetRows * UI.SLOT_SIZE + UI.PADDING * 2
   local targetX = UI.VIEWPORT_WIDTH / 2 - targetWidth / 2
   local targetY = PLAYER_INV_Y - UI.GAP - targetHeight

   return InventoryView:new(targetInventory, {
      id = "target_inventory",
      columns = targetColumns,
      rows = targetRows,
      x = targetX,
      y = targetY,
      entityId = entityId
   })
end

local function createMachineView(entityId)
   local machineX = UI.VIEWPORT_WIDTH / 2 - UI.MACHINE_WIDTH / 2
   local machineY = PLAYER_INV_Y - UI.GAP - UI.MACHINE_HEIGHT

   return MachineView:new({
      id = "machine",
      entityId = entityId,
      x = machineX,
      y = machineY,
      width = UI.MACHINE_WIDTH,
      height = UI.MACHINE_HEIGHT
   })
end

-- ============================================================================
-- Public API
-- ============================================================================

local UICoordinator = {}

function UICoordinator.openPlayerInventory(playerInventory, playerToolbar, weaponSlot, armorSlot)
   if not playerInventory then return end

   -- Transition input state
   InputState.fsm:openInventory()

   local views = {
      createPlayerInventoryView(playerInventory),
      createToolbarView(playerToolbar),
   }

   -- Add all equipment views
   for _, equipView in ipairs(createEquipmentViews(weaponSlot, armorSlot)) do
      table.insert(views, equipView)
   end

   SlotViewManager:open(views)
end

function UICoordinator.openTargetInventory(entityId)
   local playerId = ENTITIES.Player
   if not entityId or not playerId then return end

   -- Transition input state
   InputState.fsm:openInventory()

   local targetInventory = get(entityId, FRAGMENTS.Inventory)
   local playerInventory, playerToolbar, weaponSlot, armorSlot = get(playerId,
      FRAGMENTS.Inventory, FRAGMENTS.Toolbar, FRAGMENTS.WeaponSlot, FRAGMENTS.ArmorSlot)

   local views = {
      createToolbarView(playerToolbar),
      createPlayerInventoryView(playerInventory),
      createTargetInventoryView(targetInventory, entityId),
   }

   -- Add all equipment views
   for _, equipView in ipairs(createEquipmentViews(weaponSlot, armorSlot)) do
      table.insert(views, equipView)
   end

   SlotViewManager:open(views)
end

function UICoordinator.openMachineView(entityId)
   local playerId = ENTITIES.Player
   if not entityId or not playerId then return end

   -- Transition input state
   InputState.fsm:openInventory()

   local playerInventory, playerToolbar, weaponSlot, armorSlot = get(playerId,
      FRAGMENTS.Inventory, FRAGMENTS.Toolbar, FRAGMENTS.WeaponSlot, FRAGMENTS.ArmorSlot)

   local views = {
      createToolbarView(playerToolbar),
      createPlayerInventoryView(playerInventory),
      createMachineView(entityId),
   }

   -- Add all equipment views
   for _, equipView in ipairs(createEquipmentViews(weaponSlot, armorSlot)) do
      table.insert(views, equipView)
   end

   SlotViewManager:open(views)
end

function UICoordinator.getToolbarView(toolbar)
   return createToolbarView(toolbar)
end

function UICoordinator.getEquipmentViews(weaponSlot, armorSlot)
   return createEquipmentViews(weaponSlot, armorSlot)
end

-- ============================================================================
-- Input State Management
-- ============================================================================

function UICoordinator.enterPlacementMode()
   InputState.fsm:startPlacing()
end

function UICoordinator.exitPlacementMode()
   InputState.fsm:cancelPlacing()
end

function UICoordinator.closeModal()
   InputState.fsm:closeModal()
   if SlotViewManager.isOpen then
      SlotViewManager:close()
   end
end

function UICoordinator.getInputState()
   return InputState.fsm
end

return UICoordinator
