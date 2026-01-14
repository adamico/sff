local lg = love.graphics

local EntityDrawHelper = {}

-- Constants for hitbox visualization
local HITBOX_ALPHA = 0.3
local HITBOX_LINE_WIDTH = 2
local HITBOX_LABEL_OFFSET = 16

--- Draws a hitbox outline at the given position with the specified color.
--- Position is treated as:
--- - Circle: center point
--- - Rectangle: top-left corner (matching existing entity system)
--- @param shape string "circle" or "rectangle"
--- @param position table Vector with x, y - center for circles, top-left for rectangles
--- @param size table brinevector with x, y (width, height) or (radius, _) for circles
--- @param color table {r, g, b, a} color values
--- @param label? string Optional label to draw above the entity
function EntityDrawHelper.drawHitbox(shape, position, size, color, label)
   local px, py = position:split()

   -- Store original line width to restore later
   local originalLineWidth = lg.getLineWidth()
   lg.setLineWidth(HITBOX_LINE_WIDTH)

   -- Draw semi-transparent fill for hitbox area
   local r, g, b = color[1], color[2], color[3]
   lg.setColor(r, g, b, HITBOX_ALPHA)

   local labelX, labelY = px, py
   if shape == "circle" then
      labelY = labelY - size.x
      lg.circle("fill", px, py, size.x)
   else -- rectangle (default)
      lg.rectangle("fill", px, py, size.x, size.y)
   end

   -- Draw solid outline on top
   lg.setColor(color)

   if shape == "circle" then
      lg.circle("line", px, py, size.x)
   else -- rectangle (default)
      lg.rectangle("line", px, py, size.x, size.y)
   end

   -- Draw label
   if label then
      lg.print(label, labelX, labelY - HITBOX_LABEL_OFFSET)
   end

   -- Restore original line width
   lg.setLineWidth(originalLineWidth)
end

return EntityDrawHelper
