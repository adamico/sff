local EntityHelper = require("src.helpers.entity_helper")
local Behaviors = require("src.evolved.behaviors")
local trigger = Beholder.trigger
local execute = Evolved.execute
local builder = Evolved.builder
local get = Evolved.get

local damageableQuery = builder()
   :name("QUERIES.Damageable")
   :include(TAGS.Damageable)
   :build()

local attackerQuery = builder()
   :name("QUERIES.Attacker")
   :include(FRAGMENTS.Damage)
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
--- @param attackType string The attack type (defaults to "harvest")
--- @return boolean True if attack was successful
local function executeAttack(attackerId, targetId, attackType)
   attackType = attackType or "harvest" -- Default behavior

   local context = {
      attackerId = attackerId,
      targetId = targetId,
      attackType = attackType,
   }

   return Behaviors.combat.execute(attackType, context)
end

--- Simple damage application (legacy support)
--- @param attackerId number The attacking entity
--- @param targetId number The target entity
local function applyDamage(attackerId, targetId)
   return executeAttack(attackerId, targetId, "harvest")
end

return {
   findClosestDamageableEntity = findClosestDamageableEntity,
   executeAttack = executeAttack,
   applyDamage = applyDamage, -- Keep for backward compatibility
}
