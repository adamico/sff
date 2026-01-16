-- ============================================================================
-- Combat Behavior Registry
-- ============================================================================
-- Maps combat types to their behavior functions
-- The combat system uses this to look up the correct behavior when
-- entities attack each other
--
-- Usage:
--    local Combat = require("src.evolved.behaviors.combat")
--    local behavior = Combat.get("harvest")
--    behavior(context)
--
-- Adding a new combat type:
--    1. Create a new behavior module in combat/ (e.g., combat/melee_combat_behavior.lua)
--    2. Register it here with Combat.register("melee", require(...))

local Combat = {}

-- ============================================================================
-- Registry
-- ============================================================================

-- Registry table: attack type -> behavior function
local registry = {}

--- Register an combat behavior function
--- @param attackType string The attack type (e.g., "harvest", "melee"
--- @param behaviorFunction function The behavior: function(context) -> boolean
function Combat.register(attackType, behaviorFunction)
   if registry[attackType] then
      Log.warn("Combat: Overwriting existing behavior for type: "..attackType)
   end
   registry[attackType] = behaviorFunction
   Log.info("Combat: Registered behavior for type: "..attackType)
end

--- Get the behavior function for an attack type
--- @param attackType string The attack type
--- @return function|nil The behavior function, or nil if not found
function Combat.get(attackType)
   return registry[attackType]
end

--- Check if a behavior is registered for an attack type
--- @param attackType string The attack type
--- @return boolean
function Combat.has(attackType)
   return registry[attackType] ~= nil
end

--- Get all registered attack types
--- @return table Array of registered attack types
function Combat.getRegisteredTypes()
   local types = {}
   for attackType, _ in pairs(registry) do
      table.insert(types, attackType)
   end
   table.sort(types) -- Sort alphabetically for consistency
   return types
end

-- ============================================================================
-- Built-in Combat Behaviors
-- ============================================================================

Combat.register("harvest", require("src.evolved.behaviors.combat.harvest_combat_behavior"))
Combat.register("melee", require("src.evolved.behaviors.combat.melee_combat_behavior"))

-- Future combat types can be registered here:
-- Combat.register("ranged", require("src.evolved.behaviors.combat.ranged_combat_behavior"))
-- Combat.register("magic", require("src.evolved.behaviors.combat.magic_combat_behavior"))
-- Combat.register("explosive", require("src.evolved.behaviors.combat.explosive_combat_behavior"))

-- ============================================================================
-- Convenience Methods
-- ============================================================================

--- Execute a combat behavior with context
--- @param attackType string The attack type
--- @param context table The combat context
--- @return boolean True if attack was successful
function Combat.execute(attackType, context)
   local behavior = Combat.get(attackType)
   if not behavior then
      Log.warn("Combat: No behavior registered for attack type: "..attackType)
      return false
   end

   return behavior(context)
end

return Combat
