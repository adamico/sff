# Project Roadmap & TODO

> **Last Updated:** 2025-01-11  
> **Current Focus:** Complete MVP Gameplay Loop  
> **Architecture:** Evolved ECS (migrated from Nata)

## 🔴 CRITICAL: MVP Completion (Blocks Viability Testing)

**Goal:** Test if "creature production → deploy → harvest → recycle" is engaging.

- [x] **Processing System**:
    - [x] Behavior-based architecture (`src/evolved/behaviors/`)
    - [x] Assembler behavior with full state machine (blank → idle → ready → working → complete)
    - [x] Ingredient detection, consumption on completion
    - [x] Output production with stacking support
    - [x] Mana consumption per tick during working state
    - [x] NO_MANA and BLOCKED state handling
- [x] **Mana System**:
    - [x] Mana fragment with current/max/regen_rate
    - [x] Mana regeneration system (`src/evolved/systems/mana_system.lua`)
    - [x] Mana consumption during processing
- [ ] **Ritual System**:
    - [ ] Start Ritual button in the machine UI
    - [ ] Player must stay in range of the machine (optional for MVP)
- [ ] **Creature Spawning**:
    - [ ] Manually deploy (spawn) assembled creature items using `EntityRegistry` to spawn `Skeleton`
- [ ] **Deployment System**:
    - [ ] Create `PlacementSystem` with ghost preview rendering
    - [ ] Implement collision detection (red=blocked, green=valid)
    - [ ] Connect toolbar item click → spawn entity in world
    - [ ] Handle creature vs building placement (no grid snap for creatures)
- [ ] **Harvest Mechanic**:
    - [ ] Add interaction to deployed creatures (click skeleton → harvest action)
    - [ ] Implement harvest timer using `harvest_time` from creature data
    - [ ] Grant `harvest_yield` mana to global pool on completion
    - [ ] Remove creature entity after harvest
- [ ] **Recycling Loop**:
    - [ ] Add "recycle" interaction option for deployed creatures (click skeleton → recycle action)
    - [ ] Return materials based on `recycle_returns` in creature data
    - [ ] Test economic balance: can players sustain production?

## 🟡 HIGH: Processing System UI (Players Can't See Working Systems)

- [ ] **Progress Visualization**:
    - [x] Add progress bar to `Assembler` UI showing `processingTimer` progress
    - [ ] Color-code by state (WORKING, NO_MANA, BLOCKED)
    - [x] Display current FSM state label
- [ ] **Resource Displays**:
    - [ ] Show mana consumption rate in station UI
    - [x] Show current/max mana in machine inventory view
- [ ] **Recipe Preview**:
    - [ ] Show ingredient requirements vs current amounts
    - [ ] Display expected outputs before starting processing
    - [ ] Show total mana cost (mana_per_tick × processing_time)
- [ ] **Ritual Visualization**:
    - [ ] A visual representation of the ritual process (e.g., a circle with segments representing progress)

## 🟢 MEDIUM: Inventory & UX Polish

- [x] **Machine State Display**:
    - [x] InventoryView queries entity state via entityId
    - [x] State displayed in machine inventory UI
- [ ] **Advanced Interactions**:
    - [ ] Right-click split stack (pick up half)
    - [ ] Shift-click transfer between inventories
- [ ] **Item Tooltips**:
    - [ ] Create tooltip component for hover display
    - [ ] Show item name, description, stack size

## 🔵 LOWER: Technical Debt & Refactoring

- [x] **ECS Migration**:
    - [x] Migrated from Nata to Evolved ECS
    - [x] Removed old entities, components, systems folders
    - [x] Simplified registries (removed deployable_registry, registry aggregator)
- [ ] **Asset Loading**:
    - [ ] Replace `string.sub(item_id, 1, 1)` rendering with sprite system
    - [ ] Add proper icon support to item registry
- [ ] **Registry Validation**:
    - [ ] Startup checks: deployable items have entity definitions
    - [ ] Validate recipe references to materials/creatures
- [ ] **Configuration Extraction**:
    - [ ] Move UI layout constants to `src/config/inventory_layout.lua`
    - [ ] Centralize color schemes and styling

## ⚪ FUTURE: Post-MVP Features

- [ ] **Save/Load System**: Preserve `processingTimer`, `currentRecipe`, inventory states
- [ ] **Multiple Creature Types**: Test recipe variety after core loop validated
- [ ] **Automation Buildings**: Conveyors, pipes (only if manual loop is fun)
- [ ] **Global Mana Pool**: Currently machines use local mana; extend system if needed


## Architecture Notes

### Evolved ECS Structure
```
src/evolved/
├── behaviors/           # Machine behavior modules (per class)
│   ├── init.lua         # Behavior registry
│   └── assembler_behavior.lua
├── fragments/           # Reusable fragment modules
│   ├── inventory.lua
│   ├── recipe.lua
│   └── state_machine.lua
├── systems/             # ECS systems
│   ├── setup_systems.lua
│   ├── input_system.lua
│   ├── interaction_system.lua
│   ├── mana_system.lua
│   ├── physics_system.lua
│   ├── processing_system.lua
│   ├── render_entities_system.lua
│   ├── render_debug_system.lua
│   └── render_ui_system.lua
├── entities.lua         # ENTITIES and PREFABS definitions
├── fragments.lua        # FRAGMENTS and TAGS definitions
└── systems.lua          # System loader
```

## To Process

- Machines should have a more complex visual representation. Minecraft modding does this by using an entity screen which can contain more detailed information about the machine's state, progress, inventory slots etc.
- Initial recipe assignment is currently hardcoded in assembler behavior - should be set via UI or entity data
