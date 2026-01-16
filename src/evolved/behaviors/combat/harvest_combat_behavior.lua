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
--- @return boolean True if the target can be harvested, false otherwise
local function canHarvest(targetId)
   local healthComponent = get(targetId, FRAGMENTS.Health)
   if not healthComponent then
      Log.warn(string.format("No health component found for target: %d", targetId))
      return false
   end

   -- Could add additional checks here:
   -- - Check if target has required tag
   -- - Check if attacker has required tool/equipment
   -- - Check if target is in harvestable state
   return healthComponent.current > 0
end

local function execute(context)
   local attackerId = context.attackerId
   local targetId = context.targetId

   if not canHarvest(targetId) then
      Log.warn(string.format("Target %d cannot be harvested", targetId))
      return false
   end

   local damage = calculateDamage(attackerId)
   if damage > 0 then
      trigger(Events.ENTITY_DAMAGED, targetId, damage)
      Log.debug(string.format("Harvest: Entity %d harvested %d for %d", attackerId, targetId, damage))

      -- Optional: Trigger harvest-specific effects
      -- trigger(Events.HARVEST_HIT, targetId, damage)

      return true
   end

   return false
end

return execute
