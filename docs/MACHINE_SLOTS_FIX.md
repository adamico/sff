# Machine Slots Fix - Summary

## Issue

Machine input and output slots were not being drawn in the UI.

## Root Cause

The inventory system had been simplified to use a single `slots` array for all inventories. This worked fine for player inventory, toolbar, and storage, but broke machines that need to distinguish between:
- **Input slots** - Where materials are placed
- **Output slots** - Where products appear

When `FlexMachineScreen:createSlots()` called `InventoryHelper.getSlots(inventory, "input")`, this function didn't exist, causing the slots to not be created.

## Solution

Implemented a **dual inventory system** that supports both patterns:

### 1. Simple Inventories (Player, Toolbar, Storage)

**Structure:**
```lua
{
   slots = {...},
   max_slots = 20
}
```

**Use case:** General-purpose inventories where all slots are equivalent.

### 2. Typed Inventories (Machines)

**Structure:**
```lua
{
   input_slots = {...},
   output_slots = {...},
   max_input_slots = 2,
   max_output_slots = 1
}
```

**Use case:** Machines that need separate input materials and output products.

## Files Changed

### 1. `src/evolved/fragments/inventory.lua`

Modified `Inventory.new()` to detect which pattern to use:

```lua
-- If max_input_slots or max_output_slots specified → typed inventory
if max_input > 0 or max_output > 0 then
   inventory.input_slots = initializeSlots(max_input, initial_items)
   inventory.output_slots = initializeSlots(max_output, {})
   inventory.max_input_slots = max_input
   inventory.max_output_slots = max_output
else
   -- Simple inventory
   inventory.slots = initializeSlots(max_generic, initial_items)
   inventory.max_slots = max_generic
end
```

### 2. `src/helpers/inventory_helper.lua`

Added two helper functions to abstract slot access:

#### `getSlots(inventory, slotType)`

Returns the appropriate slots array based on type:
- `slotType = "input"` → returns `inventory.input_slots`
- `slotType = "output"` → returns `inventory.output_slots`
- `slotType = nil` → returns `inventory.slots`

#### `getSlot(inventory, slotIndex, slotType)`

Returns a single slot from the appropriate array.

**Example usage:**
```lua
-- Get machine input slots
local inputSlots = InventoryHelper.getSlots(inventory, "input")

-- Get a specific input slot
local slot = InventoryHelper.getSlot(inventory, 1, "input")

-- Get simple inventory slots
local slots = InventoryHelper.getSlots(inventory, nil)
```

### 3. `docs/INVENTORY_SYSTEM.md` (New)

Comprehensive documentation covering:
- Inventory structure for both patterns
- InventoryHelper API reference
- Creation examples
- How the system works internally
- Machine screen slot layout
- Benefits and future extensibility

### 4. `docs/FLEXLOVE_QUICK_REFERENCE.md`

Updated to reflect current architecture:
- Added held stack rendering pattern
- Added inventory system patterns
- Documented why held items use immediate-mode rendering
- Added slot element userdata examples

## How It Works

### Entity Creation

When a machine entity is created (e.g., from `deployable_entities_data.lua`):

```lua
inventory = {
   max_input_slots = 2,
   max_output_slots = 1,
   initial_items = {
      {item_id = "bone", quantity = 1}
   }
}
```

The `Inventory.new()` function detects the typed slot configuration and creates:
- `inventory.input_slots` - Array of 2 slots
- `inventory.output_slots` - Array of 1 slot

### Machine Screen Rendering

`FlexMachineScreen:createSlots()` flow:

1. Gets the slot layout (positions and types)
2. For each layout group (input, output):
   - Calls `InventoryHelper.getSlots(inventory, slotType)`
   - Creates FlexLove elements for each slot position
   - Stores `slotType` in element userdata

```lua
for _, layoutGroup in ipairs(slotLayout) do
   local slotType = layoutGroup.type  -- "input" or "output"
   local positions = layoutGroup.positions
   local slots = InventoryHelper.getSlots(inventory, slotType)
   
   if slots and positions then
      for slotIndex = 1, #positions do
         -- Create slot element with slotType in userdata
      end
   end
end
```

### Slot Updates

`FlexMachineScreen:updateSlots()` uses the helper:

```lua
for _, slotData in ipairs(self.slotElements) do
   local slot = InventoryHelper.getSlot(inventory, slotData.slotIndex, slotData.slotType)
   -- Update element with slot data
end
```

### State Management

Both `InventoryStateManager` and `MachineStateManager` track `slotType` when handling items:

```lua
self.heldStack = {
   item_id = slot.item_id,
   quantity = slot.quantity,
   source_inventory = inventory,
   source_slot = slot_index,
   source_slot_type = slotType,  -- nil for simple, "input"/"output" for machines
}
```

This ensures items are returned to the correct slot array.

## Benefits

1. **Simplicity** - Player/storage inventories don't need complex slot typing
2. **Flexibility** - Machines clearly distinguish input from output
3. **Backward Compatibility** - Existing simple inventories work unchanged
4. **Type Safety** - Helper functions prevent accessing wrong slot arrays
5. **Extensibility** - Easy to add new slot types (catalyst, fuel, etc.)
6. **Consistency** - All UI code uses the same helpers for slot access

## Verification

Tested that the system creates:
- ✅ Simple inventories with single `slots` arrays (player: 40, toolbar: 10, storage: 32)
- ✅ Typed inventories with separate slot arrays (assembler: 2 input, 1 output)
- ✅ No runtime errors or diagnostics issues

## Future Enhancements

The typed inventory system can easily be extended with:

- `catalyst_slots` - Special slots for catalysts (not consumed in recipes)
- `fuel_slots` - Dedicated fuel/mana source slots
- `tool_slots` - Equipment/tool slots that affect recipe behavior
- Slot filters - Restrict which items can go in which slot types
- Per-slot metadata - Mark individual slots with properties

All can be added by:
1. Adding new slot type parameters to `Inventory.new()`
2. Extending `InventoryHelper.getSlots()` to handle new types
3. Updating machine screen layouts to include new slot types

## Related Documentation

- `docs/INVENTORY_SYSTEM.md` - Complete dual inventory system guide
- `docs/FLEXLOVE_QUICK_REFERENCE.md` - FlexLove patterns and best practices
- `src/ui/flex_machine_screen.lua` - Machine screen implementation
- `src/helpers/inventory_helper.lua` - Inventory helper API
- `src/evolved/fragments/inventory.lua` - Inventory fragment implementation