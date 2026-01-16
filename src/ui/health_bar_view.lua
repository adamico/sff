-- ============================================================================
-- Health Bar View
-- ============================================================================
-- Renders health bars in world-space above entities

local HealthBarView = Class("HealthBarView")
local BarDrawHelper = require("src.helpers.bar_draw_helper")

-- Default visual constants
local DEFAULT_WIDTH = 50
local DEFAULT_HEIGHT = 10
local DEFAULT_OFFSET_Y = 15
local DEFAULT_BORDER_WIDTH = 1
local DEFAULT_BORDER_GAP = 1

local DEFAULT_BACKGROUND_COLOR = {1, 0, 0, 1} -- Red (empty health)
local DEFAULT_FILL_COLOR = {0, 1, 0, 1}       -- Green (current health)
local LOW_HEALTH_COLOR = {1, 0.5, 0, 1}       -- Orange (low health
local DEFAULT_BORDER_COLOR = {1, 1, 1, 1}     -- White border

--- @class HealthBarView
--- @field width number Width of the health bar
--- @field height number Height of the health bar
--- @field offsetY number Vertical offset above entity position
--- @field borderWidth number Border line width
--- @field borderGap number Gap between bar and border
--- @field backgroundColor table RGBA color for empty health (background)
--- @field fillColor table RGBA color for current health (fill)
--- @field borderColor table RGBA color for border

--- Create a new HealthBarView with customizable options
--- @param options table|nil Optional configuration
function HealthBarView:initialize(options)
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

--- Draw a health bar at the specified position
--- @param position table Vector with x, y coordinates (entity center position)
--- @param current number Current health value
--- @param max number Maximum health value
function HealthBarView:draw(position, current, max)
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

--- Draw a health bar with low health warning (changes color when health is low)
--- @param position table Vector with x, y coordinates
--- @param current number Current health value
--- @param max number Maximum health value
--- @param lowHealthThreshold number|nil Threshold ratio for low health warning (default 0.25)
function HealthBarView:drawWithWarning(position, current, max, lowHealthThreshold)
   if not position or not current or not max or max <= 0 then return end

   lowHealthThreshold = lowHealthThreshold or 0.25
   local healthRatio = current / max

   -- Temporarily change fill color if health is low
   local originalFillColor = self.fillColor
   if healthRatio <= lowHealthThreshold then
      self.fillColor = LOW_HEALTH_COLOR
   end

   self:draw(position, current, max)
   self.fillColor = originalFillColor
end

return HealthBarView
