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

--- Calculate entity center based on hitbox
--- @param entityId number Entity with position and hitbox
--- @return table Entity center (Vector)
function EntityHelper.getEntityCenter(entityId)
   local position = Evolved.get(entityId, FRAGMENTS.Position)
   local hitbox = Evolved.get(entityId, FRAGMENTS.Hitbox)

   if not hitbox then
      return Vector(position.x, position.y)
   end

   local x = position.x + (hitbox.offsetX or 0)
   local y = position.y + (hitbox.offsetY or 0)

   -- For rectangles, add half width/height to get center
   if hitbox.shape == "rectangle" then
      x = x + (hitbox.width or 16) / 2
      y = y + (hitbox.height or 16) / 2
   end
   -- For circles, the offset already points to center

   return Vector(x, y)
end

--- Check if point is inside circle hitbox
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param entityId number Entity with position and hitbox
--- @return boolean True if point is inside circle, false otherwise
local function pointIsInsideCircle(x, y, entityId)
   local position = Evolved.get(entityId, FRAGMENTS.Position)
   local hitbox = Evolved.get(entityId, FRAGMENTS.Hitbox)
   -- Apply hitbox offset to get center
   local centerX = position.x + (hitbox.offsetX or 0)
   local centerY = position.y + (hitbox.offsetY or 0)
   local dx, dy = x - centerX, y - centerY
   local distSquared = dx * dx + dy * dy
   local radius = hitbox.radius or 8
   return distSquared <= radius * radius
end

--- Check if point is inside rectangle hitbox
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param entityId number Entity with position and hitbox
--- @return boolean True if point is inside rectangle, false otherwise
local function pointIsInsideRectangle(x, y, entityId)
   local position = Evolved.get(entityId, FRAGMENTS.Position)
   local hitbox = Evolved.get(entityId, FRAGMENTS.Hitbox)
   -- Apply hitbox offset
   local left = position.x + (hitbox.offsetX or 0) - (hitbox.width or 16) / 2
   local top = position.y + (hitbox.offsetY or 0) - (hitbox.height or 16) / 2
   local right = left + (hitbox.width or 16)
   local bottom = top + (hitbox.height or 16)
   return x >= left and x <= right and y >= top and y <= bottom
end

--- Check if point is inside entity hitbox
--- @param x number X coordinate of point
--- @param y number Y coordinate of point
--- @param entityId number Entity with position and hitbox
--- @return boolean True if point is inside entity, false otherwise
function EntityHelper.pointIsInsideEntity(x, y, entityId)
   local hitbox = Evolved.get(entityId, FRAGMENTS.Hitbox)
   if not hitbox then return false end

   if hitbox.shape == "circle" then
      return pointIsInsideCircle(x, y, entityId)
   elseif hitbox.shape == "rectangle" then
      return pointIsInsideRectangle(x, y, entityId)
   end
   return false
end

return EntityHelper
