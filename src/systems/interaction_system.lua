local InteractionSystem = Class("InteractionSystem")

function InteractionSystem:initialize(pool)
   self.pool = pool
   self.mouseDown = false
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
   local leftMousePressed = love.mouse.isDown(1)

   if leftMousePressed and not self.mouseDown then
      local mouseX, mouseY = love.mouse.getPosition()
      -- add transform when we add a camera
      self:tryMouseInteract(mouseX, mouseY)
   end

   self.mouseDown = leftMousePressed
end

function InteractionSystem:tryMouseInteract(mouseX, mouseY)
   -- Find the player entity
   local player = self.pool.groups.controllable.entities[1]
   if not player then return end

   local interactionRangeSquared = player.interactionRange ^ 2
   local closestEntity = nil
   local closestDistanceSquared = math.huge

   for _entityIndex, entity in ipairs(self.pool.groups.interactable.entities) do
      local dx, dy = mouseX - entity.position.x, mouseY - entity.position.y
      local distSquared = dx * dx + dy * dy
      -- check if mouse is over entity
      if distSquared <= entity.size.x ^ 2 then
         if getDistanceSquared(player, entity) <= interactionRangeSquared then
            self.pool:emit("player:interacted", entity)
            break
         end
      end
   end
end

--- Attempt to interact with the closest interactable entity in range
function InteractionSystem:tryInteract()
   -- Find the player entity
   local player = self.pool.groups.controllable.entities[1]
   if not player then return end

   local interactionRangeSquared = player.interactionRange ^ 2
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
