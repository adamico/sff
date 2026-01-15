local ItemRegistry = require("src.data.queries.item_query")

local InventoryHelper = {}

--- Get the maximum stack size for an item
--- @param itemId string The item ID
--- @return number The max stack size
function InventoryHelper.getMaxStackQuantity(itemId)
   return ItemRegistry.getMaxStackSize(itemId)
end

--- Get slots from an inventory, handling both typed (input/output) and simple (slots) inventories
--- @param inventory table The inventory component
--- @param slotType string|nil The slot type ("input" or "output" for machines, nil for simple inventories)
--- @return table|nil The slots array, or nil if not found
function InventoryHelper.getSlots(inventory, slotType)
   if not inventory then return nil end

   -- If no slotType specified, return simple slots array
   if not slotType then
      return inventory.slots
   end

   -- Handle typed slots for machines
   if slotType == "input" then
      return inventory.inputSlots
   elseif slotType == "output" then
      return inventory.outputSlots
   end

   return nil
end

--- Get a single slot from an inventory
--- @param inventory table The inventory component
--- @param slotIndex number The slot index (1-based)
--- @param slotType string|nil The slot type ("input" or "output" for machines, nil for simple inventories)
--- @return table|nil The slot, or nil if not found
function InventoryHelper.getSlot(inventory, slotIndex, slotType)
   local slots = InventoryHelper.getSlots(inventory, slotType)
   if not slots then return nil end
   return slots[slotIndex]
end

return InventoryHelper
