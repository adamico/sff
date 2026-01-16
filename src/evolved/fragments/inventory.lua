local Inventory = {}

--- Initializes slots with initial items.
--- @param maxSlots number The maximum number of slots.
--- @param initialItems? table A table of itemId => count.
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

--- Initializes the inventory component using the unified slotGroups structure.
--- @param data? table The configuration table.
--- @return table Inventory component instance.
---
--- Configuration options:
---   slotGroups: table - Dictionary of slot group configurations
---     Each group: { maxSlots = number, initialItems = table }
---
--- Legacy options (for backward compatibility):
---   maxSlots: number - Creates a "default" slot group
---   maxInputSlots: number - Creates an "input" slot group
---   maxOutputSlots: number - Creates an "output" slot group
---   initialItems: table - Items to place in the primary slot group
---
--- Example configurations:
---   Simple inventory:
---     { slotGroups = { default = { maxSlots = 40 } } }
---   OR legacy: { maxSlots = 40 }
---
---   Machine inventory:
---     { slotGroups = { input = { maxSlots = 2 }, output = { maxSlots = 1 } } }
---   OR legacy: { maxInputSlots = 2, maxOutputSlots = 1 }
---
---   Equipment inventory:
---     { slotGroups = { weapon = { maxSlots = 1 }, armor = { maxSlots = 1 } } }
function Inventory.new(data)
   data = data or {}
   local inventory = {
      slotGroups = {}
   }

   -- New unified configuration
   if data.slotGroups then
      for groupType, groupConfig in pairs(data.slotGroups) do
         local maxSlots = groupConfig.maxSlots or 0
         local initialItems = groupConfig.initialItems or {}
         inventory.slotGroups[groupType] = {
            slots = initializeSlots(maxSlots, initialItems),
            maxSlots = maxSlots,
            acceptedCategories = groupConfig.acceptedCategories, -- Optional constraint
         }
      end
      return inventory
   end

   -- Legacy support: machine inventory (input/output slots)
   local maxInput = data.maxInputSlots or 0
   local maxOutput = data.maxOutputSlots or 0
   local initialItems = data.initialItems or {}

   if maxInput > 0 or maxOutput > 0 then
      inventory.slotGroups.input = {
         slots = initializeSlots(maxInput, initialItems),
         maxSlots = maxInput
      }
      inventory.slotGroups.output = {
         slots = initializeSlots(maxOutput, {}),
         maxSlots = maxOutput
      }
      return inventory
   end

   -- Legacy support: simple inventory (default slots)
   local maxGeneric = data.maxSlots or 0
   inventory.slotGroups.default = {
      slots = initializeSlots(maxGeneric, initialItems),
      maxSlots = maxGeneric
   }

   return inventory
end

--- Get a slot group by type.
--- @param inventory table The inventory component instance.
--- @param slotType string|nil The slot type (nil defaults to "default").
--- @return table|nil The slot group, or nil if not found.
function Inventory.getSlotGroup(inventory, slotType)
   if not inventory or not inventory.slotGroups then return nil end

   slotType = slotType or "default"
   return inventory.slotGroups[slotType]
end

--- Get slots array from an inventory by slot type.
--- @param inventory table The inventory component instance.
--- @param slotType string|nil The slot type (nil defaults to "default").
--- @return table|nil The slots array, or nil if not found.
function Inventory.getSlots(inventory, slotType)
   local group = Inventory.getSlotGroup(inventory, slotType)
   return group and group.slots or nil
end

--- Get a single slot from an inventory.
--- @param inventory table The inventory component instance.
--- @param slotIndex number The slot index (1-based).
--- @param slotType string|nil The slot type (nil defaults to "default").
--- @return table|nil The slot, or nil if not found.
function Inventory.getSlot(inventory, slotIndex, slotType)
   local slots = Inventory.getSlots(inventory, slotType)
   if not slots then return nil end
   return slots[slotIndex]
end

--- Get all slot group types in an inventory.
--- @param inventory table The inventory component instance.
--- @return table Array of slot type strings.
function Inventory.getSlotTypes(inventory)
   if not inventory or not inventory.slotGroups then return {} end
   local types = {}
   for groupType, _ in pairs(inventory.slotGroups) do
      table.insert(types, groupType)
   end
   return types
end

--- Adds an item to the inventory.
--- @param inventory table The inventory component instance.
--- @param itemId string The ID of the item to add.
--- @param count number The number of items to add.
--- @param slotType string|nil The slot type to add to (nil defaults to "default", or "input" for machines).
--- @return boolean True if the item was added successfully, false otherwise.
function Inventory.addItem(inventory, itemId, count, slotType)
   count = count or 1

   -- Determine which slot group to use
   if not slotType then
      -- Default to "default" group, or "input" if it exists (for machines)
      if inventory.slotGroups.input then
         slotType = "input"
      else
         slotType = "default"
      end
   end

   local slots = Inventory.getSlots(inventory, slotType)
   if not slots then return false end

   for slotIndex, slot in ipairs(slots) do
      -- Find existing stack
      if slot.itemId == itemId then
         slot.quantity = (slot.quantity or 1) + count
         return true
         -- Find empty slot
      elseif not slot.itemId then
         slots[slotIndex] = {itemId = itemId, quantity = count}
         return true
      end
   end

   return false
end

--- Deep clone an inventory instance.
--- @param inventory table The inventory to duplicate.
--- @return table A deep copy of the inventory.
function Inventory.duplicate(inventory)
   local copy = {
      slotGroups = {}
   }

   if not inventory.slotGroups then
      return copy
   end

   for groupType, group in pairs(inventory.slotGroups) do
      copy.slotGroups[groupType] = {
         maxSlots = group.maxSlots,
         acceptedCategories = group.acceptedCategories,
         slots = {}
      }

      if group.slots then
         for i, slot in ipairs(group.slots) do
            copy.slotGroups[groupType].slots[i] = {
               itemId = slot.itemId,
               quantity = slot.quantity
            }
         end
      end
   end

   return copy
end

return Inventory
