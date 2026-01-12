# Inventory System Documentation

## Overview

The inventory system supports two different slot patterns to accommodate different use cases:

1. **Simple Inventories** - Single `slots` array (for player inventory, toolbar, storage)
2. **Typed Inventories** - Separate `input_slots` and `output_slots` arrays (for machines)

## Inventory Structure

### Simple Inventories (Player, Toolbar, Storage)

```lua
{
   slots = {
      [1] = {item_id = "wood", quantity = 5},
      [2] = {item_id = "stone", quantity = 10},
      [3] = {},  -- empty slot
      -- ...
   },
   max_slots = 20
}
```

**Use case:** General-purpose inventories where all slots are equivalent.

**Created with:**
```lua
Inventory.new({
   max_slots = 20,
   initial_items = {
      {item_id = "wood", quantity = 5}
   }
})
```

### Typed Inventories (Machines)

```lua
{
   input_slots = {
      [1] = {item_id = "wood", quantity = 2},
      [2] = {item_id = "bone", quantity = 1}
   },
   output_slots = {
      [1] = {item_id = "stick", quantity = 4}
   },
   max_input_slots = 2,
   max_output_slots = 1
}
```

**Use case:** Machines that need to distinguish between input materials and output products.

**Created with:**
```lua
Inventory.new({
   max_input_slots = 2,
   max_output_slots = 1,
   initial_items = {
      {item_id = "wood", quantity = 2}
   }
})
```

## InventoryHelper API

The `InventoryHelper` module provides functions to abstract access to both inventory patterns.

### `getSlots(inventory, slotType)`

Get a slots array from an inventory, handling both patterns.

**Parameters:**
- `inventory` (table) - The inventory component
- `slotType` (string|nil) - The slot type:
  - `"input"` - Returns `inventory.input_slots` (machines)
  - `"output"` - Returns `inventory.output_slots` (machines)
  - `nil` - Returns `inventory.slots` (simple inventories)

**Returns:** `table|nil` - The slots array, or nil if not found

**Examples:**
```lua
-- Get simple inventory slots
local slots = InventoryHelper.getSlots(playerInventory, nil)

-- Get machine input slots
local inputSlots = InventoryHelper.getSlots(machineInventory, "input")

-- Get machine output slots
local outputSlots = InventoryHelper.getSlots(machineInventory, "output")
```

### `getSlot(inventory, slotIndex, slotType)`

Get a single slot from an inventory.

**Parameters:**
- `inventory` (table) - The inventory component
- `slotIndex` (number) - The slot index (1-based)
- `slotType` (string|nil) - The slot type (same as `getSlots`)

**Returns:** `table|nil` - The slot, or nil if not found

**Examples:**
```lua
-- Get slot 5 from simple inventory
local slot = InventoryHelper.getSlot(playerInventory, 5, nil)

-- Get input slot 1 from machine
local slot = InventoryHelper.getSlot(machineInventory, 1, "input")

-- Get output slot 2 from machine
local slot = InventoryHelper.getSlot(machineInventory, 2, "output")
```

### `getMaxStackQuantity(item_id)`

Get the maximum stack size for an item.

**Parameters:**
- `item_id` (string) - The item ID

**Returns:** `number` - The max stack size

## Creating Inventories

### Simple Inventory Example

```lua
local playerInventory = Inventory.new({
   max_slots = 20,
   initial_items = {
      {item_id = "torch", quantity = 3},
      {item_id = "wood", quantity = 10}
   }
})
```

### Machine Inventory Example

```lua
local assemblerInventory = Inventory.new({
   max_input_slots = 2,
   max_output_slots = 1,
   initial_items = {
      {item_id = "bone", quantity = 1}
   }
})
```

## How It Works

### Fragment Initialization (src/evolved/fragments/inventory.lua)

When `Inventory.new(data)` is called:

1. If `max_input_slots > 0` OR `max_output_slots > 0`:
   - Creates `inventory.input_slots` array
   - Creates `inventory.output_slots` array
   - Stores `max_input_slots` and `max_output_slots`
   - This is a **typed inventory** (machine)

2. Otherwise:
   - Creates `inventory.slots` array
   - Stores `max_slots`
   - This is a **simple inventory**

### UI Slot Access Pattern

All UI code should use `InventoryHelper` functions instead of directly accessing slots:

```lua
-- ❌ DON'T: Direct access doesn't work for both patterns
local slot = inventory.slots[index]

-- ✅ DO: Use helper for both patterns
local slot = InventoryHelper.getSlot(inventory, index, slotType)
```

### State Manager Pattern

Both `InventoryStateManager` and `MachineStateManager` track `slotType` when picking up items:

```lua
self.heldStack = {
   item_id = slot.item_id,
   quantity = slot.quantity,
   source_inventory = inventory,
   source_slot = slot_index,
   source_slot_type = slotType,  -- nil for simple, "input"/"output" for machines
}
```

This allows the held item to be returned to the correct slot array.

## Machine Screen Slot Layout

Machine screens define slot layouts with typed positions:

```lua
local layout = {
   {
      type = "input",
      positions = {
         {x = 10, y = 40},
         {x = 46, y = 40}
      }
   },
   {
      type = "output",
      positions = {
         {x = 150, y = 40}
      }
   }
}
```

The `FlexMachineScreen:createSlots()` function:
1. Iterates through layout groups
2. Calls `InventoryHelper.getSlots(inventory, layoutGroup.type)`
3. Creates FlexLove elements for each slot with `slotType` in userdata

## Benefits of This Design

1. **Simplicity for common cases** - Player/storage inventories don't need complex slot typing
2. **Flexibility for machines** - Clear separation between input and output
3. **Backward compatibility** - Existing simple inventories work as-is
4. **Type safety** - Helper functions prevent accessing wrong slot arrays
5. **Extensible** - Easy to add new slot types (e.g., "catalyst", "fuel") in the future

## Future Enhancements

Potential additions to typed inventories:

- `catalyst_slots` - Special slots for catalysts (not consumed)
- `fuel_slots` - Dedicated fuel/mana source slots
- `tool_slots` - Equipment/tool slots
- Slot filters - Restrict which items can go in which slots

All of these can be added by:
1. Adding new slot type parameters to `Inventory.new()`
2. Extending `InventoryHelper.getSlots()` to handle the new types
3. Updating machine screen layouts to include the new slot types