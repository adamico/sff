local lg = love.graphics

local EntityDrawHelper = {}

-- Constants for hitbox visualization
local HITBOX_ALPHA = 0.3
local HITBOX_LINE_WIDTH = 2
local HITBOX_LABEL_OFFSET = 16

--- Draws a hitbox outline using world-space bounds from CollisionHelper.getHitboxBounds()
--- @param bounds table World-space bounds { shape, x, y, radius } or { shape, x, y, width, height }
--- @param color table {r, g, b, a} color values
--- @param label? string Optional label to draw above the hitbox
function EntityDrawHelper.drawHitbox(bounds, color, label)
   local x, y = bounds.x, bounds.y

   -- Store original line width to restore later
   local originalLineWidth = lg.getLineWidth()
   lg.setLineWidth(HITBOX_LINE_WIDTH)

   -- Draw semi-transparent fill for hitbox area
   local r, g, b = color[1], color[2], color[3]
   lg.setColor(r, g, b, HITBOX_ALPHA)

   local labelX, labelY = x, y
   if bounds.shape == "circle" then
      labelY = labelY - bounds.radius
      lg.circle("fill", x, y, bounds.radius)
   else -- rectangle (default) - x,y is center
      local halfW = bounds.width / 2
      local halfH = bounds.height / 2
      labelY = labelY - halfH
      lg.rectangle("fill", x - halfW, y - halfH, bounds.width, bounds.height)
   end

   -- Draw solid outline on top
   lg.setColor(color)

   if bounds.shape == "circle" then
      lg.circle("line", x, y, bounds.radius)
   else -- rectangle (default)
      local halfW = bounds.width / 2
      local halfH = bounds.height / 2
      lg.rectangle("line", x - halfW, y - halfH, bounds.width, bounds.height)
   end

   -- Draw label
   if label then
      lg.print(label, labelX, labelY - HITBOX_LABEL_OFFSET)
   end

   -- Restore original line width
   lg.setLineWidth(originalLineWidth)
end

return EntityDrawHelper
