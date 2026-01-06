local CollisionHelper = {}

--- Check circle/circle overlap
--- @param entityA table Entity with visual representation
--- @param entityB table Entity with visual representation
--- @return boolean
local function circleCircleCollision(entityA, entityB)
   local dx = entityA.x - entityB.x
   local dy = entityA.y - entityB.y
   local distance = math.sqrt(dx * dx + dy * dy)
   return distance <= entityA.radius + entityB.radius
end

--- Check circle/rectangle overlap
--- @param entityA table Entity with visual representation
--- @param entityB table Entity with visual representation
--- @return boolean
local function circleRectangleCollision(entityA, entityB)
   local dx = entityA.x - entityB.x
   local dy = entityA.y - entityB.y
   local halfWidth = entityB.width / 2
   local halfHeight = entityB.height / 2
   local closestX = math.max(-halfWidth, math.min(halfWidth, dx))
   local closestY = math.max(-halfHeight, math.min(halfHeight, dy))
   local distance = math.sqrt(closestX * closestX + closestY * closestY)
   return distance <= entityA.radius
end

--- Check rectangle/rectangle overlap
--- @param entityA table Entity with visual representation
--- @param entityB table Entity with visual representation
--- @return boolean
local function rectangleRectangleCollision(entityA, entityB)
   local dx = entityA.x - entityB.x
   local dy = entityA.y - entityB.y
   local halfWidthA = entityA.width / 2
   local halfHeightA = entityA.height / 2
   local halfWidthB = entityB.width / 2
   local halfHeightB = entityB.height / 2
   return math.abs(dx) <= halfWidthA + halfWidthB and math.abs(dy) <= halfHeightA + halfHeightB
end

--- Choose which collision detection algorithm to use
--- @param entityA table Entity with visual representation
--- @param entityB table Entity with visual representation
--- @return boolean true if entities are colliding, false otherwise
function CollisionHelper.areColliding(entityA, entityB)
   -- choose which collision detection algorithm to use
   if entityA.visual == "circle" and entityB.visual == "circle" then
      return circleCircleCollision(entityA, entityB)
   elseif entityA.visual == "rectangle" and entityB.visual == "rectangle" then
      return rectangleRectangleCollision(entityA, entityB)
   elseif entityA.visual == "circle" and entityB.visual == "rectangle" then
      return circleRectangleCollision(entityA, entityB)
   elseif entityA.visual == "rectangle" and entityB.visual == "circle" then
      return circleRectangleCollision(entityB, entityA)
   end
   return false
end

return CollisionHelper
