-- ============================================================================
-- Melee Combat Behavior
-- ============================================================================
-- Handles melee combat mechanics where the attacker damages a target in close proximity
--
-- Context structure:
-- {
--    attackerId = number,          -- Entity dealing damage
--    targetId = number,            -- Entity being damaged
--    damagedStat = string,          -- The stat to damage (e.g., "Health")
--    attackType = string,          -- e.g., "melee"
-- }

local CombatHelpers = require("src.evolved.behaviors.combat.combat_helpers")

local trigger = Beholder.trigger

local function execute(context)
   local attackerId = context.attackerId
   local targetId = context.targetId
   local damagedStat = context.damagedStat or "Health"

   -- Validate the combat action (requires weapon equipment)
   local isValid, errorMsg = CombatHelpers.validateCombatAction(
      attackerId,
      targetId,
      damagedStat,
      "weapon"
   )

   if not isValid then
      Log.debug(string.format("Melee failed: %s", errorMsg))
      return false
   end

   -- Calculate and apply damage
   local damage = CombatHelpers.calculateDamage(attackerId)
   if damage > 0 then
      trigger(Events.ENTITY_DAMAGED, targetId, damage)
      Log.debug(string.format("Melee: Entity %d damaged %d for %d %s",
         attackerId, targetId, damage, damagedStat))
      return true
   end

   return false
end

return execute
