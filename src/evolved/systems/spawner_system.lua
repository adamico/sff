--[[
   Spawner System

   Handles entity spawning requests triggered by events.
   Centralizes entity creation logic (prefab selection, component building).
]]

local EntityRegistry = require("src.registries.entity_registry")
local Inventory = require("src.evolved.fragments.inventory")
local StateMachine = require("src.evolved.fragments.state_machine")
local InputQueue = require("src.evolved.fragments.input_queue")

local observe = Beholder.observe
local trigger = Beholder.trigger
local clone = Evolved.clone

--- Get the appropriate prefab for an entity class
--- @param class string The entity class (e.g., "Assembler", "Storage", "Creature")
--- @return table|nil The prefab, or nil if not found
local function getPrefabForClass(class)
   if class == "Assembler" then
      return PREFABS.Assembler
   elseif class == "Storage" then
      return PREFABS.Storage
   elseif class == "Creature" then
      return PREFABS.Creature
   end
   return nil
end

--- Build components for an entity based on its data
--- @param entityData table The entity data from the registry
--- @param position table The position vector to spawn at
--- @return table The component map for cloning
local function buildComponents(entityData, position)
   local components = {
      [Evolved.NAME] = entityData.name or entityData.id,
      [FRAGMENTS.Position] = Vector(position.x, position.y),
      [FRAGMENTS.Color] = entityData.color or Colors.WHITE,
      [FRAGMENTS.Size] = entityData.size or Vector(32, 32),
      [FRAGMENTS.Shape] = entityData.shape or entityData.visual or "rectangle",
   }

   -- Add inventory if entity has one
   if entityData.inventory then
      components[FRAGMENTS.Inventory] = Inventory.new(entityData.inventory)
   end

   -- Add state machine for machines
   if entityData.events then
      components[FRAGMENTS.StateMachine] = StateMachine.new({events = entityData.events})
   end

   -- Add machine-specific components
   if entityData.class == "Assembler" then
      components[FRAGMENTS.Mana] = entityData.mana
      components[FRAGMENTS.ProcessingTimer] = {current = 0, saved = 0}
      components[FRAGMENTS.ValidRecipes] = entityData.valid_recipes
      components[FRAGMENTS.MachineClass] = "Assembler"
      components[FRAGMENTS.InputQueue] = InputQueue.new()
   end

   return components
end

--- Spawn an entity at a given position
--- @param entityId string The entity ID from the registry
--- @param position table The position vector to spawn at
--- @return number|nil The spawned entity ID, or nil on failure
local function spawnEntity(entityId, position)
   local entityData = EntityRegistry.getEntity(entityId)
   if not entityData then
      Log.warn("SpawnerSystem: No entity data found for: "..tostring(entityId))
      return nil
   end

   local prefab = getPrefabForClass(entityData.class)
   if not prefab then
      Log.warn("SpawnerSystem: No prefab found for entity class: "..tostring(entityData.class))
      return nil
   end

   local components = buildComponents(entityData, position)
   local spawnedId = clone(prefab, components)

   Log.debug("SpawnerSystem: Spawned entity '"..entityId.."' at ("..position.x..", "..position.y..")")

   return spawnedId
end

-- Listen for spawn requests
observe(Events.ENTITY_SPAWN_REQUESTED, function(request)
   local spawnedId = spawnEntity(request.entityId, request.position)

   if spawnedId then
      trigger(Events.ENTITY_DEPLOYED, spawnedId, request.position, request.sourceSlotIndex)
   end
end)

return {
   spawnEntity = spawnEntity,
   getPrefabForClass = getPrefabForClass,
   buildComponents = buildComponents,
}
