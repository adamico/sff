local Inventory = {}

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
   for _, item in ipairs(initial_items) do
      slots[item_index] = {
         item_id = item.item_id,
         quantity = item.quantity or 1
      }
      item_index = item_index + 1
   end

   return slots
end

--- Initializes the inventory component.
--- @param data? table The configuration table.
--- @return table Inventory component instance.
function Inventory.new(data)
   data = data or {}
   local initial_items = data.initial_items or {}

   local inventory = {
      input_slots = initializeSlots(data.max_input_slots or 0, initial_items),
      output_slots = initializeSlots(data.max_output_slots or 0)
   }

   return inventory
end

--- Adds an item to the inventory.
--- @param inventory table The inventory component instance.
--- @param item_id string The ID of the item to add.
--- @param count number The number of items to add.
--- @return boolean True if the item was added successfully, false otherwise.
function Inventory.addItem(inventory, item_id, count)
   count = count or 1

   for slotIndex, slot in ipairs(inventory.input_slots) do
      -- Find existing stack
      if slot.item_id == item_id then
         slot.quantity = (slot.quantity or 1) + count
         return true
         -- Find empty slot
      elseif not slot.item_id then
         inventory.input_slots[slotIndex] = {item_id = item_id, quantity = count}
         return true
      end
   end

   return false
end

return Inventory
