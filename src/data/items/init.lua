-- Merge all item categories into one table
local items = {}

local categories = {
   require("src.data.items.equipment_items_data"),
   require("src.data.items.material_items_data"),
   require("src.data.items.creature_items_data"),
   require("src.data.items.deployable_items_data"),
}

for _, category in ipairs(categories) do
   for id, data in pairs(category) do
      if items[id] then
         error(string.format("Duplicate item ID: '%s'", id))
      end
      items[id] = data
      items[id].id = id -- store ID on the item itself
   end
end

return items
