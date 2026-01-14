local CollisionHelper = {}

--- Compute world-space hitbox bounds from position and hitbox fragment
--- @param position table Vector with x, y
--- @param hitbox table Hitbox fragment with shape, offset, and dimensions
--- @return table World-space bounds { shape, x, y, radius } or { shape, x, y, width, height }
function CollisionHelper.getHitboxBounds(position, hitbox)
   local x = position.x + hitbox.offsetX
   local y = position.y + hitbox.offsetY

   if hitbox.shape == "circle" then
      return {
         shape = "circle",
         x = x,
         y = y,
         radius = hitbox.radius,
      }
   else
      return {
         shape = "rectangle",
         x = x,
         y = y,
         width = hitbox.width,
         height = hitbox.height,
      }
   end
end

--- Check circle/circle overlap
--- @param boundsA table Circle bounds { x, y, radius }
--- @param boundsB table Circle bounds { x, y, radius }
--- @return boolean
local function circleCircleCollision(boundsA, boundsB)
   local dx = boundsA.x - boundsB.x
   local dy = boundsA.y - boundsB.y
   local distance = math.sqrt(dx * dx + dy * dy)
   return distance <= boundsA.radius + boundsB.radius
end

--- Check circle/rectangle overlap
--- @param circle table Circle bounds { x, y, radius }
--- @param rect table Rectangle bounds { x, y, width, height } (x,y is center)
--- @return boolean
local function circleRectangleCollision(circle, rect)
   -- Rectangle x,y is center
   local dx = circle.x - rect.x
   local dy = circle.y - rect.y
   local halfWidth = rect.width / 2
   local halfHeight = rect.height / 2
   local closestX = math.max(-halfWidth, math.min(halfWidth, dx))
   local closestY = math.max(-halfHeight, math.min(halfHeight, dy))
   local distX = dx - closestX
   local distY = dy - closestY
   local distance = math.sqrt(distX * distX + distY * distY)
   return distance <= circle.radius
end

--- Check rectangle/rectangle overlap
--- @param boundsA table Rectangle bounds { x, y, width, height } (x,y is center)
--- @param boundsB table Rectangle bounds { x, y, width, height } (x,y is center)
--- @return boolean
local function rectangleRectangleCollision(boundsA, boundsB)
   local dx = boundsA.x - boundsB.x
   local dy = boundsA.y - boundsB.y
   local halfWidthA = boundsA.width / 2
   local halfHeightA = boundsA.height / 2
   local halfWidthB = boundsB.width / 2
   local halfHeightB = boundsB.height / 2
   return math.abs(dx) <= halfWidthA + halfWidthB and math.abs(dy) <= halfHeightA + halfHeightB
end

--- Check if two hitbox bounds are colliding
--- @param boundsA table World-space bounds from getHitboxBounds
--- @param boundsB table World-space bounds from getHitboxBounds
--- @return boolean true if colliding, false otherwise
function CollisionHelper.areColliding(boundsA, boundsB)
   if boundsA.shape == "circle" and boundsB.shape == "circle" then
      return circleCircleCollision(boundsA, boundsB)
   elseif boundsA.shape == "rectangle" and boundsB.shape == "rectangle" then
      return rectangleRectangleCollision(boundsA, boundsB)
   elseif boundsA.shape == "circle" and boundsB.shape == "rectangle" then
      return circleRectangleCollision(boundsA, boundsB)
   elseif boundsA.shape == "rectangle" and boundsB.shape == "circle" then
      return circleRectangleCollision(boundsB, boundsA)
   end
   return false
end

--- Get push vector to separate two colliding bounds
--- Returns the vector to apply to boundsA to push it away from boundsB
--- @param boundsA table World-space bounds
--- @param boundsB table World-space bounds
--- @return number, number Push vector (dx, dy) or (0, 0) if not colliding
function CollisionHelper.getPushVector(boundsA, boundsB)
   if boundsA.shape == "circle" and boundsB.shape == "circle" then
      return CollisionHelper.getCircleCirclePush(boundsA, boundsB)
   elseif boundsA.shape == "rectangle" and boundsB.shape == "rectangle" then
      return CollisionHelper.getRectangleRectanglePush(boundsA, boundsB)
   elseif boundsA.shape == "circle" and boundsB.shape == "rectangle" then
      return CollisionHelper.getCircleRectanglePush(boundsA, boundsB)
   elseif boundsA.shape == "rectangle" and boundsB.shape == "circle" then
      local dx, dy = CollisionHelper.getCircleRectanglePush(boundsB, boundsA)
      return -dx, -dy
   end
   return 0, 0
end

--- Get push vector for circle-circle collision
function CollisionHelper.getCircleCirclePush(circleA, circleB)
   local dx = circleA.x - circleB.x
   local dy = circleA.y - circleB.y
   local distance = math.sqrt(dx * dx + dy * dy)
   local overlap = circleA.radius + circleB.radius - distance

   if overlap <= 0 then
      return 0, 0
   end

   if distance == 0 then
      -- Circles are exactly on top of each other, push in arbitrary direction
      return overlap, 0
   end

   -- Normalize and scale by overlap
   local nx = dx / distance
   local ny = dy / distance
   return nx * overlap, ny * overlap
end

--- Get push vector for rectangle-rectangle collision (AABB)
function CollisionHelper.getRectangleRectanglePush(rectA, rectB)
   local dx = rectA.x - rectB.x
   local dy = rectA.y - rectB.y
   local overlapX = (rectA.width / 2 + rectB.width / 2) - math.abs(dx)
   local overlapY = (rectA.height / 2 + rectB.height / 2) - math.abs(dy)

   if overlapX <= 0 or overlapY <= 0 then
      return 0, 0
   end

   -- Push along axis of minimum overlap
   if overlapX < overlapY then
      return dx > 0 and overlapX or -overlapX, 0
   else
      return 0, dy > 0 and overlapY or -overlapY
   end
end

--- Get push vector for circle-rectangle collision
function CollisionHelper.getCircleRectanglePush(circle, rect)
   local dx = circle.x - rect.x
   local dy = circle.y - rect.y
   local halfWidth = rect.width / 2
   local halfHeight = rect.height / 2

   -- Find closest point on rectangle to circle center
   local closestX = math.max(-halfWidth, math.min(halfWidth, dx))
   local closestY = math.max(-halfHeight, math.min(halfHeight, dy))

   local distX = dx - closestX
   local distY = dy - closestY
   local distance = math.sqrt(distX * distX + distY * distY)

   if distance >= circle.radius then
      return 0, 0
   end

   if distance == 0 then
      -- Circle center is inside rectangle, push out along shortest axis
      local pushX = halfWidth - math.abs(dx)
      local pushY = halfHeight - math.abs(dy)
      if pushX < pushY then
         return dx >= 0 and (pushX + circle.radius) or -(pushX + circle.radius), 0
      else
         return 0, dy >= 0 and (pushY + circle.radius) or -(pushY + circle.radius)
      end
   end

   -- Push circle away from closest point
   local overlap = circle.radius - distance
   local nx = distX / distance
   local ny = distY / distance
   return nx * overlap, ny * overlap
end

return CollisionHelper
