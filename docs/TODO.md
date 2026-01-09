# Project Roadmap & TODO

> **Last Updated:** 2025-01-08  
> **Current Focus:** Complete MVP Gameplay Loop

## 🔴 CRITICAL: MVP Completion (Blocks Viability Testing)

**Goal:** Test if "creature production → deploy → harvest → recycle" is engaging.

- [ ] **Ritual System**:
    - [ ] A ritual component needs to be implemented (name, mana cost, duration)
    - [ ] For the MVP the ritual system will be simplified (Start Ritual button in the machine UI, player must stay in range of the machine)
- [ ] **Mana System**:
    - [ ] Implement mana pool manager:
        - [ ] Initialize mana pool with a certain amount of mana (from data)
        - [ ] Implement slow mana pool regeneration (will be replaced or improved by more complex mana generation systems)
        - [ ] Implement mana consumption for starting rituals
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
    - [ ] Add progress bar to `Assembler` UI showing `processingTimer` progress
    - [ ] Color-code by state (WORKING, NO_MANA, BLOCKED)
    - [ ] Display current FSM state label
- [ ] **Resource Displays**:
    - [ ] Show mana consumption rate in station UI
    - [ ] Show current/max mana in machine inventory view
    - [ ] Show ingredient requirements vs current amounts
- [ ] **Recipe Preview**:
    - [ ] Display expected outputs before starting processing
    - [ ] Show total mana cost (mana_per_tick × processing_time)
- [ ] **Ritual Visualization**:
    - [ ] A visual representation of the ritual process (e.g., a circle with segments representing progress)

## 🟢 MEDIUM: Inventory & UX Polish

- [ ] **Draggable Windows**:
    - [ ] Make `InventoryView` instances independently draggable
    - [ ] Remove `total_width` constraint from layout
- [ ] **Advanced Interactions**:
    - [ ] Right-click split stack (pick up half)
    - [ ] Shift-click transfer between inventories
- [ ] **Item Tooltips**:
    - [ ] Create tooltip component for hover display
    - [ ] Show item name, description, stack size

## 🔵 LOWER: Technical Debt & Refactoring

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
