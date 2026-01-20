local ItemQuery = require("src.data.queries.item_query")
local Inventory = require("src.evolved.fragments.inventory")

local InventoryHelper = {}

--- Get the maximum stack size for an item
--- @param itemId string The item ID
--- @return number The max stack size
function InventoryHelper.getMaxStackQuantity(itemId)
   return ItemQuery.getMaxStackSize(itemId)
end

--- Get slots from an inventory by slot type.
--- Delegates to the Inventory fragment's getSlots function.
--- @param inventory table The inventory component
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @return table|nil The slots array, or nil if not found
function InventoryHelper.getSlots(inventory, slotType)
   return Inventory.getSlots(inventory, slotType)
end

function InventoryHelper.getSlotGroup(inventory, slotType)
   return Inventory.getSlotGroup(inventory, slotType)
end

--- Get a single slot from an inventory.
--- Delegates to the Inventory fragment's getSlot function.
--- @param inventory table The inventory component
--- @param slotIndex number The slot index (1-based)
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @return table|nil The slot, or nil if not found
function InventoryHelper.getSlot(inventory, slotIndex, slotType)
   return Inventory.getSlot(inventory, slotIndex, slotType)
end

--- Get the first free slot index in an inventory.
--- @param inventory table The inventory component
--- @return number|nil The first free slot index, or nil if no free slots
function InventoryHelper.getFreeSlot(inventory)
   return Inventory.getFreeSlot(inventory)
end

--- Get a slot group by type.
--- Delegates to the Inventory fragment's getSlotGroup function.
--- @param inventory table The inventory component
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @return table|nil The slot group containing slots and maxSlots, or nil if not found
function InventoryHelper.getSlotGroup(inventory, slotType)
   return Inventory.getSlotGroup(inventory, slotType)
end

--- Get all slot group types in an inventory.
--- Delegates to the Inventory fragment's getSlotTypes function.
--- @param inventory table The inventory component
--- @return table Array of slot type strings
function InventoryHelper.getSlotTypes(inventory)
   return Inventory.getSlotTypes(inventory)
end

--- Get the maximum number of slots for a slot type.
--- @param inventory table The inventory component
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @return number The max slots count, or 0 if not found
function InventoryHelper.getMaxSlots(inventory, slotType)
   local group = Inventory.getSlotGroup(inventory, slotType)
   return group and group.maxSlots or 0
end

--- Add an item to the inventory with proper stacking support.
--- Respects max stack size limits and handles partial additions.
--- @param inventory table The inventory component
--- @param itemId string The item ID to add
--- @param count number The quantity to add
--- @param slotType string|nil The slot type to add to (nil defaults to "default" or "input")
--- @return number The number of items actually added (may be less than count if not enough space)
function InventoryHelper.addItem(inventory, itemId, count, slotType)
   return Inventory.addItem(inventory, itemId, count, slotType)
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

--- Check if an item can be placed in a slot group based on category constraints.
--- @param inventory table The inventory component
--- @param itemId string The item ID to check
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @return boolean True if the item can be placed, false if blocked by constraints
function InventoryHelper.canPlaceItem(inventory, itemId, slotType)
   local group = Inventory.getSlotGroup(inventory, slotType)
   if not group then return false end

   -- If no constraints defined, allow anything
   local acceptedCategories = group.acceptedCategories
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

--- Get the accepted categories for a slot group.
--- @param inventory table The inventory component
--- @param slotType string|nil The slot type (nil defaults to "default")
--- @return table|nil Array of accepted category strings, or nil if no constraints
function InventoryHelper.getAcceptedCategories(inventory, slotType)
   local group = Inventory.getSlotGroup(inventory, slotType)
   return group and group.acceptedCategories or nil
end

return InventoryHelper
