-- ============================================================================
-- Interaction Handler Registry
-- ============================================================================
-- Maps interaction types to their handler functions
-- The interaction system uses this to look up the correct handler when
-- entities are interacted with
--
-- Usage:
--    local Interactions = require("src.evolved.behaviors.interactions")
--    local handler = Interactions.get("creature")
--    handler(playerId, targetId, interactionData)
--
-- Adding a new interaction type:
--    1. Create a new handler module in interactions/ (e.g., interactions/npc.lua)
--    2. Register it here with Interactions.register("npc", require(...))

local Interactions = {}

-- ============================================================================
-- Registry
-- ============================================================================

-- Registry table: interaction type -> handler function
local registry = {}

--- Register an interaction handler function
--- @param interactionType string The interaction type (e.g., "creature", "machine")
--- @param handlerFunction function The handler: function(playerId, entityId, interaction)
function Interactions.register(interactionType, handlerFunction)
   if registry[interactionType] then
      Log.warn("Interactions: Overwriting existing handler for type: "..interactionType)
   end
   registry[interactionType] = handlerFunction
   Log.info("Interactions: Registered handler for type: "..interactionType)
end

--- Get the handler function for an interaction type
--- @param interactionType string The interaction type
--- @return function|nil The handler function, or nil if not found
function Interactions.get(interactionType)
   return registry[interactionType]
end

--- Check if a handler is registered for an interaction type
--- @param interactionType string The interaction type
--- @return boolean
function Interactions.has(interactionType)
   return registry[interactionType] ~= nil
end

--- Get all registered interaction types
--- @return table Array of registered interaction types
function Interactions.getRegisteredTypes()
   local types = {}
   for interactionType, _ in pairs(registry) do
      table.insert(types, interactionType)
   end
   table.sort(types) -- Sort alphabetically for consistency
   return types
end

-- ============================================================================
-- Built-in Interaction Handlers
-- ============================================================================

Interactions.register("creature", require("src.evolved.behaviors.interactions.creature"))
Interactions.register("machine", require("src.evolved.behaviors.interactions.machine"))
Interactions.register("storage", require("src.evolved.behaviors.interactions.storage"))

-- Future interaction types can be registered here:
-- Interactions.register("npc", require("src.evolved.behaviors.interactions.npc"))
-- Interactions.register("portal", require("src.evolved.behaviors.interactions.portal"))
-- Interactions.register("harvest", require("src.evolved.behaviors.interactions.harvest"))

return Interactions
