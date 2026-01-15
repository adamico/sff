-- ============================================================================
-- Assembler Behavior
-- ============================================================================
-- Main behavior module for Assembler-class machines
-- Orchestrates state behaviors, action handlers, and helper functions
--
-- Context structure:
-- {
--    machineId = number,           -- Entity ID
--    machineName = string,         -- Display name for logging
--    fsm = table,                  -- State machine instance
--    recipe = table,               -- Current recipe
--    inventory = table,            -- Machine inventory
--    inputQueue = table,           -- Input action queue
--    mana = table,                 -- {current, max}
--    processingTimer = table,      -- {current, saved}
--    dt = number,                  -- Delta time
-- }

local states = require("src.evolved.behaviors.machines.assembler.states")
local actions = require("src.evolved.behaviors.machines.assembler.actions")
local helpers = require("src.evolved.behaviors.machines.assembler.helpers")

local Assembler = {}

-- ============================================================================
-- Main Update Loop
-- ============================================================================

--- Update function called by the processing system
--- Dispatches to the appropriate state behavior
--- @param context table The update context
function Assembler.update(context)
   -- First, drain any pending actions from external sources
   actions.drainQueue(context)

   -- Then, run state-specific behavior
   local state = context.fsm.current
   local stateHandler = states[state]

   if stateHandler then
      stateHandler(context)
   else
      Log.warn("Assembler: No behavior defined for state: "..tostring(state))
   end
end

-- ============================================================================
-- Initialization
-- ============================================================================

--- Initialize the assembler behavior (setup observers, etc.)
function Assembler.init()
   actions.setupObservers()
end

-- Setup observers when module is loaded
Assembler.init()

return Assembler
