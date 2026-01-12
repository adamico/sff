local EntityHelper = {}

--- Calculate squared distance between two entities with position components
--- @param aId number Entity ID
--- @param bId number Entity ID
--- @return number Squared distance between entity centers
function EntityHelper.getDistanceSquared(aId, bId)
   local aCenter = EntityHelper.getEntityCenter(aId)
   local bCenter = EntityHelper.getEntityCenter(bId)
   local dx = aCenter.x - bCenter.x
   local dy = aCenter.y - bCenter.y
   return dx * dx + dy * dy
end

--- Calculate entity center based on visual representation
--- @param entityId number Entity with position and size (Vector)
--- @return table Entity center (Vector)
function EntityHelper.getEntityCenter(entityId)
   local position = Evolved.get(entityId, FRAGMENTS.Position)
   local size = Evolved.get(entityId, FRAGMENTS.Size)
   local shape = Evolved.get(entityId, FRAGMENTS.Shape)
   local x, y = position.x, position.y
   if shape == "rectangle" then
      local width, height = size.x, size.y
      x, y = x + width / 2, y + height / 2
   end
   return Vector(x, y)
end

--- Check if point is inside circle
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param entityId number Circle with position and radius (Vector)
--- @return boolean True if point is inside circle, false otherwise
local function pointIsInsideCircle(x, y, entityId)
   local position = Evolved.get(entityId, FRAGMENTS.Position)
   local size = Evolved.get(entityId, FRAGMENTS.Size)
   local dx, dy = x - position.x, y - position.y
   local distSquared = dx * dx + dy * dy
   return distSquared <= size.x ^ 2
end

--- Check if point is inside rectangle
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param entityId number Rectangle with position and size (Vector)
--- @return boolean True if point is inside rectangle, false otherwise
local function pointIsInsideRectangle(x, y, entityId)
   local position = Evolved.get(entityId, FRAGMENTS.Position)
   local size = Evolved.get(entityId, FRAGMENTS.Size)
   local left, top = position.x, position.y
   local right, bottom = left + size.x, top + size.y
   return x >= left and x <= right and y >= top and y <= bottom
end

--- Check if point is inside entity
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param entityId number Entity with position and shape (Vector)
--- @return boolean True if point is inside entity, false otherwise
function EntityHelper.pointIsInsideEntity(x, y, entityId)
   local shape = Evolved.get(entityId, FRAGMENTS.Shape)
   if shape == "circle" then
      return pointIsInsideCircle(x, y, entityId)
   elseif shape == "rectangle" then
      return pointIsInsideRectangle(x, y, entityId)
   end
   return false
end

return EntityHelper
