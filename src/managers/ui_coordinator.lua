-- ============================================================================
-- UI Coordinator
-- ============================================================================
-- Central coordinator for all UI screens and state
-- Manages view creation, positioning, and lifecycle

local InventoryView = require("src.ui.inventory_view")
local MachineScreen = require("src.ui.machine_screen")
local InventoryStateManager = require("src.managers.inventory_state_manager")
local MachineStateManager = require("src.managers.machine_state_manager")
local get = Evolved.get

-- ============================================================================
-- Layout Constants (centralized)
-- ============================================================================

local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local TOOLBAR_ROWS = 1
local PADDING = 4
local GAP = 20

local INV_WIDTH = COLUMNS * SLOT_SIZE + PADDING * 2
local INV_HEIGHT = INV_ROWS * SLOT_SIZE + PADDING * 2
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * SLOT_SIZE + PADDING * 2

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local SCREEN_CENTER = Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

local CENTERED_X = SCREEN_CENTER.x - INV_WIDTH / 2
local TOOLBAR_Y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
local PLAYER_INV_Y = TOOLBAR_Y - GAP - INV_HEIGHT

local MACHINE_WIDTH = 320
local MACHINE_HEIGHT = 240

-- ============================================================================
-- Cached Views (persistent)
-- ============================================================================

local toolbarView = nil
local equipmentView = nil

local function getOrCreateToolbarView(toolbar)
   if not toolbar then return nil end

   if not toolbarView then
      toolbarView = InventoryView:new(toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = CENTERED_X,
         y = TOOLBAR_Y
      })
   end

   return toolbarView
end

local function getOrCreateEquipmentView(equipment)
   if not equipment then return nil end
   if not equipmentView then
      equipmentView = InventoryView:new(equipment, {
         id = "equipment",
         columns = 2,
         rows = 1,
         x = 16,
         y = TOOLBAR_Y
      })
   end
   return equipmentView
end

local function getOrCreatePlayerInventoryView(playerInventory)
   if not playerInventory then return nil end
   return InventoryView:new(playerInventory, {
      id = "player_inventory",
      columns = COLUMNS,
      rows = INV_ROWS,
      x = CENTERED_X,
      y = PLAYER_INV_Y
   })
end

local function getOrCreateTargetInventoryView(targetInventory, entityId)
   if not targetInventory then return nil end

   local slots = #targetInventory.slots
   local targetColumns = math.min(slots, COLUMNS)
   local targetRows = math.ceil(slots / targetColumns)

   local targetWidth = targetColumns * SLOT_SIZE + PADDING * 2
   local targetHeight = targetRows * SLOT_SIZE + PADDING * 2
   local targetX = SCREEN_CENTER.x - targetWidth / 2
   local targetY = PLAYER_INV_Y - GAP - targetHeight

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
   local machineX = SCREEN_CENTER.x - MACHINE_WIDTH / 2
   local machineY = PLAYER_INV_Y - GAP - MACHINE_HEIGHT

   return MachineScreen:new({
      entityId = entityId,
      x = machineX,
      y = machineY,
      width = MACHINE_WIDTH,
      height = MACHINE_HEIGHT
   })
end

-- ============================================================================
-- Public API
-- ============================================================================

local UICoordinator = {}

function UICoordinator.openPlayerInventory(playerInventory, playerToolbar, playerEquipment)
   if not playerInventory then return end

   local views = {
      getOrCreatePlayerInventoryView(playerInventory),
      getOrCreateToolbarView(playerToolbar),
      getOrCreateEquipmentView(playerEquipment),
   }

   InventoryStateManager:open(views)
end

function UICoordinator.openTargetInventory(entityId)
   local playerId = ENTITIES.Player
   if not entityId or not playerId then return end

   local targetInventory = get(entityId, FRAGMENTS.Inventory)
   local playerInventory, playerToolbar, playerEquipment = get(playerId,
      FRAGMENTS.Inventory, FRAGMENTS.Toolbar, FRAGMENTS.Equipment)

   local views = {
      getOrCreateToolbarView(playerToolbar),
      getOrCreatePlayerInventoryView(playerInventory),
      getOrCreateEquipmentView(playerEquipment),
      getOrCreateTargetInventoryView(targetInventory, entityId),
   }

   InventoryStateManager:open(views)
end

function UICoordinator.openMachineScreen(entityId)
   local playerId = ENTITIES.Player
   if not entityId or not playerId then return end

   local playerInventory, playerToolbar, playerEquipment = get(playerId,
      FRAGMENTS.Inventory, FRAGMENTS.Toolbar, FRAGMENTS.Equipment)

   local machineScreen = getOrCreateMachineScreenView(entityId)

   local views = {
      getOrCreateToolbarView(playerToolbar),
      getOrCreatePlayerInventoryView(playerInventory),
      getOrCreateEquipmentView(playerEquipment),
   }

   MachineStateManager:open(machineScreen, views)
end

function UICoordinator.getToolbarView(toolbar)
   return getOrCreateToolbarView(toolbar)
end

function UICoordinator.getEquipmentView(equipment)
   return getOrCreateEquipmentView(equipment)
end

return UICoordinator
