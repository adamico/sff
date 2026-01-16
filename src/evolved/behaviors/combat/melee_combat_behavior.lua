-- ============================================================================
-- Melee Combat Behavior
-- ============================================================================
-- Handles melee combat mechanics where the attacker damages a target in close proximity
--
-- Context structure:
-- {
--    attackerId = number,          -- Entity dealing damage
--    targetId = number,            -- Entity being damaged
--    damageType = string,          -- The stat to damage (e.g., "Health")
--    attackType = string,          -- e.g., "melee"
-- }

local CombatHelpers = require("src.evolved.behaviors.combat.combat_helpers")

local trigger = Beholder.trigger

local function execute(context)
   local attackerId = context.attackerId
   local targetId = context.targetId
   local damageType = context.damageType or "Health"

   -- Validate the combat action (requires weapon equipment)
   local isValid, errorMsg = CombatHelpers.validateCombatAction(
      attackerId,
      targetId,
      damageType,
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
         attackerId, targetId, damage, damageType))
      return true
   end

   return false
end

return execute
