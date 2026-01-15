-- ============================================================================
-- Assembler Action Handlers
-- ============================================================================
-- Handles queued actions from external sources (UI, events, etc.)

local helpers = require("src.evolved.behaviors.machines.assembler.helpers")
local inputQueue = require("src.evolved.fragments.input_queue")

local actions = {}
local DEBUG = true

-- ============================================================================
-- Action Handler Functions
-- ============================================================================

--- Start the ritual if FSM can transition
--- @param context table The update context
--- @return boolean success True if action was handled
local function handleStartRitual(context)
   -- Validate preconditions
   if not helpers.isValidRecipe(context.recipe) then
      if DEBUG then
         Log.warn("Assembler: "..context.machineName.." no valid recipe set")
      end
      return false
   end

   if not helpers.hasRequiredIngredients(context.recipe, context.inventory) then
      if DEBUG then
         Log.warn("Assembler: "..context.machineName.." missing ingredients")
      end
      return false
   end

   -- Set processing timer and transition
   context.processingTimer.current = context.recipe.processingTime or 1
   context.fsm:startRitual()

   if DEBUG then
      Log.info("Assembler: "..context.machineName.." ritual started")
      Log.info("  Processing time: "..context.processingTimer.current.."s")
   end

   return true
end

-- ============================================================================
-- Action Registry
-- ============================================================================

--- Handlers for queued actions
--- Each handler receives the context and returns true if the action was handled
local ACTION_HANDLERS = {
   startRitual = handleStartRitual,
}

-- ============================================================================
-- Queue Processing
-- ============================================================================

--- Drain the input queue and process all pending actions
--- @param context table The update context
function actions.drainQueue(context)
   if not context.inputQueue then return end

   inputQueue.drain(context.inputQueue, function(action)
      local handler = ACTION_HANDLERS[action.type]
      if handler then
         handler(context)
      elseif DEBUG then
         Log.warn("Assembler: Unknown action type: "..tostring(action.type))
      end
   end)
end

-- ============================================================================
-- Event Observers
-- ============================================================================

--- Setup event observers for external action triggers
function actions.setupObservers()
   local observe = Beholder.observe
   local get = Evolved.get

   observe(Events.RITUAL_STARTED, function(payload)
      local queue = get(payload.entityId, FRAGMENTS.InputQueue)
      if queue then
         inputQueue.push(queue, {type = "startRitual"})
      end
      if DEBUG then
         Log.info("Assembler: "..payload.machineName.." enqueued startRitual")
      end
   end)
end

return actions
