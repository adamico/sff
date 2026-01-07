local InventoryComponent = Class("InventoryComponent")

--- @class InventoryComponent
--- @field input_slots table
--- @field output_slots table

--- Initializes input slots with initial items.
--- @param max_slots number The maximum number of slots.
--- @param initial_items? table A table of itemId => count.
--- @return table The initialized slots.
local function initializeSlots(max_slots, initial_items)
   initial_items = initial_items or {}
   local slots = {}
   for i = 1, max_slots do
      slots[i] = {}
   end

   local item_index = 1
   for item_id, quantity in pairs(initial_items) do
      slots[item_index] = {
         item_id = item_id,
         quantity = quantity
      }
      item_index = item_index + 1
   end

   return slots
end

--- Initializes the inventory component.
--- @param data? table The configuration table.
function InventoryComponent:initialize(data)
   data = data or {}
   local initial_items = data.initial_items or {}

   self.input_slots = initializeSlots(data.max_input_slots, initial_items)
   self.output_slots = initializeSlots(data.max_output_slots)
end

--- Adds an item to the inventory.
--- @param item_id string The ID of the item to add.
--- @param count number The number of items to add.
--- @return boolean True if the item was added successfully, false otherwise.
function InventoryComponent:addItem(item_id, count)
   count = count or 1

   for slotIndex, slot in ipairs(self.input_slots) do
      -- Find existing stack
      if slot.item_id == item_id then
         slot.count = slot.count + 1

         return true
         -- Find empty slot
      elseif not slot.item_id then
         slot = {item_id = item_id, count = count}

         return true
      end
   end

   return false
end

function InventoryComponent:removeItem(slots, item_id, count)
   count = count or 1

   for slotIndex, slot in ipairs(slots) do
      if slot.item_id == item_id then
         slot.count = slot.count - 1
         if slot.count <= 0 then
            slot = {}
         end
         return true
      end
   end

   return false
end

return InventoryComponent
