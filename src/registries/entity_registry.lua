local Entities = require("src.data.entities")

local EntityRegistry = {}

--- Get an entity by its ID
--- @param entity_id string The entity ID
--- @return table|nil The entity data, or nil if not found
function EntityRegistry.getEntity(entity_id)
   return Entities[entity_id]
end

--- Check if an entity exists in the registry
--- @param entity_id string The entity ID
--- @return boolean True if the entity exists
function EntityRegistry.exists(entity_id)
   return Entities[entity_id] ~= nil
end

--- Get all entities of a specific class
--- @param class_name string The class name (e.g., "Assembler", "Storage", "Creature")
--- @return table Array of entities with that class
function EntityRegistry.getEntitiesByClass(class_name)
   local result = {}
   for id, entity in pairs(Entities) do
      if entity.class == class_name then
         result[id] = entity
      end
   end
   return result
end

--- Get all registered entities
--- @return table All entities
function EntityRegistry.getAll()
   return Entities
end

return EntityRegistry
