# Registry System Documentation

> **Last Updated:** 2025-01-08  
> **Status:** ✅ Core Implementation Complete

## Overview

The Registry System provides a centralized, scalable way to manage game data for items and entities. It separates the **inventory representation** (Items) from the **world representation** (Entities), allowing for flexible game mechanics like deploying buildings or spawning creatures from inventory stacks.

## Architecture

The system is built on a two-tier data structure:
1. **Raw Data Layer**: Static Lua tables organized by category and form.
2. **Registry Layer**: Functional APIs that provide lookups, merging, and helper methods.

### 1. Item Registry (`src/data/items/`)

Manages everything that can exist inside an inventory slot.

| Category | File | Description |
|:---|:---|:---|
| **Materials** | `material_items_data.lua` | Basic resources (Bone, Essence, Wood). |
| **Creatures** | `creature_items_data.lua` | Inventory form of living entities. |
| **Deployables** | `deployable_items_data.lua` | Inventory form of buildings and machines. |
| **Index** | `init.lua` | Merges all categories into a single flat table. |

**Item Properties:**
- `id`: Unique identifier (e.g., "skeleton_assembler").
- `name`: Display name.
- `max_stack_size`: Maximum quantity per slot.
- `deployable`: Boolean flag indicating if it can be placed in the world.

---

### 2. Entity Registry (`src/data/entities/`)

Manages the properties used when an object is spawned in the game world.

| Category | File | Description |
|:---|:---|:---|
| **Deployables** | `deployable_entities_data.lua` | Data for Assemblers, Storages, and Buildings. |
| **Creatures** | `creature_entities_data.lua` | Data for Skeletons and other NPCs. |
| **Index** | `init.lua` | Merges all categories into a single flat table. |

**Entity Properties:**
- `class`: The logic class to instantiate (e.g., "Assembler").
- `size`: Collision and visual dimensions.
- `visual`: Sprite or primitive shape configuration.
- `components`: Configuration for ECS components (Inventory, Health, etc.).

---

## Data Flow: Item ↔ Entity Linkage

Items and Entities are linked by their **Shared ID**.

1. **Inventory**: You have an item with ID `skeleton`.
2. **Lookup**: `ItemRegistry.getItem("skeleton")` shows `deployable = true`.
3. **Deployment**: When the player clicks the ground, the system calls `EntityRegistry.getEntity("skeleton")`.
4. **Spawning**: The game uses the entity data (size, class, visual) to create a world object.

---

## API Reference

### ItemRegistry (`src/registries/item_registry.lua`)

#### `getItem(item_id)`
Returns the full item data table.
```lua
local item = ItemRegistry.getItem("bone")
-- { id = "bone", name = "Bone", max_stack_size = 64, ... }
```

#### `getMaxStackSize(item_id)`
Returns the stack limit, falling back to a default (usually 64) if not defined.
```lua
local max = ItemRegistry.getMaxStackSize("essence") -- 16
```

---

### EntityRegistry (`src/registries/entity_registry.lua`)

#### `getEntity(entity_id)`
Returns the world-space configuration for an ID.
```lua
local data = EntityRegistry.getEntity("skeleton_assembler")
-- { class = "Assembler", size = Vector(64, 64), ... }
```

#### `getEntitiesByClass(class_name)`
Returns a filtered list of all entities belonging to a specific class (e.g., all "Storage").

---

## Scaling Strategy

To maintain a project with hundreds of items without creating "mega-files":

1. **Split by Category**: Keep files under 100 items each (e.g., `ore_items_data.lua`, `gem_items_data.lua`).
2. **Register in Init**: Add the new file to the `categories` table in `src/data/items/init.lua`.
3. **Unique IDs**: The `init.lua` scripts automatically check for duplicate IDs across all files and will throw an error if a collision is found.

## Usage Example

```lua
local Registry = require("src.registries.registry")

-- Checking if we can stack more items
function canAddMore(slot, incoming_id)
    local max = Registry.ItemRegistry.getMaxStackSize(incoming_id)
    return slot.quantity < max
end

-- Spawning an entity from an item
function deployItem(item_id, x, y)
    local item = Registry.ItemRegistry.getItem(item_id)
    if item and item.deployable then
        local entity_data = Registry.EntityRegistry.getEntity(item_id)
        World:spawn(entity_data, x, y)
    end
end
```
