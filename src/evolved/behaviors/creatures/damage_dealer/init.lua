-- ============================================================================
-- DamageDealer Behavior
-- ============================================================================
-- Main behavior module for DamageDealer-class creatures
-- Orchestrates state behaviors
--
-- Context structure:
-- {
--    creatureId = number,   -- Entity ID
--    creatureName = string, -- Display name for logging
--    fsm = table,           -- State creature instance
-- }

local states = require("src.evolved.behaviors.creatures.damageDealer.states")

local DamageDealer = {}

-- ============================================================================
-- Main Update Loop
-- ============================================================================

--- Update function called by the processing system
--- Dispatches to the appropriate state behavior
--- @param context table The update context
function DamageDealer.update(context)
   -- Then, run state-specific behavior
   local state = context.fsm.current
   local stateHandler = states[state]

   if stateHandler then
      stateHandler(context)
   else
      Log.warn("DamageDealer: No behavior defined for state: "..tostring(state))
   end
end

-- ============================================================================
-- Initialization
-- ============================================================================

--- Initialize the damageDealer behavior (setup observers, etc.)
function DamageDealer.init()
   actions.setupObservers()
end

-- Setup observers when module is loaded
DamageDealer.init()

return DamageDealer
