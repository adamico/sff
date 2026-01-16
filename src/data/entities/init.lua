-- Merge all entity categories into one table
local entities = {}

local categories = {
   require("src.data.entities.corpse_entities_data"),
   require("src.data.entities.creature_entities_data"),
   require("src.data.entities.deployable_entities_data"),
   require("src.data.entities.player_entities_data"),
}

for _, category in ipairs(categories) do
   for id, data in pairs(category) do
      if entities[id] then
         error(string.format("Duplicate entity ID: '%s'", id))
      end
      entities[id] = data
      entities[id].id = id -- store ID on the entity itself
   end
end

return entities
