local EntityHelper = require("src.helpers.entity_helper")
local InteractionSystem = {}

function InteractionSystem:init()
   self.pool:on(Events.INPUT_INTERACT, function()
      self:tryMouseInteract(love.mouse.getPosition())
   end)
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
      if EntityHelper.pointIsInsideEntity(mouseX, mouseY, entity) then
         -- 2. check if entity is inside player range interaction circle
         local playerEntityDistanceSquared = EntityHelper.getDistanceSquared(player, entity)
         if playerEntityDistanceSquared <= interactionRangeSquared
            and playerEntityDistanceSquared < closestDistanceSquared then
            closestEntity = entity
            closestDistanceSquared = playerEntityDistanceSquared
         end
      end
   end

   -- 3. Emit interaction event if we found an interactable entity in range
   if closestEntity then
      self.pool:emit(Events.ENTITY_INTERACTED, {player_entity = player, target_entity = closestEntity})
   end
end

return InteractionSystem
