# Inventory Click System Documentation

## Overview

This document describes the implementation of the inventory item picking system, which allows players to click on inventory slots to pick up and move items between slots and inventories.

## Architecture

The system is built with clear separation of concerns across multiple components:

### Components

1. **InventoryLayout** (`src/config/inventory_layout.lua`)
   - Centralized configuration for inventory UI dimensions
   - Provides utility functions for slot positioning and hit detection
   - Shared between renderer and state manager

2. **InventoryStateManager** (`src/ui/inventory_state_manager.lua`)
   - Manages inventory state (open/closed, which inventories are active)
   - Handles click detection (which slot was clicked)
   - Manages held item state
   - Implements pick/place/swap/stack logic

3. **InventoryRenderer** (`src/ui/inventory_renderer.lua`)
   - Pure rendering component
   - Draws inventory boxes, slots, and items
   - Draws held item following cursor
   - Uses InventoryLayout for positioning

4. **UISystem** (`src/systems/ui_system.lua`)
   - Coordinates between input events and state manager
   - Manages renderer lifecycle
   - Handles inventory open/close events

## Data Flow

```
User Clicks
    ↓
InputSystem detects mouse click while inventory is open
    ↓
Emits INPUT_INVENTORY_CLICK event with {mouse_x, mouse_y}
    ↓
UISystem receives event → handleInventoryClick()
    ↓
InventoryStateManager:getSlotAt() → determines which slot was clicked
    ↓
If holding item: placeItemInSlot()
If not holding: pickItemFromSlot()
    ↓
State updated (heldStack, slot contents)
    ↓
InventoryRenderer:draw() → reflects new state
```

## Key Features

### 1. Click Detection

The system determines which slot was clicked by:
- Getting inventory base positions from layout
- Calculating each slot's position using `InventoryLayout:getSlotPosition()`
- Checking if mouse coordinates fall within any slot bounds
- Returning slot info: `{inventory_type, slot_index, item}`

### 2. Item Picking Logic

When clicking on a slot:

**If NOT holding an item:**
- Pick up the entire stack from the slot
- Store in `InventoryStateManager.heldStack`
- Clear the source slot

**If ALREADY holding an item:**
- **Same item type:** Stack items together (combines quantities)
- **Different item type:** Swap the held item with the slot's item
- Empty slot: Place the held item

### 3. Held Item Tracking

The `heldStack` object contains:
```lua
{
   item_id = "stone",
   quantity = 5,
   source_inventory = "player",  -- or "target"
   source_slot = 3
}
```

This allows the system to:
- Know what item is being held
- Track where it came from
- Return it to source if needed

### 4. Visual Feedback

The renderer draws the held item:
- Semi-transparent slot background
- Following the mouse cursor
- Offset by half slot size (centered on cursor)
- Shows item icon and quantity

## API Reference

### InventoryStateManager

#### `open(player_inventory, target_inventory)`
Opens an inventory view with player inventory and optionally a target inventory.

#### `close()`
Closes the inventory and clears all state including held items.

#### `getSlotAt(mouse_x, mouse_y)`
Returns slot info for the slot at the given coordinates, or nil.
```lua
{
   inventory_type = "player" | "target",
   slot_index = number,
   item = table | nil
}
```

#### `pickItemFromSlot(slot_index, inventory_type)`
Picks up an item from the specified slot. Returns the held stack.

#### `placeItemInSlot(slot_index, inventory_type)`
Places the held item into the specified slot. Handles stacking and swapping.

#### `dropHeldItem()`
Attempts to return the held item to its source or discard it.

### InventoryLayout

#### `getSlotPosition(slot_index, base_x, base_y)`
Returns the x, y pixel coordinates of a slot.

#### `getInventoryPositions(has_target)`
Returns base positions for player and target inventories.

#### `isPointInSlot(mouse_x, mouse_y, slot_x, slot_y)`
Returns true if the point is inside the slot bounds.

## Configuration

Edit `src/config/inventory_layout.lua` to customize:

```lua
{
   slot_size = 32,              -- Pixel size of each slot
   padding = 4,                 -- Padding around inventory
   border_width = 2,            -- Border width of each slot
   columns = 10,                -- Number of columns
   rows = 4,                    -- Number of rows
   gap_between_inventories = 20 -- Gap when showing two inventories
}
```

## Future Enhancements

### TODO Items in Code

1. **Max Stack Size:** Currently items stack without limit. Need to add max stack size logic in `placeItemInSlot()` and `swapOrStackItems()`.

2. **Drop Handling:** `dropHeldItem()` needs proper implementation for:
   - Finding an empty slot
   - Emitting a drop event to spawn item in world
   - Handling full inventories

3. **Right-Click Split:** Add ability to split stacks by right-clicking.

4. **Shift-Click Transfer:** Quick transfer between player and target inventory.

5. **Slot Highlighting:** Visual feedback when hovering over slots.

6. **Item Tooltips:** Show item details on hover.

## Testing

To test the system:

1. Open player inventory (default: E key)
2. Click on a slot with an item to pick it up
3. Click on another slot to place it
4. Click on different items to swap them
5. Click on same item types to stack them

## Troubleshooting

**Items not picking up:**
- Check that inventory has `input_slots` array
- Verify slots have `item_id` and `quantity` fields

**Click not registering:**
- Ensure `INPUT_INVENTORY_CLICK` event passes `{mouse_x, mouse_y}` table
- Check that positions are calculated correctly

**Held item not visible:**
- Verify `InventoryRenderer:drawHeldItem()` is called
- Check that `heldStack.item_id` is set

**Items disappearing:**
- Check slot clearing logic in `pickItemFromSlot()`
- Verify `placeItemInSlot()` is properly setting slot values