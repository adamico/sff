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

--- Initializes the inventory component.
--- @param data? table The configuration table.
--- @return table Inventory component instance.
function Inventory.new(data)
   data = data or {}
   local initialItems = data.initialItems or {}

   -- Determine capacity
   local maxInput = data.maxInputSlots or 0
   local maxOutput = data.maxOutputSlots or 0
   local maxGeneric = data.maxSlots or 0

   local inventory = {}

   -- If this is a machine (has typed slots)
   if maxInput > 0 or maxOutput > 0 then
      inventory.inputSlots = initializeSlots(maxInput, initialItems)
      inventory.outputSlots = initializeSlots(maxOutput, {})
      inventory.maxInputSlots = maxInput
      inventory.maxOutputSlots = maxOutput
   else
      -- Simple inventory (player, toolbar, storage)
      inventory.slots = initializeSlots(maxGeneric, initialItems)
      inventory.maxSlots = maxGeneric
   end

   return inventory
end

--- Adds an item to the inventory.
--- @param inventory table The inventory component instance.
--- @param itemId string The ID of the item to add.
--- @param count number The number of items to add.
--- @return boolean True if the item was added successfully, false otherwise.
function Inventory.addItem(inventory, itemId, count)
   count = count or 1

   -- Determine which slots array to use
   local slots = inventory.slots or inventory.inputSlots
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

--- Deep clone an inventory instance
--- @param inventory table The inventory to duplicate
--- @return table A deep copy of the inventory
function Inventory.duplicate(inventory)
   local copy = {}

   -- Copy max slot counts
   if inventory.maxSlots then
      copy.maxSlots = inventory.maxSlots
   end
   if inventory.maxInputSlots then
      copy.maxInputSlots = inventory.maxInputSlots
   end
   if inventory.maxOutputSlots then
      copy.maxOutputSlots = inventory.maxOutputSlots
   end

   -- Deep copy slots
   if inventory.slots then
      copy.slots = {}
      for i, slot in ipairs(inventory.slots) do
         copy.slots[i] = {
            itemId = slot.itemId,
            quantity = slot.quantity
         }
      end
   end

   -- Deep copy input slots
   if inventory.inputSlots then
      copy.inputSlots = {}
      for i, slot in ipairs(inventory.inputSlots) do
         copy.inputSlots[i] = {
            itemId = slot.itemId,
            quantity = slot.quantity
         }
      end
   end

   -- Deep copy output slots
   if inventory.outputSlots then
      copy.outputSlots = {}
      for i, slot in ipairs(inventory.outputSlots) do
         copy.outputSlots[i] = {
            itemId = slot.itemId,
            quantity = slot.quantity
         }
      end
   end

   return copy
end

return Inventory
