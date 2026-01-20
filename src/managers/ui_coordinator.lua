-- ============================================================================
-- UI Coordinator
-- ============================================================================
-- Central coordinator for all UI screens and state
-- Manages view creation, positioning, and lifecycle

local InventoryHelper = require("src.helpers.inventory_helper")
local Inventory = require("src.evolved.fragments.inventory")
local InventoryView = require("src.ui.inventory_view")
local MachineScreen = require("src.ui.machine_screen")
local InventoryViewManager = require("src.managers.inventory_view_manager")
local MachineViewManager = require("src.managers.machine_view_manager")
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
local equipmentViews = {} -- Table of views keyed by slotType

local function getOrCreateToolbarView(toolbar)
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

--- Creates equipment views for all slot groups in the equipment inventory.
--- Each slot group (weapon, armor, etc.) gets its own view positioned vertically.
--- @param equipment table The equipment inventory
--- @return table Array of InventoryView instances for all slot groups
local function getOrCreateEquipmentViews(equipment)
   if not equipment then return {} end

   local slotTypes = InventoryHelper.getSlotTypes(equipment)
   local views = {}
   local currentY = TOOLBAR_Y
   local viewX = EQUIPMENT_X

   for _, slotType in ipairs(slotTypes) do
      if not equipmentViews[slotType] then
         local group = Inventory.getSlotGroup(equipment, slotType)
         if group then
            local maxSlots = group.maxSlots or 1
            local viewHeight = UI.SLOT_SIZE + UI.PADDING * 2

            equipmentViews[slotType] = InventoryView:new(equipment, {
               id = "equipment_"..slotType,
               slotType = slotType,
               columns = maxSlots,
               rows = 1,
               x = viewX,
               y = currentY
            })

            currentY = currentY - viewHeight - 4 -- Stack views vertically upward
         end
      end

      if equipmentViews[slotType] then
         table.insert(views, equipmentViews[slotType])
      end
   end

   return views
end

local function getOrCreatePlayerInventoryView(playerInventory)
   if not playerInventory then return nil end
   return InventoryView:new(playerInventory, {
      id = "player_inventory",
      columns = UI.COLUMNS,
      rows = UI.INV_ROWS,
      x = CENTERED_X,
      y = PLAYER_INV_Y
   })
end

local function getOrCreateTargetInventoryView(targetInventory, entityId)
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

local function getOrCreateMachineScreenView(entityId)
   local machineX = UI.VIEWPORT_WIDTH / 2 - UI.MACHINE_WIDTH / 2
   local machineY = PLAYER_INV_Y - UI.GAP - UI.MACHINE_HEIGHT

   return MachineScreen:new({
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

function UICoordinator.openPlayerInventory(playerInventory, playerToolbar, playerEquipment)
   if not playerInventory then return end

   -- Transition input state
   InputState.fsm:openInventory()

   local views = {
      getOrCreatePlayerInventoryView(playerInventory),
      getOrCreateToolbarView(playerToolbar),
   }

   -- Add all equipment views
   for _, equipView in ipairs(getOrCreateEquipmentViews(playerEquipment)) do
      table.insert(views, equipView)
   end

   InventoryViewManager:open(views)
end

function UICoordinator.openTargetInventory(entityId)
   local playerId = ENTITIES.Player
   if not entityId or not playerId then return end

   -- Transition input state
   InputState.fsm:openInventory()

   local targetInventory = get(entityId, FRAGMENTS.Inventory)
   local playerInventory, playerToolbar, playerEquipment = get(playerId,
      FRAGMENTS.Inventory, FRAGMENTS.Toolbar, FRAGMENTS.Equipment)

   local views = {
      getOrCreateToolbarView(playerToolbar),
      getOrCreatePlayerInventoryView(playerInventory),
      getOrCreateTargetInventoryView(targetInventory, entityId),
   }

   -- Add all equipment views
   for _, equipView in ipairs(getOrCreateEquipmentViews(playerEquipment)) do
      table.insert(views, equipView)
   end

   InventoryViewManager:open(views)
end

function UICoordinator.openMachineScreen(entityId)
   local playerId = ENTITIES.Player
   if not entityId or not playerId then return end

   -- Transition input state
   InputState.fsm:openInventory()

   local playerInventory, playerToolbar, playerEquipment = get(playerId,
      FRAGMENTS.Inventory, FRAGMENTS.Toolbar, FRAGMENTS.Equipment)

   local machineScreen = getOrCreateMachineScreenView(entityId)

   local views = {
      getOrCreateToolbarView(playerToolbar),
      getOrCreatePlayerInventoryView(playerInventory),
   }

   -- Add all equipment views
   for _, equipView in ipairs(equipmentViews) do
      table.insert(views, equipView)
   end

   MachineViewManager:open(machineScreen, views)
end

function UICoordinator.getToolbarView(toolbar)
   return getOrCreateToolbarView(toolbar)
end

function UICoordinator.getEquipmentViews(equipment)
   return getOrCreateEquipmentViews(equipment)
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
   if InventoryViewManager.isOpen then
      InventoryViewManager:close()
   end
   if MachineViewManager.isOpen then
      MachineViewManager:close()
   end
end

function UICoordinator.getInputState()
   return InputState.fsm
end

return UICoordinator
