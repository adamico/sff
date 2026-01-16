-- ============================================================================
-- Harvest Combat Behavior
-- ============================================================================
-- Handles harvesting mechanics where the attacker damages a target
-- to extract mana
--
-- Context structure:
-- {
--    attackerId = number,          -- Entity dealing damage
--    targetId = number,            -- Entity being harvested
--    damagedStat = string,          -- The stat to damage (e.g., "Mana")
--    attackType = string,          -- e.g., "harvest"
-- }

local CombatHelpers = require("src.evolved.behaviors.combat.combat_helpers")

local trigger = Beholder.trigger

local function execute(context)
   local attackerId = context.attackerId
   local targetId = context.targetId
   local damagedStat = context.damagedStat or "Mana"

   -- Validate the combat action (requires harvester equipment)
   local isValid, errorMsg = CombatHelpers.validateCombatAction(
      attackerId,
      targetId,
      damagedStat,
      "harvester"
   )

   if not isValid then
      Log.debug(string.format("Harvest failed: %s", errorMsg))
      return false
   end

   -- Calculate and apply damage
   local damage = CombatHelpers.calculateDamage(attackerId)
   if damage > 0 then
      trigger(Events.ENTITY_HARVESTED, attackerId, targetId, damage)
      Log.debug(string.format("Harvest: Entity %d harvested %d for %d %s",
         attackerId, targetId, damage, damagedStat))
      return true
   end

   return false
end

return execute
