local FlexInventoryView = require("src.ui.inventory_view")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local FlexMachineScreen = require("src.ui.machine_screen")
local MachineStateManager = require("src.ui.machine_state_manager")

local builder = Evolved.builder
local observe = Beholder.observe
local get = Evolved.get

-- Layout constants
local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local TOOLBAR_ROWS = 1
local BORDER_WIDTH = 2
local PADDING = 4
local GAP = 20

-- Calculated dimensions (matching inventory_view.lua calculateBoxDimensions)
local WIDTH = COLUMNS * (SLOT_SIZE - BORDER_WIDTH) + BORDER_WIDTH + PADDING * 2
local INV_HEIGHT = INV_ROWS * (SLOT_SIZE - BORDER_WIDTH) + BORDER_WIDTH + PADDING * 2
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * (SLOT_SIZE - BORDER_WIDTH) + BORDER_WIDTH + PADDING * 2

-- Screen dimensions
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local SCREEN_CENTER = Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

-- Machine screen layout constants
local MACHINE_WIDTH = 300
local MACHINE_HEIGHT = 200

-- Cached views (created lazily)
local toolbarView = nil
-- Don't cache playerInventoryView - it gets destroyed when closed

-- Position presets
local CENTERED_X = SCREEN_CENTER.x - WIDTH / 2
local TOOLBAR_Y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
local PLAYER_INV_Y = TOOLBAR_Y - GAP - INV_HEIGHT

local function getToolbarView(toolbar)
   if not toolbar then return nil end
   if not toolbarView then
      toolbarView = FlexInventoryView:new(toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = CENTERED_X,
         y = TOOLBAR_Y
      })
   end
   return toolbarView
end

local function getPlayerInventoryView(playerInventory)
   if not playerInventory then return nil end

   -- Always create new view since it gets destroyed when closed
   local playerInventoryView = FlexInventoryView:new(playerInventory, {
      id = "player_inventory",
      columns = COLUMNS,
      rows = INV_ROWS,
      x = CENTERED_X,
      y = PLAYER_INV_Y
   })

   return playerInventoryView
end

local function openPlayerInventory(playerInventory, playerToolbar)
   if not playerInventory then return end

   local views = {
      getToolbarView(playerToolbar),
      getPlayerInventoryView(playerInventory)
   }

   InventoryStateManager:open(views)
end

local function openTargetInventory(playerInventory, targetInventory, playerToolbar, entityId)
   if not playerInventory or not targetInventory then return end

   -- Calculate target inventory dimensions based on actual slot count
   local totalSlots = math.max(#targetInventory.slots, 1)

   -- Determine columns and rows based on slot count
   local targetColumns = math.min(totalSlots, COLUMNS)
   local targetRows = math.ceil(totalSlots / targetColumns)

   -- Calculate actual width and height for this inventory
   local targetWidth = targetColumns * (SLOT_SIZE - BORDER_WIDTH) + BORDER_WIDTH + PADDING * 2
   local targetHeight = targetRows * (SLOT_SIZE - BORDER_WIDTH) + BORDER_WIDTH + PADDING * 2

   -- Center the target inventory
   local targetX = SCREEN_CENTER.x - targetWidth / 2
   local targetY = PLAYER_INV_Y - GAP - targetHeight

   local options = {
      id = "target_inventory",
      columns = targetColumns,
      rows = targetRows,
      x = targetX,
      y = targetY,
      draggable = true,
      entityId = entityId or nil
   }

   local targetInventoryView = FlexInventoryView:new(targetInventory, options)

   local views = {
      getToolbarView(playerToolbar),
      getPlayerInventoryView(playerInventory),
      targetInventoryView,
   }

   InventoryStateManager:open(views)
end

local function openMachineScreen(entityId)
   if not entityId then return end

   -- Get player data for inventory views
   local playerId = ENTITIES.Player
   local playerInventory = get(playerId, FRAGMENTS.Inventory)
   local playerToolbar = get(playerId, FRAGMENTS.Toolbar)

   -- Position machine screen centered above player inventory
   local machineX = SCREEN_CENTER.x - MACHINE_WIDTH / 2
   local machineY = PLAYER_INV_Y - GAP - MACHINE_HEIGHT

   local machineScreen = FlexMachineScreen:new({
      entityId = entityId,
      x = machineX,
      y = machineY,
      width = MACHINE_WIDTH,
      height = MACHINE_HEIGHT
   })

   -- Create inventory views for player inventory and toolbar
   local views = {
      getToolbarView(playerToolbar),
      getPlayerInventoryView(playerInventory)
   }

   MachineStateManager:open(machineScreen, views)
end

local function closeMachineScreen()
   MachineStateManager:close()
end

-- Register event observers for entity/storage interaction (inventory view)
observe(Events.ENTITY_INTERACTED, function(playerInventory, targetInventory, playerToolbar, entityId)
   openTargetInventory(playerInventory, targetInventory, playerToolbar, entityId)
end)

-- Register event observers for machine interaction (machine screen)
observe(Events.MACHINE_INTERACTED, function(entityId)
   openMachineScreen(entityId)
end)

observe(Events.INPUT_INVENTORY_OPENED, function(playerInventory, playerToolbar)
   openPlayerInventory(playerInventory, playerToolbar)
end)

observe(Events.INPUT_INVENTORY_CLOSED, function()
   -- Close whichever screen is open
   if InventoryStateManager.isOpen then
      InventoryStateManager:close()
   end
   if MachineStateManager.isOpen then
      closeMachineScreen()
   end
end)

observe(Events.INPUT_INVENTORY_CLICKED, function(mouseX, mouseY, userdata)
   if InventoryStateManager.isOpen then
      InventoryStateManager:handleSlotClick(mouseX, mouseY, userdata)
   elseif MachineStateManager.isOpen then
      MachineStateManager:handleSlotClick(mouseX, mouseY, userdata)
   end
end)

-- Register the render system (runs every frame)
builder()
   :name("SYSTEMS.RenderUI")
   :group(STAGES.OnRender)
   :include(FRAGMENTS.Toolbar)
   :execute(function(chunk, _, entityCount)
      local toolbars = chunk:components(FRAGMENTS.Toolbar)

      for i = 1, entityCount do
         local toolbar = toolbars[i]
         local view = getToolbarView(toolbar)
         if view then
            view:draw()
         end
      end
   end)
   :epilogue(function()
      -- Update state managers (for held stack position tracking)
      local dt = UNIFORMS.getDeltaTime()
      if InventoryStateManager.isOpen then
         InventoryStateManager:update(dt)
         InventoryStateManager:draw()
      end
      if MachineStateManager.isOpen then
         MachineStateManager:update(dt)
         MachineStateManager:draw()
      end
   end)
   :build()
