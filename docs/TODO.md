# Project Roadmap & TODO

> **Last Updated:** 2025-01-08  
> **Current Focus:** Inventory Polish & Deployment Systems

## 1. Inventory & Item Systems (High Priority)

- [x] **Max Stack Size Enforcement**: Integrate `InventoryHelper.getMaxStackQuantity()` into `InventoryComponent:addItem()` to prevent over-stacking during automated transfers.
- [ ] **Item Registry Expansion**:
    - [ ] Add `icon` sprites to `item_data` files.
- [ ] **Advanced Interactions**:
    - [ ] **Right-Click Split**: Implement logic in `InventoryStateManager` to pick up half a stack.
    - [ ] **Shift-Click Transfer**: Implement quick-move between player inventory and open storage views.
    - [ ] **Item Tooltips**: Create a UI component to display item name and description on hover in the inventory.

## 2. Deployment System (The "Next Big Step")

- [ ] **Deployment Preview**:
    - [ ] Create a `PlacementSystem` that renders a "ghost" of the entity at the mouse position when a deployable item is held.
    - [ ] Implement collision checking for the preview (red ghost if blocked, green if clear).
- [ ] **Spawn Logic**:
    - [ ] Implement `World:spawnEntity(entity_id, x, y)` using `EntityRegistry`.
    - [ ] Connect `INPUT_INVENTORY_CLICK` (outside of UI bounds) to trigger deployment if a deployable item is held.
- [ ] **Creature Spawning**: Ensure the deployment system handles `Creature` class entities (Skeletons) differently than `Buildings` (no grid snapping, different spawn effects).

## 3. ECS & Entity Logic

- [ ] **Unified Entity Factory**: Create a central factory that uses `EntityRegistry` to attach correct components (Inventory, Interaction, Health) based on the entity's `class` and `data`.
- [ ] **Assembler Logic**:
    - [ ] Implement recipe processing timers.
    - [ ] Implement "Input" vs "Output" slot filtering (assemblers should only allow specific items in input slots).

## 4. UI/UX Improvements

- [ ] **Slot Highlighting**: Add visual feedback in `DrawHelper` when hovering over a valid slot.
- [ ] **Inventory Animations**: Add slight offsets or scaling when picking up/dropping items.
- [ ] **Configuration Extraction**: Move hardcoded layout constants from `UISystem` to `src/config/inventory_layout.lua`.
- [ ] **Draggable Windows**: Allow `InventoryView` instances to be moved around the screen.

## 5. Technical Debt & Refactoring

- [ ] **Registry Validation**: Add startup checks to ensure every `deployable` Item has a matching entry in the `EntityRegistry`.
- [ ] **Resource Management**: Implement a proper Asset Loader for sprites and fonts to replace the placeholder `string.sub(item_id, 1, 1)` rendering.
- [ ] **Event Cleanup**: Audit `Events.lua` to ensure consistent naming conventions across the growing system.

## Future Exploration

- [ ] **Save/Load System**: Serialize the state of all deployed entities and player inventory.
