local ItemQuery = require("src.data.queries.item_query")
local Inventory = require("src.evolved.fragments.inventory")

local InventoryHelper = {}

--- Get the maximum stack size for an item
--- @param itemId string The item ID
--- @return number The max stack size
function InventoryHelper.getMaxStackQuantity(itemId)
   return ItemQuery.getMaxStackSize(itemId)
end

--- Get slots from an inventory.
--- Delegates to the Inventory fragment's getSlots function.
--- @param inventory table The inventory component
--- @return table|nil The slots array, or nil if not found
function InventoryHelper.getSlots(inventory)
   return Inventory.getSlots(inventory)
end

--- Get a single slot from an inventory.
--- Delegates to the Inventory fragment's getSlot function.
--- @param inventory table The inventory component
--- @param slotIndex number The slot index (1-based)
--- @return table|nil The slot, or nil if not found
function InventoryHelper.getSlot(inventory, slotIndex)
   return Inventory.getSlot(inventory, slotIndex)
end

--- Get the first free slot index in an inventory.
--- @param inventory table The inventory component
--- @return number|nil The first free slot index, or nil if no free slots
function InventoryHelper.getFreeSlot(inventory)
   return Inventory.getFreeSlot(inventory)
end

--- Get the maximum number of slots for an inventory.
--- @param inventory table The inventory component
--- @return number The max slots count, or 0 if not found
function InventoryHelper.getMaxSlots(inventory)
   return inventory and inventory.maxSlots or 0
end

--- Add an item to the inventory with proper stacking support.
--- Respects max stack size limits and handles partial additions.
--- @param inventory table The inventory component
--- @param itemId string The item ID to add
--- @param count number The quantity to add
--- @return number The number of items actually added (may be less than count if not enough space)
function InventoryHelper.addItem(inventory, itemId, count)
   return Inventory.addItem(inventory, itemId, count)
end

--- Stack items into a specific slot, respecting max stack limits.
--- Use this when you need to add items to a specific slot rather than finding first available.
--- @param slot table The slot to stack into
--- @param itemId string The item ID to add
--- @param count number The quantity to add
--- @return number The number of items actually added
function InventoryHelper.stackIntoSlot(slot, itemId, count)
   return Inventory.stackIntoSlot(slot, itemId, count)
end

--- Check if an item can be placed in an inventory based on category constraints.
--- @param inventory table The inventory component
--- @param itemId string The item ID to check
--- @return boolean True if the item can be placed, false if blocked by constraints
function InventoryHelper.canPlaceItem(inventory, itemId)
   if not inventory then return false end

   -- If no constraints defined, allow anything
   local acceptedCategories = inventory.acceptedCategories
   if not acceptedCategories then return true end

   -- Get the item's category
   local item = ItemQuery.getItem(itemId)
   if not item then return false end

   local itemCategory = item.category
   if not itemCategory then return false end

   -- Check if item's category is in the accepted list
   for _, acceptedCategory in ipairs(acceptedCategories) do
      if itemCategory == acceptedCategory then
         return true
      end
   end

   return false
end

--- Get the accepted categories for an inventory.
--- @param inventory table The inventory component
--- @return table|nil Array of accepted category strings, or nil if no constraints
function InventoryHelper.getAcceptedCategories(inventory)
   return inventory and inventory.acceptedCategories or nil
end

--- Check if external entities can insert items into this inventory.
--- @param inventory table The inventory component
--- @return boolean True if insertion is allowed
function InventoryHelper.canInsert(inventory)
   return Inventory.canInsert(inventory)
end

--- Check if external entities can remove items from this inventory.
--- @param inventory table The inventory component
--- @return boolean True if removal is allowed
function InventoryHelper.canRemove(inventory)
   return Inventory.canRemove(inventory)
end

return InventoryHelper
