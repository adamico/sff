local EntityHelper = require("src.helpers.entity_helper")
local InventoryStateManager = require("src.managers.inventory_state_manager")
local MachineStateManager = require("src.managers.machine_state_manager")
local Behaviors = require("src.evolved.behaviors")
local CombatSystem = require("src.evolved.systems.combat_system")

local observe = Beholder.observe
local execute = Evolved.execute
local builder = Evolved.builder
local get = Evolved.get

-- Create a query for interactable entities (registered once)
local interactableQuery = builder()
   :name("QUERIES.Interactable")
   :include(TAGS.Interactable)
   :build()

local function tryWeaponActivate(mouseX, mouseY)
   local playerId = ENTITIES.Player
   if not playerId then return end

   -- Get equipped weapon and its combat behavior
   local weapon = EntityHelper.getEquippedWeapon(playerId)
   if not weapon then
      Log.debug("No weapon equipped")
      return
   end

   local combatBehavior = weapon.combatBehavior
   local damagedStat = weapon.damagedStat or "Health"
   local attackRange = weapon.attackRange or 16

   if not combatBehavior then
      Log.warn("Equipped weapon has no combat behavior defined")
      return
   end

   local targetId = CombatSystem.findClosestDamageableEntity(playerId, attackRange)
   if targetId then
      CombatSystem.executeAttack(playerId, targetId, damagedStat, combatBehavior)
   end
end

local function tryMouseInteract(mouseX, mouseY)
   local playerId = ENTITIES.Player
   if not playerId then return end

   local playerInteractionRange = get(playerId, FRAGMENTS.InteractionRange)
   local interactionRangeSquared = playerInteractionRange ^ 2

   local closestEntityId = nil
   local closestDistanceSquared = math.huge

   -- Use Evolved.execute() to iterate over interactable entities on-demand
   for _chunk, entityIds, entityCount in execute(interactableQuery) do
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
      if interaction then
         local handler = Behaviors.interactions.get(interaction.type)
         if handler then
            handler(playerId, closestEntityId, interaction)
         end
      end
   end
end

-- Register observer for input interaction events
observe(Events.INPUT_INTERACTION_CLICKED, function(mouseX, mouseY)
   -- Don't process mouse interactions when inventory or machine screen is open
   if not InventoryStateManager.isOpen and not MachineStateManager.isOpen then
      tryMouseInteract(mouseX, mouseY)
   end
end)

-- Register observer for weapon activation events
observe(Events.WEAPON_ACTIVATED, function(mouseX, mouseY)
   -- Don't process weapon activations when inventory or machine screen is open
   if not InventoryStateManager.isOpen and not MachineStateManager.isOpen then
      tryWeaponActivate(mouseX, mouseY)
   end
end)
