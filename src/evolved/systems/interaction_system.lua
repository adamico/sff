local EntityHelper = require("src.helpers.entity_helper")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local MachineStateManager = require("src.ui.machine_state_manager")
local observe = Beholder.observe
local execute = Evolved.execute
local builder = Evolved.builder
local get = Evolved.get

-- Interaction handler registry
local HANDLERS = {
   storage = require("src.evolved.behaviors.storage_interaction"),
   machine = require("src.evolved.behaviors.machine_interaction"),
   creature = require("src.evolved.behaviors.creature_interaction"),
}

-- Create a query for interactable entities (registered once)
local interactableQuery = builder()
   :name("QUERIES.Interactable")
   :include(TAGS.Interactable)
   :build()

local function tryMouseInteract(mouseX, mouseY)
   local playerId = ENTITIES.Player
   local playerInteractionRange = get(playerId, FRAGMENTS.InteractionRange)
   local interactionRangeSquared = playerInteractionRange ^ 2

   local closestEntityId = nil
   local closestDistanceSquared = math.huge

   -- Use Evolved.execute() to iterate over interactable entities on-demand
   for chunk, entityIds, entityCount in execute(interactableQuery) do
      for i = 1, entityCount do
         local entityId = entityIds[i]
         -- 1. Check if mouse is over entity
         local isMouseOverEntity = EntityHelper.pointIsInsideEntity(mouseX, mouseY, entityId)
         if isMouseOverEntity then
            -- 2. Check if entity is inside player interaction range
            local playerEntityDistanceSquared = EntityHelper.getDistanceSquared(playerId, entityId)
            if playerEntityDistanceSquared <= interactionRangeSquared
               and playerEntityDistanceSquared < closestDistanceSquared then
               closestEntityId = entityId
               closestDistanceSquared = playerEntityDistanceSquared
            end
         end
      end
   end

   -- 3. Dispatch to appropriate handler based on interaction type
   if closestEntityId then
      local interaction = get(closestEntityId, FRAGMENTS.Interaction)
      if interaction and HANDLERS[interaction.type] then
         HANDLERS[interaction.type](playerId, closestEntityId, interaction)
      end
   end
end

-- Register observer for input interaction events
observe(Events.INPUT_INTERACTED, function(mouseX, mouseY)
   -- Don't process mouse interactions when inventory or machine screen is open
   if not InventoryStateManager.isOpen and not MachineStateManager.isOpen then
      tryMouseInteract(mouseX, mouseY)
   end
end)
