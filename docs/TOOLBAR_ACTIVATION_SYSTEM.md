# Toolbar Activation System

> **Last Updated:** 2026-01-13  
> **Status:** Design Document

Handles toolbar slot activation when inventories are closed. Clicking or using a keyboard shortcut on a slot containing a deployable item immediately enters placement mode.

---

## Behavior Model

**Hybrid Minecraft/Factorio approach:**

| Aspect | Minecraft | Factorio | Super Fantasy Factory |
|:-------|:----------|:---------|:----------------------|
| Toolbar is inventory? | ✅ Yes (hotbar row) | ❌ No (shortcuts) | ✅ Yes |
| Selection before use? | ✅ Yes (highlight slot) | ❌ No (immediate) | ❌ No |
| Activation trigger | Use key | Click/shortcut | Click/shortcut |

**Core Rule:** When inventories are closed, clicking a toolbar slot (or pressing 1-9) with a deployable item → **immediately enter placement mode**.

---

## Activation Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INVENTORIES CLOSED                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   User Action                                                       │
│       │                                                             │
│       ├── Left-click toolbar slot                                   │
│       │       │                                                     │
│       │       └──► TOOLBAR_SLOT_ACTIVATED event                     │
│       │                   │                                         │
│       └── Keyboard 1-9    │                                         │
│               │           │                                         │
│               └───────────┤                                         │
│                           ▼                                         │
│                   ┌───────────────┐                                 │
│                   │ Slot empty?   │──Yes──► (nothing happens)       │
│                   └───────┬───────┘                                 │
│                           │ No                                      │
│                           ▼                                         │
│                   ┌───────────────┐                                 │
│                   │ Item is       │──No───► (future: other actions) │
│                   │ deployable?   │                                 │
│                   └───────┬───────┘                                 │
│                           │ Yes                                     │
│                           ▼                                         │
│               ┌───────────────────────┐                             │
│               │ ENTER PLACEMENT MODE  │                             │
│               │                       │                             │
│               │ • Ghost preview       │                             │
│               │ • Collision check     │                             │
│               │ • Left-click: deploy  │                             │
│               │ • Right-click: cancel │                             │
│               └───────────────────────┘                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Placement Mode

Once activated, the player enters **placement mode** until they deploy or cancel.

### Ghost Preview

- Semi-transparent entity follows cursor
- Shows entity size and shape
- Color indicates validity:
  - **Green**: Valid placement
  - **Red**: Invalid (collision)

### Deploy Action

- Left-click in valid location → spawn entity
- Consume 1 item from toolbar slot
- If stack remains → stay in placement mode
- If stack empty → exit placement mode

### Cancel Action

- Right-click → exit placement mode
- Press Escape → exit placement mode
- Open any inventory → exit placement mode

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INPUT LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   input_system.lua                                                  │
│       │                                                             │
│       ├── Keyboard 1-9 pressed ──► TOOLBAR_SLOT_ACTIVATED(index)    │
│       │                                                             │
│       └── (inventory closed check before emitting)                  │
│                                                                     │
│   inventory_view.lua (toolbar instance)                             │
│       │                                                             │
│       └── onClick ──► TOOLBAR_SLOT_ACTIVATED(index)                 │
│           (only when inventory closed)                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      ACTIVATION LAYER                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   toolbar_activation_manager.lua (NEW)                              │
│       │                                                             │
│       ├── Observes: TOOLBAR_SLOT_ACTIVATED                          │
│       │                                                             │
│       ├── Reads toolbar slot data                                   │
│       │                                                             │
│       ├── Checks item.deployable flag                               │
│       │                                                             │
│       └── Triggers: PLACEMENT_MODE_ENTERED(itemId, slot_index)     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      PLACEMENT LAYER                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   placement_manager.lua (NEW)                                       │
│       │                                                             │
│       ├── Observes: PLACEMENT_MODE_ENTERED                          │
│       │                                                             │
│       ├── State:                                                    │
│       │   • isPlacing: boolean                                      │
│       │   • placingItemId: string                                   │
│       │   • sourceSlotIndex: number                                 │
│       │   • ghostPosition: Vector                                   │
│       │   • isValidPlacement: boolean                               │
│       │                                                             │
│       ├── update(dt):                                               │
│       │   • Update ghost position to cursor                         │
│       │   • Check collision at ghost position                       │
│       │                                                             │
│       ├── draw():                                                   │
│       │   • Draw ghost entity (green/red)                           │
│       │                                                             │
│       ├── handleClick():                                            │
│       │   • Left-click + valid → deploy entity                      │
│       │   • Right-click → cancel                                    │
│       │                                                             │
│       └── Triggers: ENTITY_DEPLOYED(entity_id, position)            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       SPAWN LAYER                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Entity spawning (existing Evolved patterns)                       │
│       │                                                             │
│       ├── Look up entity definition from EntityRegistry             │
│       │   (itemId → entity_type mapping)                           │
│       │                                                             │
│       ├── Spawn entity at position                                  │
│       │                                                             │
│       └── Consume item from toolbar slot                            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## New Files

