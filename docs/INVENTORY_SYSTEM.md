# Inventory System

> **Last Updated:** 2026-01-16

The inventory system uses a unified **slot groups** architecture that supports any type of inventory through a consistent structure.

---

## Overview

All inventories use the same underlying structure:

```lua
{
   slotGroups = {
      [slotType] = {
         slots = { ... },
         maxSlots = number
      }
   }
}
```

This unified approach supports:
- **Simple Inventories** - Player inventory, toolbar, storage (`default` slot group)
- **Machine Inventories** - Input/output separation (`input` and `output` slot groups)
- **Equipment Inventories** - Typed equipment slots (`weapon`, `armor`, etc.)

---

## Slot Group Types

### Simple Inventory (default)

Used for player inventory, toolbar, and storage chests.

```lua
{
   slotGroups = {
      default = {
         slots = {
            [1] = {itemId = "wood", quantity = 5},
            [2] = {},  -- empty
         },
         maxSlots = 40
      }
   }
}
```

### Machine Inventory (input/output)

Used for machines with separate input and output slots.

```lua
{
   slotGroups = {
      input = {
         slots = {
            [1] = {itemId = "bone", quantity = 2},
            [2] = {},
         },
         maxSlots = 2
      },
      output = {
         slots = {
            [1] = {},
         },
         maxSlots = 1
      }
   }
}
```

### Equipment Inventory (weapon/armor/etc.)

Used for player equipment with typed slots.

```lua
{
   slotGroups = {
      weapon = {
         slots = {
            [1] = {itemId = "harvesterBasic", quantity = 1},
         },
         maxSlots = 1
      },
      armor = {
         slots = {
            [1] = {itemId = "armorBasic", quantity = 1},
         },
         maxSlots = 1
      }
   }
}
```

---

## Creating Inventories

### New Unified API

```lua
-- Simple inventory
Inventory.new({
   slotGroups = {
      default = { maxSlots = 40 }
   }
})

-- Machine inventory
Inventory.new({
   slotGroups = {
      input = { maxSlots = 2, initialItems = {{itemId = "bone", quantity = 1}} },
      output = { maxSlots = 1 }
   }
})

-- Equipment inventory
Inventory.new({
   slotGroups = {
      weapon = { maxSlots = 1, initialItems = {{itemId = "harvesterBasic", quantity = 1}} },
      armor = { maxSlots = 1, initialItems = {{itemId = "armorBasic", quantity = 1}} }
   }
})
```

### Legacy API (Backward Compatible)

The old API is still supported for existing code:

```lua
-- Simple inventory (creates "default" slot group)
Inventory.new({ maxSlots = 40 })

-- Machine inventory (creates "input" and "output" slot groups)
Inventory.new({
   maxInputSlots = 2,
   maxOutputSlots = 1,
})
```

---

## Inventory Fragment API

The `Inventory` fragment (`src/evolved/fragments/inventory.lua`) provides these functions:

### `Inventory.new(config)`

Creates a new inventory with the specified configuration.

### `Inventory.getSlotGroup(inventory, slotType)`

Returns the slot group for the given type. Defaults to "default" if `slotType` is nil.

### `Inventory.getSlots(inventory, slotType)`

Returns the slots array for the given type.

### `Inventory.getSlot(inventory, slotIndex, slotType)`

Returns a single slot from the specified group.

### `Inventory.getSlotTypes(inventory)`

Returns an array of all slot type names in the inventory.

### `Inventory.addItem(inventory, itemId, count, slotType)`

Adds an item to the first available slot in the specified group.

### `Inventory.duplicate(inventory)`

Deep clones an inventory instance.

---

## InventoryHelper API

The `InventoryHelper` (`src/helpers/inventory_helper.lua`) delegates to the Inventory fragment and provides additional utilities:

### `InventoryHelper.getSlots(inventory, slotType)`

Returns slot array for the given type (nil defaults to "default").

### `InventoryHelper.getSlot(inventory, slotIndex, slotType)`

Returns single slot from the specified group.

### `InventoryHelper.getSlotGroup(inventory, slotType)`

Returns the full slot group (with `slots` and `maxSlots`).

### `InventoryHelper.getSlotTypes(inventory)`

Returns array of all slot type names.

### `InventoryHelper.getMaxSlots(inventory, slotType)`

Returns the max slot count for a group.

