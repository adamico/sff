local InventoryDrawHelpers = require("src.ui.inventory_draw_helpers")
local InventoryLayout = require("src.config.inventory_layout"):new({
   slot_size = 32,
   padding = 4,
   border_width = 2,
   columns = 10,
   rows = 1,
   gap_between_inventories = 20
})

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local ToolbarRenderer = Class("ToolbarRenderer"):include(InventoryDrawHelpers)

--- @class ToolbarRenderer
--- @field player_toolbar table
--- @field layout table

--- Initialize the toolbar renderer with the given player toolbar.
--- @param player_toolbar table
function ToolbarRenderer:initialize(player_toolbar)
   self.player_toolbar = player_toolbar
   self.layout = InventoryLayout
end

function ToolbarRenderer:draw()
   local width = self.layout:getInventoryWidth()
   local height = self.layout:getInventoryHeight() + self.layout.padding
   local toolbar_x = SCREEN_WIDTH / 2 - width / 2
   local toolbar_y = SCREEN_HEIGHT - height
   self:drawBox(toolbar_x, toolbar_y, width, height)
   self:drawSlots(toolbar_x, toolbar_y, self.player_toolbar.input_slots)
end

return ToolbarRenderer
