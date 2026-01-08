local Items = require("src.data.items")

local ItemRegistry = {}

local DEFAULT_MAX_STACK = 64

--- Get an item by its ID
--- @param item_id string The item ID
--- @return table|nil The item data, or nil if not found
function ItemRegistry.getItem(item_id)
   return Items[item_id]
end

--- Get the max stack size for an item
--- @param item_id string The item ID
--- @return number The max stack size (defaults to 64 if not specified)
function ItemRegistry.getMaxStackSize(item_id)
   local item = Items[item_id]
   if item then
      return item.max_stack_size or DEFAULT_MAX_STACK
   end
   return DEFAULT_MAX_STACK
end

--- Check if an item exists in the registry
--- @param item_id string The item ID
--- @return boolean True if the item exists
function ItemRegistry.exists(item_id)
   return Items[item_id] ~= nil
end

--- Get all registered items
--- @return table All items
function ItemRegistry.getAll()
   return Items
end

return ItemRegistry
