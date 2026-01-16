-- ============================================================================
-- Harvest Combat Behavior
-- ============================================================================
-- Handles harvesting/gathering mechanics where the attacker damages a target
-- to extract resources (trees, rocks, plants, etc.)
--
-- Context structure:
-- {
--    attackerId = number,          -- Entity dealing damage
--    targetId = number,            -- Entity being harvested
--    attackType = string,          -- e.g., "harvest", "melee", "ranged"
-- }

local EntityHelper = require("src.helpers.entity_helper")

local trigger = Beholder.trigger
local get = Evolved.get

--- Calculate damage based on attacker's damage component
--- @param attackerId number The attacker's entity ID
--- @return number The calculated damage amount
local function calculateDamage(attackerId)
   local damageComponent = get(attackerId, FRAGMENTS.Damage)
   if not damageComponent then
      Log.warn(string.format("No damage component found for attacker: %s", attackerId))
      return 0
   end

   local damage = math.random(damageComponent.min, damageComponent.max)

   return damage
end


--- Check if the target can be harvested
--- @param targetId number The target's entity ID
--- @param damageType string The type of damage being dealt
--- @return boolean True if the target can be harvested, false otherwise
local function canHarvest(attackerId, targetId, damageType)
   local damagedStatComponent = get(targetId, FRAGMENTS[damageType])
   if not damagedStatComponent then
      Log.warn(string.format("No %s component found for target: %d", damageType, targetId))
      return false
   end

   if damagedStatComponent.current <= 0 then
      Log.warn(string.format("Target %d can't be harvested because it has no %s", targetId, damageType))
      return false
   end

   if attackerId == targetId then
      Log.warn(string.format("Target %d can't be harvested because it is the attacker", targetId))
      return false
   end

   local equipment = get(attackerId, FRAGMENTS.Equipment)
   if not equipment then
      Log.warn(string.format("No equipment component found for attacker: %d", attackerId))
      return false
   end

   if not EntityHelper.isEquippedWith(attackerId, "harvester") then
      Log.warn(string.format("Target %d can't be harvested because attacker %d is not equipped with a harvester",
         targetId, attackerId))
      return false
   end

   return true
end

local function execute(context)
   local attackerId = context.attackerId
   local targetId = context.targetId
   local damageType = context.damageType

   if not canHarvest(attackerId, targetId, damageType) then
      Log.warn(string.format("Target %d cannot be harvested", targetId))
      return false
   end

   local damage = calculateDamage(attackerId)
   if damage > 0 then
      trigger(Events.ENTITY_HARVESTED, attackerId, targetId, damage)
      Log.debug(string.format("Harvest: Entity %d harvested %d for %d", attackerId, targetId, damage))

      -- Optional: Trigger harvest-specific effects
      -- trigger(Events.HARVEST_HIT, targetId, damage)

      return true
   end

   return false
end

return execute