| File | Purpose |
|:-----|:--------|
| `src/ui/toolbar_activation_manager.lua` | Handles slot activation → placement mode transition |
| `src/ui/placement_manager.lua` | Ghost preview, collision, deploy/cancel logic |

---

## New Events

| Event | Payload | Description |
|:------|:--------|:------------|
| `TOOLBAR_SLOT_ACTIVATED` | `slotIndex` | Toolbar slot clicked/keyed (inv closed) |
| `PLACEMENT_MODE_ENTERED` | `itemId, slotIndex` | Deployable activated |
| `PLACEMENT_MODE_EXITED` | `reason` | Cancelled or deployed |
| `ENTITY_DEPLOYED` | `entityType, position, slotIndex` | Entity spawned |

---

## Item → Entity Mapping

Deployable items need to know which entity to spawn:

```lua
-- src/data/items/deployable_items_data.lua
skeleton_assembler = {
   name = "Skeleton Assembler",
   category = "building",
   maxStackSize = 10,
   deployable = true,
   spawnsEntity = "SkeletonAssembler",  -- ADD THIS
}

-- src/data/items/creature_items_data.lua
skeleton = {
   name = "Skeleton",
   category = "creature",
   maxStackSize = 5,
   deployable = true,
   spawnsEntity = "skeleton",  -- ADD THIS
}
```

---

## Modifications to Existing Files

### 1. `src/ui/inventory_view.lua`

Add context-aware click handling:

```lua
onEvent = function(element, event)
   if event.type == "click" then
      local mx, my = love.mouse.getPosition()
      
      -- Check if this is the toolbar and inventory is closed
      if self.id == "toolbar" and not InventoryViewManager.isOpen then
         Beholder.trigger(Events.TOOLBAR_SLOT_ACTIVATED, slotIndex)
      else
         Beholder.trigger(Events.INPUT_INVENTORY_CLICKED, mx, my, element.userdata)
      end
   end
end
```

### 2. `src/evolved/systems/input_system.lua`

Add keyboard shortcuts for toolbar:

```lua
-- In actionDetection()
for i = 1, 9 do
   if actionDetector:pressed(A["TOOLBAR_" .. i]) then
      if not InventoryViewManager.isOpen and not MachineViewManager.isOpen then
         trigger(Events.TOOLBAR_SLOT_ACTIVATED, i)
      end
   end
end
-- Slot 10 with key "0"
if actionDetector:pressed(A.TOOLBAR_10) then
   if not InventoryViewManager.isOpen and not MachineViewManager.isOpen then
      trigger(Events.TOOLBAR_SLOT_ACTIVATED, 10)
   end
end
```

### 3. `src/config/input_bindings.lua`

Add toolbar action bindings:

```lua
actions = {
   -- ... existing ...
   TOOLBAR_1 = "toolbar_1",
   TOOLBAR_2 = "toolbar_2",
   -- ... through TOOLBAR_10 ...
}

bindings = {
   -- ... existing ...
   keyboard = {
      ["1"] = A.TOOLBAR_1,
      ["2"] = A.TOOLBAR_2,
      -- ... through ["0"] = A.TOOLBAR_10 ...
   }
}
```

### 4. `src/config/events.lua`

Add new events:

```lua
TOOLBAR_SLOT_ACTIVATED = "toolbar:slot_activated",
PLACEMENT_MODE_ENTERED = "placement:entered",
PLACEMENT_MODE_EXITED = "placement:exited",
ENTITY_DEPLOYED = "entity:deployed",
```

---

## Implementation Order

| Step | Task | Dependencies |
|:----:|:-----|:-------------|
| 1 | Add `spawnsEntity` to item data | None |
| 2 | Add events to `events.lua` | None |
| 3 | Add keyboard bindings | None |
| 4 | Create `ToolbarActivationManager` | Steps 1-3 |
| 5 | Modify `InventoryView` click logic | Step 4 |
| 6 | Add keyboard shortcuts to `input_system.lua` | Steps 2-3 |
| 7 | Create `PlacementManager` (ghost only) | Step 4 |
| 8 | Add collision detection | Step 7 |
| 9 | Add entity spawning | Step 8 |
| 10 | Add item consumption | Step 9 |

---

## MVP Scope

For initial implementation, focus on:

1. ✅ Toolbar click → activate slot
2. ✅ Keyboard 1-9 → activate slot
3. ✅ Deployable check
4. ⚠️ Ghost preview (simple rectangle, no collision)
5. ✅ Left-click → spawn entity at cursor
6. ✅ Right-click → cancel
7. ✅ Consume item from slot

**Defer for later:**

- Collision detection (red/green preview)
- Snap to grid
- Visual polish (animations, particles)

---

## See Also

- `INVENTORY_CLICK_SYSTEM.md` - How inventory clicks work
- `arch_mvp.md` - Overall architecture
- `TODO.md` - Project roadmap
