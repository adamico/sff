local EntityHelper = {}

--- Calculate squared distance between two entities with position components
--- @param a table Entity with position (Vector)
--- @param b table Entity with position (Vector)
--- @return number Squared distance between entity centers
function EntityHelper.getDistanceSquared(a, b)
   local aCenter = EntityHelper.getEntityCenter(a)
   local bCenter = EntityHelper.getEntityCenter(b)
   local dx = aCenter.x - bCenter.x
   local dy = aCenter.y - bCenter.y
   return dx * dx + dy * dy
end

--- Calculate entity center based on visual representation
--- @param entity table Entity with position and size (Vector)
--- @return table Entity center (Vector)
function EntityHelper.getEntityCenter(entity)
   local x, y = entity.position.x, entity.position.y
   if entity.visual == "rectangle" then
      local width, height = entity.size.x, entity.size.y
      x, y = x + width / 2, y + height / 2
   end
   return Vector(x, y)
end

--- Check if point is inside circle
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param circle table Circle with position and radius (Vector)
--- @return boolean True if point is inside circle, false otherwise
local function pointIsInsideCircle(x, y, circle)
   local dx, dy = x - circle.position.x, y - circle.position.y
   local distSquared = dx * dx + dy * dy
   return distSquared <= circle.size.x ^ 2
end

--- Check if point is inside rectangle
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param rectangle table Rectangle with position and size (Vector)
--- @return boolean True if point is inside rectangle, false otherwise
local function pointIsInsideRectangle(x, y, rectangle)
   local left, top = rectangle.position.x, rectangle.position.y
   local right, bottom = left + rectangle.size.x, top + rectangle.size.y
   return x >= left and x <= right and y >= top and y <= bottom
end

--- Check if point is inside entity
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param entity table Entity with position and visual type
--- @return boolean True if point is inside entity, false otherwise
function EntityHelper.pointIsInsideEntity(x, y, entity)
   if entity.visual == "circle" then
      return pointIsInsideCircle(x, y, entity)
   elseif entity.visual == "rectangle" then
      return pointIsInsideRectangle(x, y, entity)
   end
   return false
end

return EntityHelper
