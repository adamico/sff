local lg = love.graphics
local InventoryView = require("src.ui.inventory_view")
local builder = Evolved.builder
local observe = Beholder.observe
local group = Beholder.group

local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local INV_GAP = 20
local TOOLBAR_ROWS = 1
local WIDTH = COLUMNS * SLOT_SIZE
local INV_HEIGHT = INV_ROWS * SLOT_SIZE
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * SLOT_SIZE + 8
local SCREEN_WIDTH, SCREEN_HEIGHT = lg.getDimensions()

builder()
   :name("SYSTEMS.Rendering")
   :group(STAGES.OnRender)
   :include(TAGS.Visual, TAGS.Physical)
   :execute(function(chunk, _, entityCount)
      local positions, sizes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Size)
      local visuals = chunk:components(FRAGMENTS.Shape)
      local colors = chunk:components(FRAGMENTS.Color)

      for i = 1, entityCount do
         local px, py = positions[i]:split()
         local size = sizes[i]
         local visual = visuals[i]
         local color = colors[i]

         lg.setColor(color)
         if visual == "circle" then
            lg.circle("fill", px, py, size.x)
         elseif visual == "rectangle" then
            lg.rectangle("fill", px, py, size.x, size.y)
         end
      end
   end):build()

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

builder()
   :name("SYSTEMS.UI")
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

builder()
   :name("SYSTEMS.Debugging")
   :group(STAGES.OnRender)
   :epilogue(function()
      local fps = love.timer.getFPS()
      local mem = collectgarbage("count")
      lg.print(string.format("FPS: %d", fps), 10, 10)
      lg.print(string.format("Memory: %d KB", mem), 10, 30)
   end):build()
