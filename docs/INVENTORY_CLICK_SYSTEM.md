# Inventory Click System Documentation

> **Last Updated:** 2025-01-11  
> **Status:** ✅ Core Implementation Complete (Evolved ECS)

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
| RenderUISystem | `src/evolved/systems/render_ui_system.lua` | ✅ |
| InputSystem | `src/evolved/systems/input_system.lua` | ✅ |
| Inventory Fragment | `src/evolved/fragments/inventory.lua` | ✅ |

### Component Responsibilities

1. **InventoryStateManager** (`src/ui/inventory_state_manager.lua`)
   - Manages inventory UI state (open/closed, active views)
   - Handles click detection via `handleSlotClick(mouse_x, mouse_y)`
   - Manages held item state (`heldStack`)
   - Implements pick/place/swap/stack logic
   - Returns held items to source slot when inventory closes
   - Coordinates drawing of all active inventory views

2. **InventoryView** (`src/ui/inventory_view.lua`)
   - Represents a single inventory panel (toolbar, player inventory, or storage)
   - Handles slot positioning and hit detection (`getSlotUnderMouse`)
   - Draws inventory box and slots using `DrawHelper` mixin
   - Supports multiple instances for side-by-side inventory display
   - Configurable columns, rows, position, and slot size

3. **DrawHelper** (`src/helpers/draw_helper.lua`)
   - Shared drawing utilities for UI elements
   - Functions: `drawBox`, `drawSlot`, `drawItem`, `drawHeldStack`
   - Mixed into `InventoryView` class for reusable rendering
   - Handles borders, backgrounds, item icons, and quantity text

4. **RenderUISystem** (`src/evolved/systems/render_ui_system.lua`)
   - Coordinates between input events and state manager
   - Creates and manages `InventoryView` instances
   - Handles inventory open/close events via Beholder observers
   - Maintains persistent toolbar view
   - Always renders toolbar; conditionally renders inventory popups
   - Supports both player-only and player+storage inventory modes

5. **InputSystem** (`src/evolved/systems/input_system.lua`)
   - Detects mouse clicks and keyboard input
   - Emits `INPUT_INVENTORY_CLICKED` event when clicking while inventory is open
   - Emits `INPUT_INTERACTED` event when clicking while inventory is closed
   - Handles movement input (blocked when inventory is open)
   - Manages open/close inventory key bindings

6. **Inventory Fragment** (`src/evolved/fragments/inventory.lua`)
   - ECS fragment attached to entities
   - Contains `slots`
   - Each slot: `{item_id: string, quantity: number}`
   - Provides `new()` and `duplicate()` functions

## Data Flow

```
User Clicks Mouse
    ↓
InputSystem detects click (via action detector)
    ↓
If inventory open: trigger INPUT_INVENTORY_CLICKED event (mouse_x, mouse_y)
If inventory closed: trigger INPUT_INTERACTED event (mouse_x, mouse_y)
    ↓
RenderUISystem observer receives event → calls handler
    ↓
InventoryStateManager:handleSlotClick(mouse_x, mouse_y)
    ↓
getSlotUnderMouse() → iterates through views
    ↓
Each InventoryView:getSlotUnderMouse() checks bounds
    ↓
Returns {view, slotIndex, slot} or nil
    ↓
If holding item: placeItemInSlot()
If not holding: pickItemFromSlot()
    ↓
State updated (heldStack, slot.item_id, slot.quantity)
    ↓
Mouse cursor hidden/shown based on held state
    ↓
InventoryStateManager:draw() → reflects new state
```

## Key Features

### 1. Click Detection

The system determines which slot was clicked by:

- Iterating through all active `InventoryView` instances in `views` array
- Each view calculates slot positions based on its configuration (x, y, columns, rows, slot_size)
- Checking if mouse coordinates fall within any slot bounds using `isPointInSlot()`
- Returning slot info: `{view, slotIndex, slot}` where slot contains `{item_id, quantity}`

### 2. Item Picking Logic

When clicking on a slot:

**If NOT holding an item (`heldStack == nil`):**

- Pick up the entire stack from the slot via `pickItemFromSlot()`
- Store in `InventoryStateManager.heldStack`
- Clear the source slot (`item_id = nil, quantity = 0`)
- Hide mouse cursor (`love.mouse.setVisible(false)`)

**If ALREADY holding an item:**

- **Empty slot:** Place the held item in the slot
- **Same item type:** Stack items together (combines quantities, no max limit currently)
- **Different item type:** Swap the held item with the slot's item, update source tracking
- Show mouse cursor when item is placed (`love.mouse.setVisible(true)`)

### 3. Held Item Tracking

The `heldStack` object contains:

