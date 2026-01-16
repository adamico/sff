--[[
   Spawner System

   Handles entity spawning requests triggered by events.
   Fully data-driven: iterates over FRAGMENTS and checks for matching entity data fields.

   Convention:
   - Entity data field names are lowercase versions of FRAGMENTS names
   - e.g., FRAGMENTS.Color → entityData.color
   - e.g., FRAGMENTS.MaxSpeed → entityData.maxSpeed
]]

local EntityRegistry = require("src.data.queries.entity_query")

local observe = Beholder.observe
local trigger = Beholder.trigger

--- Convert fragment name to entity data field name
--- e.g., "FRAGMENTS.MaxSpeed" → "maxSpeed", "FRAGMENTS.Color" → "color"
--- @param fragmentName string The fragment name (e.g., "MaxSpeed")
--- @return string The entity data field name (e.g., "maxSpeed")
local function fragmentNameToFieldName(fragmentName)
   -- Convert first character to lowercase
   return fragmentName:sub(1, 1):lower()..fragmentName:sub(2)
end

--- Build components for an entity based on its data
--- Iterates over FRAGMENTS and checks for matching entity data fields
--- @param entityData table The entity data from the registry
--- @param position table The position vector to spawn at
--- @param overrides table|nil Optional overrides for component values
--- @return table The component map
local function buildComponents(entityData, position, overrides)
   overrides = overrides or {}

   local components = {
      [Evolved.NAME] = overrides.name or entityData.name or entityData.id,
      [FRAGMENTS.Position] = Vector(position.x, position.y),
   }

   -- Iterate over all defined fragments
   for fragmentName, fragment in pairs(FRAGMENTS) do
      local fieldName = fragmentNameToFieldName(fragmentName)
      -- Check overrides first, then entity data
      local value = overrides[fieldName]
      if value == nil then
         value = entityData[fieldName]
      end

      if value ~= nil then
         components[fragment] = value
      end
   end

   return components
end

--- Determine which tags to apply based on entity data
--- Reads from entityData.tags array (e.g., {"physical", "visual", "player"})
--- @param entityData table The entity data from the registry
--- @return table Array of tags to apply
local function getTags(entityData)
   local tags = {}

   if entityData.tags then
      for _, tagName in ipairs(entityData.tags) do
         -- Convert tag name to TAGS reference (capitalize first letter)
         local capitalizedName = tagName:sub(1, 1):upper()..tagName:sub(2)
         local tag = TAGS[capitalizedName]
         if tag then
            table.insert(tags, tag)
         else
            Log.warn("SpawnerSystem: Unknown tag '"..tagName.."'")
         end
      end
   end

   return tags
end

--- Spawn an entity at a given position
--- @param entityId string The entity ID from the registry
--- @param position table The position vector to spawn at
--- @param overrides table|nil Optional overrides for component values
--- @return number|nil The spawned entity ID, or nil on failure
local function spawnEntity(entityId, position, overrides)
   local entityData = EntityRegistry.getEntity(entityId)
   if not entityData then
      Log.warn("SpawnerSystem: No entity data found for: "..tostring(entityId))
      return nil
   end

   -- Build components from entity data (with optional overrides)
   local components = buildComponents(entityData, position, overrides)

   -- Get tags to apply
   local tags = getTags(entityData)

   -- Use the builder pattern to create the entity
   local entityBuilder = Evolved.builder()

   -- Add all components
   for fragment, value in pairs(components) do
      entityBuilder:set(fragment, value)
   end

   -- Add all tags
   for _, tag in ipairs(tags) do
      entityBuilder:set(tag)
   end

   -- Spawn the entity
   local spawnedId = entityBuilder:spawn()

   Log.debug("SpawnerSystem: Spawned entity '"..entityId.."' at ("..position.x..", "..position.y..")")

   return spawnedId
end

-- Listen for spawn requests
observe(Events.ENTITY_SPAWN_REQUESTED, function(request)
   local spawnedId = spawnEntity(request.entityId, request.position, request.overrides)

   if spawnedId then
      trigger(Events.ENTITY_SPAWNED, spawnedId, request.position, request.sourceSlotIndex)
   end
end)

return {
   spawnEntity = spawnEntity,
   buildComponents = buildComponents,
   getTags = getTags,
}
