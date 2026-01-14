local lg = love.graphics

local EntityDrawHelper = {}

--- Draws an entity shape at the given position with the specified color.
--- Position is treated as:
--- - Circle: center point
--- - Rectangle: top-left corner (matching existing entity system)
--- @param shape string "circle" or "rectangle"
--- @param position table Vector with x, y - center for circles, top-left for rectangles
--- @param size table brinevector with x, y (width, height) or (radius, _) for circles
--- @param color table {r, g, b, a} color values
--- @param label? string Optional label to draw above the entity
function EntityDrawHelper.drawShape(shape, position, size, color, label)
   local px, py = position:split()

   lg.setColor(color)

   local labelX, labelY = px, py
   if shape == "circle" then
      labelY = labelY - size.x
      lg.circle("fill", px, py, size.x)
   else -- rectangle (default)
      lg.rectangle("fill", px, py, size.x, size.y)
   end

   if label then
      lg.print(label, labelX, labelY - 16)
   end
end

return EntityDrawHelper
