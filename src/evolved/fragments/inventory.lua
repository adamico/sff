local Inventory = {}

--- Initializes slots with initial items.
--- @param maxSlots number The maximum number of slots.
--- @param initialItems? table A table of {itemId, quantity} pairs.
--- @return table The initialized slots.
local function initializeSlots(maxSlots, initialItems)
   initialItems = initialItems or {}
   local slots = {}
   for i = 1, maxSlots do
      slots[i] = {}
   end

   local itemIndex = 1
   for _, item in ipairs(initialItems) do
      if itemIndex <= maxSlots then
         slots[itemIndex] = {
            itemId = item.itemId,
            quantity = item.quantity or 1
         }
         itemIndex = itemIndex + 1
      end
   end

   return slots
end

--- Initializes the inventory component.
--- @param data? table The configuration table.
--- @return table Inventory component instance.
---
--- Configuration options:
---   maxSlots: number - Maximum number of slots
---   initialItems: table - Array of {itemId, quantity} to place initially
---   acceptedCategories: table - Array of category strings this inventory accepts (optional)
---   accessMode: string - "io" (default), "output", or future modes
---
--- Access modes:
---   "io" - External entities can insert AND remove items (default)
---   "output" - External entities can only remove; machine produces here
---
--- Example:
---   Inventory.new({ maxSlots = 40 })
---   Inventory.new({ maxSlots = 2, accessMode = "io" })
---   Inventory.new({ maxSlots = 1, accessMode = "output" })
function Inventory.new(data)
   data = data or {}
   return {
      slots = initializeSlots(data.maxSlots or 0, data.initialItems or {}),
      maxSlots = data.maxSlots or 0,
      acceptedCategories = data.acceptedCategories,
      accessMode = data.accessMode or "io",
   }
end

--- Check if external entities can insert items into this inventory.
--- @param inventory table The inventory component instance.
--- @return boolean True if insertion is allowed.
function Inventory.canInsert(inventory)
   return inventory.accessMode == "io"
end

--- Check if external entities can remove items from this inventory.
--- @param inventory table The inventory component instance.
--- @return boolean True if removal is allowed.
function Inventory.canRemove(inventory)
   return inventory.accessMode == "io" or inventory.accessMode == "output"
end

--- Get slots array from an inventory.
--- @param inventory table The inventory component instance.
--- @return table|nil The slots array, or nil if not found.
function Inventory.getSlots(inventory)
   if not inventory then return nil end
   return inventory.slots
end

--- Get a single slot from an inventory.
--- @param inventory table The inventory component instance.
--- @param slotIndex number The slot index (1-based).
--- @return table|nil The slot, or nil if not found.
function Inventory.getSlot(inventory, slotIndex)
   local slots = Inventory.getSlots(inventory)
   if not slots then return nil end
   return slots[slotIndex]
end

--- Get the first free slot index in an inventory.
--- @param inventory table The inventory component instance.
--- @return number|nil The first free slot index, or nil if no free slots
function Inventory.getFreeSlot(inventory)
   local slots = Inventory.getSlots(inventory)
   if not slots then return nil end

   for slotIndex = 1, #slots do
      if not slots[slotIndex].itemId then
         return slotIndex
      end
   end
   return nil
end

--- Adds an item to the inventory with proper stacking support.
--- Respects max stack size limits and handles partial additions.
--- @param inventory table The inventory component instance.
--- @param itemId string The ID of the item to add.
--- @param count number The number of items to add.
--- @return number The number of items actually added (may be less than count if not enough space).
function Inventory.addItem(inventory, itemId, count)
   count = count or 1
   local ItemQuery = require("src.data.queries.item_query")
   local maxStack = ItemQuery.getMaxStackSize(itemId)

   local slots = Inventory.getSlots(inventory)
   if not slots then return 0 end

   local remaining = count

   -- First pass: try to stack onto existing stacks of the same item
   for _, slot in ipairs(slots) do
      if remaining <= 0 then break end

      if slot.itemId == itemId and (slot.quantity or 0) < maxStack then
         local canAdd = math.min(remaining, maxStack - (slot.quantity or 0))
         slot.quantity = (slot.quantity or 0) + canAdd
         remaining = remaining - canAdd
      end
   end

   -- Second pass: fill empty slots
   for i, slot in ipairs(slots) do
      if remaining <= 0 then break end

      if not slot.itemId then
         local toAdd = math.min(remaining, maxStack)
         slots[i] = {itemId = itemId, quantity = toAdd}
         remaining = remaining - toAdd
      end
   end

   return count - remaining -- Return how many were actually added
end

--- Stack items into a specific slot, respecting max stack limits.
--- Use this when you need to add items to a specific slot rather than finding the first available.
--- @param slot table The slot to stack into (must already contain the same itemId or be empty).
--- @param itemId string The item ID to add.
--- @param count number The quantity to add.
--- @return number The number of items actually added (may be less than count if stack limit reached).
function Inventory.stackIntoSlot(slot, itemId, count)
   if not slot then return 0 end

   local ItemQuery = require("src.data.queries.item_query")
   local maxStack = ItemQuery.getMaxStackSize(itemId)

   -- Empty slot - just place the item
   if not slot.itemId then
      local toAdd = math.min(count, maxStack)
      slot.itemId = itemId
      slot.quantity = toAdd
      return toAdd
   end

   -- Different item - can't stack
   if slot.itemId ~= itemId then
      return 0
   end

   -- Same item - stack up to max
   local currentQuantity = slot.quantity or 0
   if currentQuantity >= maxStack then
      return 0 -- Already at max
   end

   local canAdd = math.min(count, maxStack - currentQuantity)
   slot.quantity = currentQuantity + canAdd
   return canAdd
end

--- Deep clone an inventory instance.
--- @param inventory table|nil The inventory to duplicate.
--- @return table|nil A deep copy of the inventory, or nil if input is nil.
function Inventory.duplicate(inventory)
   if not inventory then return nil end

   local copy = {
      maxSlots = inventory.maxSlots,
      acceptedCategories = inventory.acceptedCategories,
      accessMode = inventory.accessMode,
      slots = {}
   }

   if inventory.slots then
      for i, slot in ipairs(inventory.slots) do
         copy.slots[i] = {
            itemId = slot.itemId,
            quantity = slot.quantity
         }
      end
   end

   return copy
end

return Inventory
