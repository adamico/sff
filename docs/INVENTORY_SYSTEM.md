# Inventory System

> **Last Updated:** 2026-01-13

The inventory system supports two slot patterns:

1. **Simple Inventories** - Single `slots` array (player, toolbar, storage)
2. **Typed Inventories** - Separate `input_slots` and `output_slots` (machines)

---

## Structure

### Simple Inventory

```lua
{
   slots = {
      [1] = {itemId = "wood", quantity = 5},
      [2] = {},  -- empty
   },
   maxSlots = 20
}
```

### Typed Inventory (Machines)

```lua
{
   input_slots = {
      [1] = {itemId = "bone", quantity = 2},
   },
   output_slots = {
      [1] = {itemId = "skeleton", quantity = 1},
   },
   max_input_slots = 2,
   maxOutputSlots = 1
}
```

---

## InventoryHelper API

### `getSlots(inventory, slotType)`

Returns slot array based on type:

- `nil` → `inventory.slots`
- `"input"` → `inventory.input_slots`
- `"output"` → `inventory.output_slots`

### `getSlot(inventory, slotIndex, slotType)`

Returns single slot from appropriate array.

### `getMaxStackQuantity(itemId)`

Returns max stack size for an item.

---

## Creating Inventories

```lua
-- Simple
Inventory.new({ maxSlots = 20 })

-- Typed (Machine)
Inventory.new({
   max_input_slots = 2,
   maxOutputSlots = 1,
})
```

The `Inventory.new()` function automatically detects which pattern based on parameters.

---

## Machine Screen Layout

```lua
local layout = {
   { type = "input", positions = {{x = 10, y = 40}, {x = 46, y = 40}} },
   { type = "output", positions = {{x = 150, y = 40}} },
}
```

---

## Usage Pattern

```lua
-- Always use helpers, not direct access
local slot = InventoryHelper.getSlot(inventory, index, slotType)
local slots = InventoryHelper.getSlots(inventory, slotType)
```

---

## Future Extensions

- `catalyst_slots` - Not consumed in recipes
- `fuel_slots` - Dedicated fuel source
- Per-slot filters
