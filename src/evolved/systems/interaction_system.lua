local EntityHelper = require("src.helpers.entity_helper")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local observe = Beholder.observe
local execute = Evolved.execute

-- Create a query for interactable entities (registered once)
local interactableQuery = Evolved.builder()
   :name("QUERIES.Interactable")
   :include(TAGS.Interactable)
   :build()

local function tryMouseInteract(mouseX, mouseY)
   local playerId = ENTITIES.Player
   local playerInventory = Evolved.get(playerId, FRAGMENTS.Inventory)
   local playerToolbar = Evolved.get(playerId, FRAGMENTS.Toolbar)
   local playerInteractionRange = Evolved.get(playerId, FRAGMENTS.InteractionRange)
   local interactionRangeSquared = playerInteractionRange ^ 2

   local closestEntityId = nil
   local closestDistanceSquared = math.huge

   -- Use Evolved.execute() to iterate over interactable entities on-demand
   for chunk, entityIds, entityCount in execute(interactableQuery) do
      for entityIndex = 1, entityCount do
         local entityId = entityIds[entityIndex]

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

   -- 3. Emit interaction event if we found an interactable entity in range
   if closestEntityId then
      local targetInventory = Evolved.get(closestEntityId, FRAGMENTS.Inventory)
      trigger(Events.ENTITY_INTERACTED, playerInventory, targetInventory, playerToolbar)
   end
end

-- Register observer for input interaction events
observe(Events.INPUT_INTERACTED, function(mouseX, mouseY)
   -- Don't process mouse interactions when inventory is open
   if not InventoryStateManager.isOpen then
      tryMouseInteract(mouseX, mouseY)
   end
end)