### `InventoryHelper.getMaxStackQuantity(itemId)`

Returns max stack size for an item.

### `InventoryHelper.addItem(inventory, itemId, count, slotType)`

Adds an item to the inventory.

---

## Usage Patterns

### Always Use Helpers

```lua
-- ✓ Correct: Use helper functions
local slot = InventoryHelper.getSlot(inventory, index, slotType)
local slots = InventoryHelper.getSlots(inventory, slotType)

-- ✗ Avoid: Direct access (legacy pattern)
local slot = inventory.slots[index]  -- Only works for "default" group
```

### Iterating Over All Slot Groups

```lua
local slotTypes = InventoryHelper.getSlotTypes(inventory)
for _, slotType in ipairs(slotTypes) do
   local slots = InventoryHelper.getSlots(inventory, slotType)
   for i, slot in ipairs(slots) do
      -- Process each slot
   end
end
```

### Checking Equipment

```lua
-- Check all equipment slot types for a specific item category
local slotTypes = InventoryHelper.getSlotTypes(equipment)
for _, slotType in ipairs(slotTypes) do
   local slots = InventoryHelper.getSlots(equipment, slotType)
   for _, slot in ipairs(slots) do
      if slot.itemId then
         local item = ItemQuery.getItem(slot.itemId)
         if item and item.category == "weapon" then
            -- Found a weapon
         end
      end
   end
end
```

---

## UI Integration

### InventoryView

The `InventoryView` class accepts a `slotType` option to specify which slot group to display:

```lua
InventoryView:new(equipment, {
   id = "equipment_weapon",
   slotType = "weapon",
   columns = 1,
   rows = 1,
   x = 16,
   y = 500
})
```

### Equipment Views

Equipment inventories with multiple slot groups are rendered as separate views, one per slot type. The `UICoordinator` handles creating and positioning these views.

### MachineScreen

The `MachineScreen` automatically iterates over all slot types in a machine inventory and creates appropriate UI elements for each.

---

## Future Extensions

Potential slot types that could be added:

- `catalyst` - Slots for items not consumed in recipes
- `fuel` - Dedicated fuel source slots
- `accessory` - Additional equipment slots
- `ammo` - Ammunition for ranged weapons

---

## Slot Constraints

Slot groups can define constraints to restrict which items can be placed in them.

### Accepted Categories

Use `acceptedCategories` to limit a slot group to specific item categories:

```lua
-- Equipment with category constraints
Inventory.new({
   slotGroups = {
      weapon = {
         maxSlots = 1,
         acceptedCategories = {"weapon", "harvester"},  -- Only weapons and harvesters
         initialItems = {
            {itemId = "harvesterBasic", quantity = 1},
         },
      },
      armor = {
         maxSlots = 1,
         acceptedCategories = {"armor"},  -- Only armor items
         initialItems = {
            {itemId = "armorBasic", quantity = 1},
         },
      },
   },
})
```

### Validation

The `InventoryHelper.canPlaceItem()` function checks constraints:

```lua
-- Check if an item can be placed in a slot group
local canPlace = InventoryHelper.canPlaceItem(inventory, itemId, slotType)

-- Get the accepted categories for a slot group
local categories = InventoryHelper.getAcceptedCategories(inventory, slotType)
```

### How It Works

1. When placing an item, the state manager calls `canPlaceItem()`
2. If the slot group has no `acceptedCategories`, any item is allowed
3. If constraints exist, the item's `category` must be in the accepted list
4. Swaps also validate that the swapped item can go to the source slot

### Item Categories

Items define their category in the item data:

```lua
-- equipment_items_data.lua
harvesterBasic = {
   name = "Basic Harvester",
   category = "harvester",  -- Matches acceptedCategories = {"harvester"}
   ...
},
daggerBasic = {
   name = "Basic Dagger",
   category = "weapon",     -- Matches acceptedCategories = {"weapon"}
   ...
},
armorBasic = {
   name = "Basic Armor",
   category = "armor",      -- Matches acceptedCategories = {"armor"}
   ...
},
```

---

## Future Extensions

Potential additional constraints:

- `acceptedItems` - Specific item IDs allowed (whitelist)
- `rejectedItems` - Specific item IDs blocked (blacklist)
- `maxQuantity` - Override max stack size for the slot
- `requiresTags` - Item must have specific tags