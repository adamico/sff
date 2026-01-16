-- ============================================================================
-- Mana Bar View
-- ============================================================================
-- Renders mana bars in world-space above entities

local ManaBarView = Class("ManaBarView")
local BarDrawHelper = require("src.helpers.bar_draw_helper")

-- Default visual constants
local DEFAULT_WIDTH = 50
local DEFAULT_HEIGHT = 10
local DEFAULT_OFFSET_Y = 30
local DEFAULT_BORDER_WIDTH = 1
local DEFAULT_BORDER_GAP = 1

local DEFAULT_BACKGROUND_COLOR = {0.5, 0.45, 0.5}
local DEFAULT_FILL_COLOR = {0.3, 0.5, 0.9}
local DEFAULT_BORDER_COLOR = {1, 1, 1, 1}

--- @class ManaBarView
--- @field width number Width of the mana bar
--- @field height number Height of the mana bar
--- @field offsetY number Vertical offset above entity position
--- @field borderWidth number Border line width
--- @field borderGap number Gap between bar and border
--- @field backgroundColor table RGBA color for empty mana (background)
--- @field fillColor table RGBA color for current mana (fill)
--- @field borderColor table RGBA color for border


--- Create a new ManaBarView with customizable options
--- @param options table|nil Optional configuration
function ManaBarView:initialize(options)
   options = options or {}

   self.width = options.width or DEFAULT_WIDTH
   self.height = options.height or DEFAULT_HEIGHT
   self.offsetY = options.offsetY or DEFAULT_OFFSET_Y
   self.borderWidth = options.borderWidth or DEFAULT_BORDER_WIDTH
   self.borderGap = options.borderGap or DEFAULT_BORDER_GAP

   self.backgroundColor = options.backgroundColor or DEFAULT_BACKGROUND_COLOR
   self.fillColor = options.fillColor or DEFAULT_FILL_COLOR
   self.borderColor = options.borderColor or DEFAULT_BORDER_COLOR
end

--- Draw a mana bar at the specified position
--- @param position table Vector with x, y coordinates (entity center position)
--- @param current number Current mana value
--- @param max number Maximum mana value
function ManaBarView:draw(position, current, max)
   if not position or not current or not max or max <= 0 then return end

   BarDrawHelper.draw({
      position = position,
      width = self.width,
      height = self.height,
      offsetY = self.offsetY,
      current = current,
      max = max,
      backgroundColor = self.backgroundColor,
      fillColor = self.fillColor,
      borderColor = self.borderColor,
      borderWidth = self.borderWidth,
      borderGap = self.borderGap
   })
end

return ManaBarView
