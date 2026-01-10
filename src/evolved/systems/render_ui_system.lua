local InventoryView = require("src.ui.inventory_view")
local InventoryStateManager = require("src.ui.inventory_state_manager")

local builder = Evolved.builder
local observe = Beholder.observe

local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local INV_GAP = 20
local TOOLBAR_ROWS = 1
local WIDTH = COLUMNS * SLOT_SIZE
local INV_HEIGHT = INV_ROWS * SLOT_SIZE
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * SLOT_SIZE + 8
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local SCREEN_CENTER = Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

-- Cached views (created lazily)
local toolbarView = nil
local playerInventoryView = nil

-- Position presets for player inventory
local PLAYER_INV_X = SCREEN_CENTER.x - WIDTH / 2
local PLAYER_INV_Y = SCREEN_CENTER.y - INV_HEIGHT / 2

local function getToolbarView(toolbar)
   if not toolbar then return nil end
   if not toolbarView then
      toolbarView = InventoryView:new(toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = SCREEN_CENTER.x - WIDTH / 2,
         y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
      })
   end
   return toolbarView
end

local function getPlayerInventoryView(playerInventory, withTarget)
   if not playerInventory then return nil end

   if not playerInventoryView then
      playerInventoryView = InventoryView:new(playerInventory, {
         id = "player_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = PLAYER_INV_X,
         y = PLAYER_INV_Y
      })
   end

   -- Update position based on whether target inventory is open
   if withTarget then
      playerInventoryView:setPosition(SCREEN_CENTER.x - WIDTH - INV_GAP / 2, PLAYER_INV_Y)
   else
      playerInventoryView:setPosition(PLAYER_INV_X, PLAYER_INV_Y)
   end

   return playerInventoryView
end

local function openPlayerInventory(playerInventory, playerToolbar)
   if not playerInventory then return end

   local views = {
      getToolbarView(playerToolbar),
      getPlayerInventoryView(playerInventory, false)
   }

   InventoryStateManager:open(views)
end

local function openTargetInventory(playerInventory, targetInventory, playerToolbar)
   if not playerInventory or not targetInventory then return end

   local targetInventoryView = InventoryView:new(targetInventory, {
      id = "target_inventory",
      columns = COLUMNS,
      rows = INV_ROWS,
      x = SCREEN_CENTER.x + INV_GAP / 2,
      y = SCREEN_CENTER.y - INV_HEIGHT / 2,
      draggable = true
   })

   local views = {
      getToolbarView(playerToolbar),
      getPlayerInventoryView(playerInventory, true),
      targetInventoryView,
   }

   InventoryStateManager:open(views)
end

-- Register event observers
observe(Events.ENTITY_INTERACTED, function(playerInventory, targetInventory, playerToolbar)
   openTargetInventory(playerInventory, targetInventory, playerToolbar)
end)

observe(Events.INPUT_INVENTORY_OPENED, function(playerInventory, playerToolbar)
   openPlayerInventory(playerInventory, playerToolbar)
end)

observe(Events.INPUT_INVENTORY_CLOSED, function()
   InventoryStateManager:close()
end)

observe(Events.INPUT_INVENTORY_CLICKED, function(mouseX, mouseY)
   InventoryStateManager:handleSlotClick(mouseX, mouseY)
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
      if InventoryStateManager.isOpen then
         InventoryStateManager:draw()
      end
   end)
   :build()
