-- ============================================================================
-- Creature State Behaviors
-- ============================================================================
-- State-specific behavior functions for the Creature state machine
-- Each function receives a context table and can trigger FSM transitions
--
local get = Evolved.get
local set = Evolved.set

local states = {}
local DEBUG = true

-- ============================================================================
-- BLANK State - No recipe set
-- ============================================================================

--- Handle BLANK state
--- @param context table The update context
function states.blank(context)

end

-- ============================================================================
-- IDLE State -
-- ============================================================================

--- Handle IDLE state
--- @param context table The update context
function states.idle(context)

end

-- ============================================================================
-- DEAD State -
-- ============================================================================

--- Handle DEAD state -
--- @param context table The update context
function states.dead(context)

end

-- ============================================================================
-- LOOTED State -
-- ============================================================================

--- Handle LOOTED state
--- @param context table The update context
function states.looted(context)
   -- when the creature has been looted for a certain amount of time
   -- destroy it
   -- Evolved.destroy(entityId)
end

return states
