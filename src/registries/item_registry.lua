local Items = require("src.data.items")

local ItemRegistry = {}

local DEFAULT_MAX_STACK = 64

--- Get an item by its ID
--- @param itemId string The item ID
--- @return table|nil The item data, or nil if not found
function ItemRegistry.getItem(itemId)
   return Items[itemId]
end

--- Get the max stack size for an item
--- @param itemId string The item ID
--- @return number The max stack size (defaults to 64 if not specified)
function ItemRegistry.getMaxStackSize(itemId)
   local item = Items[itemId]
   if item then
      return item.maxStackSize or DEFAULT_MAX_STACK
   end
   return DEFAULT_MAX_STACK
end

--- Check if an item exists in the registry
--- @param itemId string The item ID
--- @return boolean True if the item exists
function ItemRegistry.exists(itemId)
   return Items[itemId] ~= nil
end

--- Get all registered items
--- @return table All items
function ItemRegistry.getAll()
   return Items
end

return ItemRegistry
