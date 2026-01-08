local ItemRegistry = require("src.registries.item_registry")

local InventoryHelper = {}

--- Get the maximum stack size for an item
--- @param item_id string The item ID
--- @return number The max stack size
function InventoryHelper.getMaxStackQuantity(item_id)
   return ItemRegistry.getMaxStackSize(item_id)
end

return InventoryHelper
