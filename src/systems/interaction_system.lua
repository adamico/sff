local InteractionSystem = Class("InteractionSystem")

local lk = love.keyboard

function InteractionSystem:initialize(pool)
   self.pool = pool
   self.interactKeyDown = false
end

--- Calculate squared distance between two entities with position components
--- @param a table Entity with position (Vector)
--- @param b table Entity with position (Vector)
--- @return number Squared distance between entity centers
local function getDistanceSquared(a, b)
   local dx = a.position.x - b.position.x
   local dy = a.position.y - b.position.y
   return dx * dx + dy * dy
end

function InteractionSystem:update(dt)
   local interactPressed = lk.isScancodeDown("e")

   -- Only trigger on key down (not held)
   if interactPressed and not self.interactKeyDown then
      self:tryInteract()
   end

   self.interactKeyDown = interactPressed
end

--- Attempt to interact with the closest interactable entity in range
function InteractionSystem:tryInteract()
   -- Find the player entity
   local player = nil
   for _, entity in ipairs(self.pool.entities) do
      if entity.isPlayer then
         player = entity
         break
      end
   end

   if not player then return end

   local interactionRangeSquared = player.interactionRange * player.interactionRange
   local closestEntity = nil
   local closestDistanceSquared = math.huge

   -- Find the closest interactable entity within range
   for _, entity in ipairs(self.pool.groups.interactable.entities) do
      local distSquared = getDistanceSquared(player, entity)

      if distSquared <= interactionRangeSquared and distSquared < closestDistanceSquared then
         closestEntity = entity
         closestDistanceSquared = distSquared
      end
   end

   -- Emit event if we found an interactable entity in range
   if closestEntity then
      self.pool:emit("player:interacted", closestEntity)
   end
end

return InteractionSystem
