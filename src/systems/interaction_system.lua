local EntityUtils = require("src.entities.entity_utils")

local InteractionSystem = {}

local DEBOUNCE_TIME = 0.2 -- Minimum seconds between clicks

function InteractionSystem:init()
   self.mouseDown = false
   self.lastClickTime = 0
end

function InteractionSystem:update(dt)
   local leftMousePressed = love.mouse.isDown(1)
   local currentTime = love.timer.getTime()

   if leftMousePressed and not self.mouseDown then
      -- Debounce: ignore clicks that happen too quickly after the last one
      local timeSinceLastClick = currentTime - self.lastClickTime
      if timeSinceLastClick >= DEBOUNCE_TIME then
         self.lastClickTime = currentTime
         self:tryMouseInteract(love.mouse.getPosition())
      end
   end

   self.mouseDown = leftMousePressed
end

function InteractionSystem:tryMouseInteract(mouseX, mouseY)
   local player = self.pool.groups.controllable.entities[1]
   if not player then
      return
   end

   local interactionRangeSquared = player.interactionRange ^ 2
   local closestEntity = nil
   local closestDistanceSquared = math.huge

   for _, entity in ipairs(self.pool.groups.interactable.entities) do
      -- 1. check if mouse is over entity
      if EntityUtils.pointIsInsideEntity(mouseX, mouseY, entity) then
         -- 2. check if entity is inside player range interaction circle
         local playerEntityDistanceSquared = EntityUtils.getDistanceSquared(player, entity)
         if playerEntityDistanceSquared <= interactionRangeSquared
            and playerEntityDistanceSquared < closestDistanceSquared then
            closestEntity = entity
            closestDistanceSquared = playerEntityDistanceSquared
         end
      end
   end

   -- 3. Emit interaction event if we found an interactable entity in range
   if closestEntity then
      self.pool:emit("player:interacted", closestEntity)
   end
end

return InteractionSystem