```lua
{
   item_id = "stone",
   quantity = 5,
   source_inventory = InventoryComponent,  -- Reference to source inventory
   source_slot = 3                         -- Index of source slot
}
```

This allows the system to:

- Know what item is being held
- Track where it came from
- Return it to source if inventory is closed without placing
- Update source tracking when swapping items

### 4. Visual Feedback

The held item is rendered by `DrawHelper:drawHeldStack()`:

- Semi-transparent slot background (alpha: 0.8)
- Follows the mouse cursor position
- Offset by half slot size (centered on cursor)
- Shows item icon (first letter of item_id)
- Shows quantity if > 1
- Mouse cursor is hidden while holding item

### 5. Multi-Inventory Support

UISystem creates different view configurations:

**Player Inventory Only:**
- Toolbar view (bottom of screen, always visible)
- Player inventory view (center of screen)

**Player + Storage Inventory:**
- Toolbar view (bottom of screen, always visible)
- Player inventory view (left side of center)
- Storage inventory view (right side of center, with gap)

### 6. Return on Close

When inventory closes with held item:

- `InventoryStateManager:close()` detects `heldStack`
- Calls `returnHeldStack()` to place item back in source slot
- Restores mouse cursor visibility
- Clears all state

## API Reference

### InventoryStateManager

#### `open(views)`

Opens the inventory UI with an array of `InventoryView` instances.

**Parameters:**
- `views` (table): Array of InventoryView objects to display

#### `close()`

Closes the inventory and clears all state. Returns any held items to their source slot.

#### `getSlotUnderMouse(mouse_x, mouse_y)`

Returns slot info for the slot at the given coordinates, or nil.

**Returns:**
```lua
{
   view = InventoryView,        -- The view containing the slot
   slotIndex = number,          -- 1-based slot index
   slot = {item_id, quantity}   -- The slot data
}
```

#### `handleSlotClick(mouse_x, mouse_y)`

Main entry point for click logic. Determines which slot was clicked and executes pick/place logic.

**Returns:** `boolean` - Success status

#### `pickItemFromSlot(slot_index, inventory)`

Picks up an item from the specified slot. Assumes `heldStack` is nil.

**Parameters:**
- `slot_index` (number): The slot index to pick from
- `inventory` (InventoryComponent): The inventory component

**Returns:** `boolean` - Success status

#### `placeItemInSlot(slot_index, inventory)`

Places the held item into the specified slot. Handles stacking and swapping.

**Parameters:**
- `slot_index` (number): The slot index to place into
- `inventory` (InventoryComponent): The inventory component

**Returns:** `boolean` - Success status

#### `returnHeldStack()`

Returns the currently held item to its source slot. Called automatically on `close()`.

#### `draw()`

Draws all active inventory views and the held stack (if any).

### InventoryView

#### `new(inventory, options)`

Creates a new inventory view instance.

**Parameters:**
- `inventory` (InventoryComponent): The inventory to display
- `options` (table): Configuration options
  - `id` (string): Unique identifier
  - `x` (number): X position in pixels
  - `y` (number): Y position in pixels
  - `columns` (number): Number of columns (default: 10)
  - `rows` (number): Number of rows (default: 4)
  - `slot_size` (number): Slot size in pixels (default: 32)
  - `padding` (number): Padding in pixels (default: 4)

#### `draw()`

Renders the inventory view (box and slots).

#### `getSlotPosition(slot_index)`

Returns the x, y pixel coordinates of a slot.

**Returns:** `x, y` (numbers)

#### `isPointInSlot(mx, my, slot_x, slot_y)`

Returns true if the point is inside the slot bounds.

#### `getSlotUnderMouse(mx, my)`

Returns slot info if mouse is over a slot, otherwise nil.

#### `setPosition(x, y)`

Updates the view's position. Useful for draggable windows.

### DrawHelper

Mixin providing drawing utilities:

- `drawBox(x, y, width, height)` - Draws bordered box
- `drawSlot(x, y, width, height, slot)` - Draws slot with item
- `drawItem(x, y, width, height, slot, color)` - Draws item icon and quantity
- `drawBorder(x, y, width, height, color)` - Draws border rectangle
- `drawBackground(x, y, width, height, color)` - Draws background rectangle
- `drawHeldStack(stack, mouse_x, mouse_y)` - Draws held item following cursor

## Configuration

Layout is currently hardcoded in `UISystem`. Key constants:

```lua
SLOT_SIZE = 32              -- Pixel size of each slot
COLUMNS = 10                -- Number of columns
INV_ROWS = 4                -- Number of rows for full inventory
INV_GAP = 20                -- Gap between player and storage inventories
TOOLBAR_ROWS = 1            -- Number of rows in toolbar
```

DrawHelper constants:

