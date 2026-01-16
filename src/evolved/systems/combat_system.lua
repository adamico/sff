local EntityHelper = require("src.helpers.entity_helper")
local Behaviors = require("src.evolved.behaviors")
local execute = Evolved.execute
local builder = Evolved.builder

local damageableQuery = builder()
   :name("QUERIES.Damageable")
   :include(TAGS.Damageable)
   :build()

local harvestableQuery = builder()
   :name("QUERIES.Harvestable")
   :include(TAGS.Harvestable)
   :build()

--- Find the closest damageable entity within range
--- @param attackerId number The attacking entity ID
--- @param maxRange number Maximum attack range
--- @return number|nil The closest entity ID or nil
local function findClosestDamageableEntity(attackerId, maxRange)
   local maxRangeSquared = maxRange ^ 2
   local closestEntityId = nil
   local closestDistanceSquared = math.huge

   for _chunk, entityIds, entityCount in execute(damageableQuery) do
      for i = 1, entityCount do
         local entityId = entityIds[i]
         if entityId ~= attackerId then
            local distanceSquared = EntityHelper.getDistanceSquared(attackerId, entityId)
            if distanceSquared <= maxRangeSquared and distanceSquared < closestDistanceSquared then
               closestEntityId = entityId
               closestDistanceSquared = distanceSquared
            end
         end
      end
   end

   return closestEntityId
end

--- Execute an attack from attacker to target using specified behavior
--- @param attackerId number The attacking entity
--- @param targetId number The target entity
--- @param damageType string The damage type (defaults to "Health")
--- @param attackType string The attack type (defaults to "harvest")
--- @return boolean True if attack was successful
local function executeAttack(attackerId, targetId, damageType, attackType)
   attackType = attackType or "harvest" -- Default behavior
   damageType = damageType or "Health"  -- Default damage type

   local context = {
      attackerId = attackerId,
      targetId = targetId,
      damageType = damageType,
      attackType = attackType,
   }

   return Behaviors.combat.execute(attackType, context)
end

return {
   findClosestDamageableEntity = findClosestDamageableEntity,
   executeAttack = executeAttack,
}
