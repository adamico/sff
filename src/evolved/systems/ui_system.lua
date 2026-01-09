local InventoryView = require("src.ui.inventory_view")
local builder = Evolved.builder

local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local INV_GAP = 20
local TOOLBAR_ROWS = 1
local WIDTH = COLUMNS * SLOT_SIZE
local INV_HEIGHT = INV_ROWS * SLOT_SIZE
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * SLOT_SIZE + 8
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

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
   :name("SYSTEMS.UI")
   :group(STAGES.OnRender)
   :include(FRAGMENTS.Toolbar)
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
