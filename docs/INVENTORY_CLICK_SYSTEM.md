# Inventory Click System

> **Last Updated:** 2026-01-13

Handles clicking inventory slots to pick up and move items between slots and inventories.

---

## Components

| Component | File | Purpose |
|:----------|:-----|:--------|
| InventoryViewManager | `src/ui/inventoryview_manager.lua` | Click detection, held item state, pick/place logic |
| InventoryView | `src/ui/inventory_view.lua` | Slot positioning, hit detection, drawing |
| MachineView | `src/ui/machine_view.lua` | Machine UI with typed slots |
| MachineViewManager | `src/ui/machine_view_manager.lua` | Machine-specific click handling |
| InputSystem | `src/evolved/systems/input_system.lua` | Mouse/keyboard input detection |
| RenderUISystem | `src/evolved/systems/render_ui_system.lua` | Event observers, view management |

---

## Data Flow

```
User Click
    ↓
InputSystem detects click
    ↓
If inventory open: INPUT_INVENTORY_CLICKED event
    ↓
StateManager:handleSlotClick(mouse_x, mouse_y)
    ↓
getSlotUnderMouse() → finds slot
    ↓
If holding: placeItemInSlot()
If not holding: pickItemFromSlot()
```

---

## Click Logic

**Not holding an item:**

- Pick up entire stack from clicked slot
- Store in `heldStack` with source tracking
- Hide mouse cursor

**Holding an item:**

- Empty slot: Place item
- Same item type: Stack (combine quantities)
- Different item type: Swap items

**On inventory close:**

- Return held item to source slot
- Restore cursor

---

## Held Stack Structure

```lua
{
   itemId = "stone",
   quantity = 5,
   source_inventory = InventoryComponent,
   source_slot = 3,
   source_slot_type = nil  -- or "input"/"output" for machines
}
```

---

## Events

| Event | Payload | Description |
|:------|:--------|:------------|
| `INPUT_INVENTORY_CLICKED` | `mouse_x, mouse_y` | Click while inventory open |
| `INPUT_INVENTORY_OPENED` | `playerInventory, playerToolbar` | Inventory key pressed |
| `INPUT_INVENTORY_CLOSED` | none | Close/escape key |
| `ENTITY_INTERACTED` | `playerInventory, targetInventory, playerToolbar, entityId` | Entity interaction |

---

## Testing Checklist

1. Open inventory → click slot with item → item follows cursor
2. Click another slot → item placed/stacked/swapped
3. Close with held item → returns to source
4. Interact with storage → side-by-side inventories work
5. Toolbar is usable during inventory screens

---

## TODO

| Priority | Feature |
|:--------:|:--------|
| High | Max stack size per item type |
| Medium | Right-click split stack |
| Medium | Shift-click transfer |
| Medium | Proper item icons (replace letters) |
| Low | Drop items outside inventory |
| Low | Slot hover highlighting |
| Low | Item tooltips |

---

## Known Issues

- No max stack size (infinite stacking)
- Item icons show first letter only
- No input validation on slot operations
