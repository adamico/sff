-- ============================================================================
-- DamageDealer Behavior
-- ============================================================================
-- Main behavior module for DamageDealer-class creatures (e.g., Skeleton)
-- Orchestrates state behaviors for aggressive melee attackers
--
-- Context structure (passed by creature_system):
-- {
--    creatureId = number,   -- Entity ID
--    creatureName = string, -- Display name for logging
--    fsm = table,           -- State machine instance
--    position = table,      -- Current position vector
--    velocity = table,      -- Current velocity vector
--    visual = table,        -- Visual component
--    health = table,        -- Health component
--    dt = number,           -- Delta time
-- }

local states = require("src.evolved.behaviors.creatures.damage_dealer.states")

local DamageDealer = {}

-- ============================================================================
-- Main Update Loop
-- ============================================================================

--- Update function called by the creature processing system
--- Dispatches to the appropriate state behavior based on FSM current state
--- @param context table The update context
function DamageDealer.update(context)
   local state = context.fsm.current
   local stateHandler = states[state]

   if stateHandler then
      stateHandler(context)
   else
      Log.warn("DamageDealer: No behavior defined for state: "..tostring(state))
   end
end

return DamageDealer
