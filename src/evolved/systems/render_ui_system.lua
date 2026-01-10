local lg = love.graphics
local builder = Evolved.builder
local observe = Beholder.observe
local group = Beholder.group
local InventoryView = require("src.ui.inventory_view")

local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local INV_GAP = 20
local TOOLBAR_ROWS = 1
local WIDTH = COLUMNS * SLOT_SIZE
local INV_HEIGHT = INV_ROWS * SLOT_SIZE
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * SLOT_SIZE + 8
local SCREEN_WIDTH, SCREEN_HEIGHT = lg.getDimensions()

local UI_OBSERVERS = {}
local observersRegistered = false

local function registerObservers()
   if observersRegistered then return end
   observersRegistered = true

   group(UI_OBSERVERS, function()
      observe(Events.ENTITY_INTERACTED, function()
         Log.trace("Entity interacted")
      end)
      observe(Events.INPUT_INVENTORY_OPENED, function(playerInventory)
         Log.trace("Inventory "..tostring(playerInventory).." opened")
      end)
      observe(Events.INPUT_INVENTORY_CLOSED, function()
         Log.trace("Inventory closed")
      end)
      observe(Events.INPUT_INVENTORY_CLICKED, function()
         Log.trace("Inventory clicked")
      end)
   end)
end

local toolbarView
local function getToolbarView(toolbar)
   if not toolbarView then
      if not toolbar then return nil end

      toolbarView = InventoryView:new(toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = (SCREEN_WIDTH - WIDTH) / 2,
         y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
      })
   end

   return toolbarView
end

builder()
   :name("SYSTEMS.RenderUI")
   :group(STAGES.OnRender)
   :include(FRAGMENTS.Toolbar)
   :prologue(function()
      registerObservers()
   end)
   :execute(function(chunk, _, entityCount)
      local toolbars = chunk:components(FRAGMENTS.Toolbar)

      for i = 1, entityCount do
         local toolbar = toolbars[i]
         toolbarView = getToolbarView(toolbar)
         if toolbarView then
            toolbarView:draw()
         end
      end
   end):build()
