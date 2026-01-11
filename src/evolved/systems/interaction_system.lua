local EntityHelper = require("src.helpers.entity_helper")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local MachineStateManager = require("src.ui.machine_state_manager")
local trigger = Beholder.trigger
local observe = Beholder.observe
local execute = Evolved.execute
local builder = Evolved.builder
local get = Evolved.get

-- Create a query for interactable entities (registered once)
local interactableQuery = builder()
   :name("QUERIES.Interactable")
   :include(TAGS.Interactable)
   :build()

local function tryMouseInteract(mouseX, mouseY)
   local playerId = ENTITIES.Player
   local playerInventory = get(playerId, FRAGMENTS.Inventory)
   local playerToolbar = get(playerId, FRAGMENTS.Toolbar)
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

   -- 3. Emit appropriate event based on entity type
   if closestEntityId then
      local machineClass = get(closestEntityId, FRAGMENTS.MachineClass)

      if machineClass then
         -- This is a machine - use machine screen
         trigger(Events.MACHINE_INTERACTED, closestEntityId)
      else
         -- This is a storage or other entity - use inventory view
         local targetInventory = get(closestEntityId, FRAGMENTS.Inventory)
         trigger(Events.ENTITY_INTERACTED, playerInventory, targetInventory, playerToolbar, closestEntityId)
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
