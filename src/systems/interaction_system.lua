local EntityUtils = require("src.entities.entity_utils")
local InputHelper = require("src.helpers.input_helper")

local InteractionSystem = {}

local DEBOUNCE_TIME = 0.2 -- Minimum seconds between clicks

function InteractionSystem:init()
   self.clickDetector = InputHelper.createEdgeDetector({threshold = 0.2})
end

-- REFACTOR: pass dt as argument to edge detector
function InteractionSystem:update(_dt)
   if self.clickDetector:check(InputHelper.isActionPressed("interact")) then
      self:tryMouseInteract(love.mouse.getPosition())
   end
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