```lua
SLOT_SIZE = 32
BORDER_WIDTH = 2
BORDER_COLOR = {1, 1, 1}
BACKGROUND_COLOR = {0.5, 0.45, 0.5}
STACK_BORDER_COLOR = {1, 1, 1, 0.8}
STACK_BACKGROUND_COLOR = {0.5, 0.45, 0.5, 0.8}
TEXT_COLOR = {1, 1, 1}
```

## Events

| Event | Emitter | Payload | Description |
|:------|:--------|:--------|:------------|
| `INPUT_INVENTORY_CLICKED` | InputSystem | `mouse_x, mouse_y` | Mouse clicked while inventory is open |
| `INPUT_INVENTORY_OPENED` | InputSystem | `playerInventory, playerToolbar` | Player pressed inventory key |
| `INPUT_INVENTORY_CLOSED` | InputSystem | none | Player pressed close/escape key |
| `ENTITY_INTERACTED` | InteractionSystem | `playerInventory, targetInventory, playerToolbar, entityId` | Player interacted with entity |

## Testing

To test the system:

1. **Open player inventory** (default: E key)
2. **Click on a slot** with an item to pick it up
   - Mouse cursor should disappear
   - Item should follow cursor
3. **Click on another slot** to place it
   - Empty slot: Item is placed
   - Same item: Items stack together
   - Different item: Items swap positions
4. **Close inventory** (default: Escape) while holding item
   - Item should return to original slot
   - Mouse cursor should reappear
5. **Interact with storage** entity
   - Should see player inventory on left, storage on right
   - Can move items between both inventories

## Future Enhancements

### Completed ✅

- ✅ **Pick/Place Items**: Click to pick up, click to place
- ✅ **Stack Merging**: Same item types combine quantities
- ✅ **Item Swapping**: Different items swap positions
- ✅ **Held Item Rendering**: Item follows cursor when held
- ✅ **Multi-Inventory Support**: Side-by-side player + storage inventories
- ✅ **Toolbar Integration**: Always-visible toolbar, interactable during inventory screens
- ✅ **Return on Close**: Held items return to source slot when inventory closes
- ✅ **View-Based Architecture**: Flexible InventoryView system for multiple panels

### TODO Items

| Priority | Feature | Description |
|:--------:|:--------|:------------|
| High | **Max Stack Size** | Items stack without limit. Add max stack size per item type. |
| High | **Item Registry** | Create item definitions with metadata (name, icon, max_stack, etc). |
| Medium | **Right-Click Split** | Split stacks by right-clicking. |
| Medium | **Shift-Click Transfer** | Quick transfer between player and storage inventory. |
| Medium | **Proper Item Icons** | Replace single-letter placeholders with actual sprites. |
| Low | **Drop Handling** | Emit drop event to spawn item in world when clicking outside. |
| Low | **Deploy Handling** | Emit deploy event to deploy structure in world when clicking on terrain with deployable item. |
| Low | **Slot Highlighting** | Visual feedback when hovering over slots. |
| Low | **Item Tooltips** | Show item details on hover. |
| Low | **Wheel Scrolling** | Scroll up/down to move items between inventories. |
| Low | **Number Keys** | Press 1-9 to move hovered item to toolbar slot. |
| Low | **Configuration File** | Extract hardcoded constants to `config/inventory_layout.lua`. |
| Low | **Draggable Windows** | Allow dragging inventory panels around screen. |

## Known Issues

- **No max stack size:** Items stack infinitely
- **Item icons:** Currently showing first letter of item_id instead of proper sprites
- **Toolbar in views array:** Toolbar is included in InventoryStateManager.views when inventory is open, but also drawn separately in UISystem:draw()
- **No validation:** Slot indices and inventory references aren't validated

## Architecture Notes

### Why View-Based?

The view-based architecture allows:
- Multiple inventory panels on screen simultaneously
- Each panel can represent different inventory sources
- Easy to add new panel types (crafting, equipment, etc.)
- Clean separation between data (Inventory Fragment) and presentation (InventoryView)

### Why Track Source?

Tracking `source_inventory` and `source_slot` in `heldStack` enables:
- Returning items when closing inventory
- Updating source tracking when swapping
- Future features like "cancel" or "undo" operations

### Why Hide Cursor?

Hiding the mouse cursor when holding an item:
- Prevents visual clutter (cursor overlapping held item sprite)
- Makes it clearer that an item is being moved
- Common UX pattern in inventory systems

### Integration with Evolved ECS

The inventory system integrates with the Evolved ECS architecture:
- **Inventory Fragment**: Stores slot data on entities
- **InventoryView**: Queries entity state directly (e.g., machine state via `entityId`)
- **Events**: Uses Beholder for event triggers and observers
- **No polling**: Views update reactively when state changes
