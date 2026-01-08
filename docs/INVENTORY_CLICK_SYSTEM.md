# Inventory Click System Documentation

> **Last Updated:** 2026-01-08  
> **Status:** ✅ Core Implementation Complete

## Overview

This document describes the implementation of the inventory item picking system, which allows players to click on inventory slots to pick up and move items between slots and inventories.

## Architecture

The system is built with clear separation of concerns across multiple components:

### Components

| Component | File | Status |
|:----------|:-----|:------:|
| InventoryStateManager | `src/ui/inventory_state_manager.lua` | ✅ |
| InventoryView | `src/ui/inventory_view.lua` | ✅ |
| DrawHelper | `src/helpers/draw_helper.lua` | ✅ |
| UISystem | `src/systems/ui_system.lua` | ✅ |

1. **InventoryStateManager** (`src/ui/inventory_state_manager.lua`)
   - Manages inventory state (open/closed, which inventories are active)
   - Handles click detection via `handleSlotClick(mouse_x, mouse_y)`
   - Manages held item state (`heldStack`)
   - Implements pick/place/swap/stack logic
   - Returns held items to source slot when inventory closes

2. **InventoryView** (`src/ui/inventory_view.lua`)
   - Represents a single inventory panel (toolbar, player inventory, or target)
   - Handles slot positioning and hit detection (`getSlotUnderMouse`)
   - Draws inventory box and slots using `DrawHelper`
   - Supports multiple instances for side-by-side inventory display

3. **DrawHelper** (`src/helpers/draw_helper.lua`)
   - Shared drawing utilities (boxes, slots, held items)
   - Mixed into `InventoryView` class

4. **UISystem** (`src/systems/ui_system.lua`)
   - Coordinates between input events and state manager
   - Creates and manages `InventoryView` instances
   - Handles inventory open/close events
   - Always renders toolbar; conditionally renders inventory popups

## Data Flow

```raw
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

### Completed

- ✅ **Pick/Place Items**: Click to pick up, click to place
- ✅ **Stack Merging**: Same item types combine quantities
- ✅ **Item Swapping**: Different items swap positions
- ✅ **Held Item Rendering**: Item follows cursor when held
- ✅ **Multi-Inventory Support**: Side-by-side player + target inventories
- ✅ **Toolbar Integration**: Always-visible toolbar, interactable during inventory screens
- ✅ **Return on Close**: Held items return to source slot when inventory closes

### TODO Items

| Priority | Feature | Description |
| :--------: | :--------: | :------------ |
| High | **Max Stack Size** | Items stack without limit. Add max logic in `placeItemInSlot()`. |
| Medium | **Right-Click Split** | Split stacks by right-clicking. |
| Medium | **Shift-Click Transfer** | Quick transfer between player and target inventory. |
| Low | **Drop Handling** | Emit drop event to spawn item in world when clicking outside. |
| Low | **Deploy Handlling** | Emit deploy event to deploy structure in world when clicking on terrain with a deployable item in hand. |
| Low | **Slot Highlighting** | Visual feedback when hovering over slots. |
| Low | **Item Tooltips** | Show item details on hover. |
| Low | **Wheel-scrolling** | Scroll up/down to move items between inventories. |
| Low | **Number Keys** | Press 1-9 to move hovered item to toolbar slot. |

## Testing

To test the system:

1. Open player inventory (default: E key)
2. Click on a slot with an item to pick it up
3. Click on another slot to place it
4. Click on different items to swap them
5. Click on same item types to stack them
