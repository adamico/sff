-- ============================================================================
-- Behavior Module
-- ============================================================================
-- Main entry point for all behaviors in the ECS
-- Exports both machine behaviors and interaction handlers
--
-- Usage:
--    local Behaviors = require("src.evolved.behaviors")
--
--    -- Access machine behaviors
--    local assemblerBehavior = Behaviors.machines.get("Assembler")
--    assemblerBehavior.update(context)
--
--    -- Access interaction handlers
--    local storageHandler = Behaviors.interactions.get("storage")
--    storageHandler(playerId, entityId, interactionData)

local Behaviors = {}

-- ============================================================================
-- Sub-modules
-- ============================================================================

--- Machine behavior registry (for processing systems)
Behaviors.machines = require("src.evolved.behaviors.machines")

--- Interaction handler registry (for interaction systems)
Behaviors.interactions = require("src.evolved.behaviors.interactions")

-- ============================================================================
-- Convenience Methods
-- ============================================================================

--- Get a machine behavior by class name
--- @param className string The machine class name
--- @return table|nil The behavior module
function Behaviors.getMachineBehavior(className)
   return Behaviors.machines.get(className)
end

--- Get an interaction handler by type
--- @param interactionType string The interaction type
--- @return function|nil The handler function
function Behaviors.getInteractionHandler(interactionType)
   return Behaviors.interactions.get(interactionType)
end

--- Check if a machine behavior exists
--- @param className string The machine class name
--- @return boolean
function Behaviors.hasMachineBehavior(className)
   return Behaviors.machines.has(className)
end

--- Check if an interaction handler exists
--- @param interactionType string The interaction type
--- @return boolean
function Behaviors.hasInteractionHandler(interactionType)
   return Behaviors.interactions.has(interactionType)
end

-- ============================================================================
-- Diagnostic Methods
-- ============================================================================

--- Get a summary of all registered behaviors
--- @return table Summary information
function Behaviors.getSummary()
   return {
      machines = Behaviors.machines.getRegisteredClasses(),
      interactions = Behaviors.interactions.getRegisteredTypes(),
   }
end

--- Print a summary of all registered behaviors to console
function Behaviors.printSummary()
   local summary = Behaviors.getSummary()

   print("\n=== Behavior Registry Summary ===")

   print("\nRegistered Machine Behaviors:")
   for _, className in ipairs(summary.machines) do
      print("  - "..className)
   end

   print("\nRegistered Interaction Handlers:")
   for _, interactionType in ipairs(summary.interactions) do
      print("  - "..interactionType)
   end

   print("\nTotal: "..#summary.machines.." machines, "..#summary.interactions.." interactions")
   print("=================================\n")
end

return Behaviors
