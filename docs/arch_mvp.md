# Super Fantasy Factory - MVP Architecture

> **Last Updated:** 2026-01-20

Core gameplay loop: **Player → Creative Chest → Toolbar → Assembly Station → Ritual → Skeleton Spawn**

---

## Implementation Status

| Step | Task | Status |
| :--: | :--- | :----: |
| 1 | Materials, recipes, mana system | ✅ Done |
| 2 | Player toolbar and selection | ✅ Done |
| 3 | Creative Chest for infinite supply | ✅ Done |
| 4 | Assembly Station entity and UI | ✅ Done |
| 5 | Processing timers, mana, creature spawning | 🔄 In Progress |

### Systems Completed

- **ECS Architecture**: Evolved-based entity system
- **Interaction System**: Proximity + mouse-based interaction
- **Input System**: Player input handling
- **UI System**: Toolbar, inventory popups, item transfer
- **Inventory Fragment**: Reusable inventory logic (simple and typed slots)
- **Processing System**: Behavior-based machine automation
- **Mana System**: Mana regeneration for entities

### Pending

- **Creature Spawning**: Spawn skeletons on ritual completion

---

## Entity Specifications

| Entity | Visual | Size | Color |
| :--- | :--- | :--- | :--- |
| Player | Circle | r = 16px | Blue |
| Assembly Station | Rectangle | 64 × 64px | Purple |
| Creative Chest | Rectangle | 32 × 32px | Gold |
| Items | Icon | 8 × 8px | Various |

---

## Project Structure

```
src/
├── config/              # Colors, events, input bindings
├── data/                # Static game data
│   ├── entities/        # Entity definitions
│   ├── items/           # Item definitions
│   └── recipes_data.lua
├── evolved/             # Evolved ECS
│   ├── behaviors/       # Machine behavior modules
│   ├── fragments/       # ECS components
│   ├── systems/         # ECS systems
│   ├── entities.lua     # Prefabs
│   └── fragments.lua    # Fragment/tag definitions
├── helpers/             # Utilities
├── registries/          # Data lookup APIs
└── ui/                  # UI components
    ├── inventory_state_manager.lua
    ├── inventory_view.lua
    ├── machine_screen.lua
    └── machine_state_manager.lua
```

---

## ECS Systems

| System | Purpose |
| :------- | :-------- |
| Setup | Spawns initial entities |
| Input | Player input, emits events |
| Interaction | Entity interactions |
| UpdateZIndex | Syncs ZIndex from Y position for depth sorting |
| Physics | Position updates |
| Mana | Mana regeneration |
| Processing | Machine behaviors |
| SortEntities | Collects entities with ZIndex for rendering |
| RenderSortedEntities | Sorts by ZIndex and draws in order |
| Render Debug | Debug overlays |
| Render UI | Inventory UI |

---

## Rendering Architecture

Entities use **ZIndex-based Y-sorting** for 2.5D depth ordering:

1. `UpdateZIndex` system sets `ZIndex = Position.y` each frame
2. `SortEntities` collects all entities with ZIndex into a render list
3. `RenderSortedEntities` sorts by ZIndex (lower Y = further back) and draws

**Tags:** `Animated` and `Static` require `ZIndex` fragment.

**Extension:** Add `ZOffset` fragment for flying entities or elevated platforms.

---

## Assembly Station FSM

```
      [BLANK] ──set_recipe──► [IDLE] ◄─────────────┐
                                │                   │
                           prepare                  │
                                ▼                   │
                             [READY]                │
                                │                   │
                          startRitual              │
                                │                   │
                                ▼                   │
     [NO_MANA] ◄───starve─── [WORKING] ───block───► [BLOCKED]
         │                      │                       │
         │                   complete                   │
         │                      │                       │
         └───────refuel─────────┴───────unblock────────┘
                                │
                                ▼
                             [IDLE]
```

---

## See Also

- `PROCESSING_SYSTEM.md` - Machine automation details
- `INVENTORY_SYSTEM.md` - Dual inventory pattern
- `TODO.md` - Project roadmap
