local Inventory = {}

--- Initializes slots with initial items.
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
      if item_index <= max_slots then
         slots[item_index] = {
            item_id = item.item_id,
            quantity = item.quantity or 1
         }
         item_index = item_index + 1
      end
   end

   return slots
end

--- Initializes the inventory component.
--- @param data? table The configuration table.
--- @return table Inventory component instance.
function Inventory.new(data)
   data = data or {}
   local initial_items = data.initial_items or {}

   -- Determine capacity
   local max_input = data.max_input_slots or 0
   local max_output = data.max_output_slots or 0
   local max_generic = data.max_slots or 0

   local inventory = {}

   -- If this is a machine (has typed slots)
   if max_input > 0 or max_output > 0 then
      inventory.input_slots = initializeSlots(max_input, initial_items)
      inventory.output_slots = initializeSlots(max_output, {})
      inventory.max_input_slots = max_input
      inventory.max_output_slots = max_output
   else
      -- Simple inventory (player, toolbar, storage)
      inventory.slots = initializeSlots(max_generic, initial_items)
      inventory.max_slots = max_generic
   end

   return inventory
end

--- Adds an item to the inventory.
--- @param inventory table The inventory component instance.
--- @param item_id string The ID of the item to add.
--- @param count number The number of items to add.
--- @return boolean True if the item was added successfully, false otherwise.
function Inventory.addItem(inventory, item_id, count)
   count = count or 1

   -- Determine which slots array to use
   local slots = inventory.slots or inventory.input_slots
   if not slots then return false end

   for slotIndex, slot in ipairs(slots) do
      -- Find existing stack
      if slot.item_id == item_id then
         slot.quantity = (slot.quantity or 1) + count
         return true
         -- Find empty slot
      elseif not slot.item_id then
         slots[slotIndex] = {item_id = item_id, quantity = count}
         return true
      end
   end

   return false
end

return Inventory
