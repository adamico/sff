# Super Fantasy Factory - MVP High-Level Architecture

> **Last Updated:** 2025-01-11

This document outlines the architecture for testing the core gameplay loop of Super Fantasy Factory: **Player → Creative Chest → Toolbar → Assembly Station → Ritual → Skeleton Spawn**.

---

## Implementation Status

| Step | Task | Status | Notes |
| :--: | :--- | :----: | :---- |
| 1 | **Foundation**: Define materials, recipes, and mana system | ✅ Done | `src/data/recipes_data.lua`, `src/evolved/systems/mana_system.lua` |
| 2 | **Toolbar**: Implement the player toolbar and selection logic | ✅ Done | `src/evolved/fragments/inventory.lua`, `src/ui/inventory_view.lua` |
| 3 | **Chest**: Create the Creative Chest for infinite bone supply | ✅ Done | `src/data/entities/deployable_entities_data.lua` |
| 4 | **Station**: Implement the Assembly Station entity and its modal UI | ✅ Done | `src/evolved/behaviors/assembler_behavior.lua`, `src/ui/inventory_state_manager.lua` |
| 5 | **Logic**: Implement processing timers, mana deduction, and creature spawning | 🔄 In Progress | Processing system complete, creature spawning pending |

### Additional Progress

- ✅ **ECS Architecture**: Evolved-based entity system (`src/evolved/`)
- ✅ **Interaction System**: Proximity detection + mouse-based interaction (`src/evolved/systems/interaction_system.lua`)
- ✅ **Input System**: Player input handling (`src/evolved/systems/input_system.lua`)
- ✅ **UI System**: Toolbar rendering, inventory popups, item transfer (`src/evolved/systems/render_ui_system.lua`)
- ✅ **Inventory Fragment**: Reusable inventory logic (`src/evolved/fragments/inventory.lua`)
- ✅ **Processing System**: Behavior-based machine automation (`src/evolved/systems/processing_system.lua`)
- ✅ **Mana System**: Mana regeneration for entities (`src/evolved/systems/mana_system.lua`)
- ⬜ **Creature Spawning**: Spawning skeletons on ritual completion (pending)

## Core Gameplay Flow

1. **Material Acquisition**: Player interacts with a **Creative Chest** to get bones.
2. **Inventory Management**: Items are stored in a **Factorio-style toolbar** (10 slots).
3. **Station Interaction**: Player approaches an **Assembly Station** and opens its UI.
4. **Recipe Fulfillment**: Player inserts ingredients from their toolbar into the station.
5. **Ritual Initiation**: Player starts the ritual, consuming mana and time.
6. **Product Collection**: Station produces output items which can be collected.

---

## Entity Specifications

| Entity | Visual Representation | Size/Radius | Color (Placeholder) |
| :--- | :--- | :--- | :--- |
| **Player** | Circle | r = 16px | Blue |
| **Assembly Station** | Rectangle | 64 × 64px | Purple |
| **Bone** | Item Icon | 8 × 8px | White |
| **Essence** | Item Icon | 8 × 8px | Cyan |
| **Creative Chest** | Rectangle | 32 × 32px | Gold |
| **Skeleton** | Item Icon | 8 × 8px | Gray |

---

## Technical Architecture

### Project Structure

```
src/
├── config/              # Configuration files (colors, events, input bindings)
├── data/                # Static game data
│   ├── entities/        # Entity definitions (deployables, creatures)
│   ├── items/           # Item definitions (materials, creatures, deployables)
│   └── recipes_data.lua # Recipe definitions
├── evolved/             # Evolved ECS implementation
│   ├── behaviors/       # Machine behavior modules
│   ├── fragments/       # ECS components (inventory, recipe, state_machine)
│   ├── systems/         # ECS systems
│   ├── entities.lua     # Entity and prefab definitions
│   ├── fragments.lua    # Fragment definitions
│   └── systems.lua      # System loader
├── helpers/             # Utility functions
├── registries/          # Data lookup APIs
│   ├── entity_registry.lua
│   └── item_registry.lua
└── ui/                  # UI components
    ├── inventory_state_manager.lua
    └── inventory_view.lua
```

### 1. Data Layer (`src/data/`)

Static definitions for items, entities, and recipes. This allows easy balancing of mana costs and processing times.

- **Items**: Materials, creatures, deployables with stack sizes
- **Entities**: World-spawnable objects with visual/inventory configuration
- **Recipes**: Input/output definitions with mana costs and processing times

### 2. ECS Layer (`src/evolved/`)

Evolved-based entity-component-system architecture:

- **Fragments**: Data components attached to entities (Position, Inventory, Mana, etc.)
- **Tags**: Marker components for filtering (Processing, Interactable, Player)
- **Systems**: Logic that operates on entities with specific fragments
- **Behaviors**: State-specific logic for machine types (Assembler, etc.)

### 3. Registry Layer (`src/registries/`)

- **ItemRegistry**: Lookup items by ID, get max stack sizes
- **EntityRegistry**: Lookup entity data by ID, filter by class

### 4. UI Layer (`src/ui/`)

- **InventoryView**: Renders inventory slots with items
- **InventoryStateManager**: Manages inventory UI state, handles item transfers

---

## ECS Systems

| System | File | Purpose |
|:-------|:-----|:--------|
| Setup | `setup_systems.lua` | Spawns initial entities on game start |
| Input | `input_system.lua` | Handles player input, emits events |
| Interaction | `interaction_system.lua` | Detects entity interactions |
| Physics | `physics_system.lua` | Updates entity positions |
| Mana | `mana_system.lua` | Regenerates mana for entities |
| Processing | `processing_system.lua` | Runs machine behaviors |
| Render Entities | `render_entities_system.lua` | Draws entities |
| Render Debug | `render_debug_system.lua` | Draws debug information |
| Render UI | `render_ui_system.lua` | Draws inventory UI |

---

## Detailed UI Design

### Toolbar

- 10 slots visible at the bottom of the screen.
- Click to interact with items.
- Context-aware interaction based on the item in the slot.

### Assembly Station Popup

A modal window appearing on interaction:

- **Input Slots**: Visual slots for placing ingredients.
- **Output Slot**: Holds the finished product until collected by the player.
- **State Display**: Shows current machine state (idle, ready, working, etc.).

---

## Assembly Station State Machine

```
      [BLANK] ──set_recipe──► [IDLE] ◄─────────────┐
                                │                   │
                           prepare                  │
                                ▼                   │
                             [READY]                │
                                │                   │
                          start_ritual              │
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

## Implementation Roadmap

1. ✅ **Foundation**: Define materials, recipes, and mana system.
2. ✅ **Toolbar**: Implement the player toolbar and selection logic.
3. ✅ **Chest**: Create the Creative Chest for infinite bone supply.
4. ✅ **Station**: Implement the Assembly Station entity and behavior.
5. 🔄 **Logic**: Implement creature spawning on ritual completion.