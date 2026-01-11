# Registry System Documentation

> **Last Updated:** 2025-01-11  
> **Status:** ✅ Simplified for Evolved ECS

## Overview

The Registry System provides a centralized way to look up game data for items and entities. It separates the **inventory representation** (Items) from the **world representation** (Entities), allowing for flexible game mechanics like deploying buildings or spawning creatures from inventory stacks.

## Architecture

The system is built on a two-tier data structure:
1. **Raw Data Layer**: Static Lua tables organized by category.
2. **Registry Layer**: Functional APIs that provide lookups and helper methods.

```
src/
├── data/
│   ├── entities/
│   │   ├── init.lua                    # Merges all entity categories
│   │   ├── deployable_entities_data.lua
│   │   └── creature_entities_data.lua
│   ├── items/
│   │   ├── init.lua                    # Merges all item categories
│   │   ├── material_items_data.lua
│   │   ├── creature_items_data.lua
│   │   └── deployable_items_data.lua
│   └── recipes_data.lua
└── registries/
    ├── item_registry.lua
    └── entity_registry.lua
```

---

## Item Registry

**File:** `src/registries/item_registry.lua`

Manages everything that can exist inside an inventory slot.

### Data Source

Items are loaded from `src/data/items/`, which merges:
- `material_items_data.lua` - Basic resources (Bone, Essence, Wood)
- `creature_items_data.lua` - Inventory form of living entities
- `deployable_items_data.lua` - Inventory form of buildings and machines

### Item Properties

```lua
{
   id = "bone",           -- Unique identifier (auto-set by init.lua)
   name = "Bone",         -- Display name
   max_stack_size = 64,   -- Maximum quantity per slot (default: 64)
   deployable = false,    -- Can be placed in the world
}
```

### API

#### `ItemRegistry.getItem(item_id)`
Returns the full item data table.
```lua
local item = ItemRegistry.getItem("bone")
-- { id = "bone", name = "Bone", max_stack_size = 64, ... }
```

#### `ItemRegistry.getMaxStackSize(item_id)`
Returns the stack limit, defaulting to 64 if not defined.
```lua
local max = ItemRegistry.getMaxStackSize("essence") -- 16
```

#### `ItemRegistry.exists(item_id)`
Returns true if the item exists in the registry.
```lua
if ItemRegistry.exists("bone") then
   -- item is valid
end
```

#### `ItemRegistry.getAll()`
Returns all registered items.
```lua
local allItems = ItemRegistry.getAll()
```

---

## Entity Registry

**File:** `src/registries/entity_registry.lua`

Manages properties for objects that can be spawned in the game world.

### Data Source

Entities are loaded from `src/data/entities/`, which merges:
- `deployable_entities_data.lua` - Assemblers, Storages, Buildings
- `creature_entities_data.lua` - Skeletons and other NPCs

### Entity Properties

```lua
{
   id = "SkeletonAssembler",  -- Unique identifier (auto-set by init.lua)
   class = "Assembler",       -- Machine class for behavior lookup
   name = "Skeleton Assembler",
   color = Colors.PURPLE,
   size = Vector(64, 64),
   events = { ... },          -- FSM state transitions
   inventory = { ... },       -- Inventory configuration
   mana = { ... },            -- Mana configuration
   valid_recipes = { ... },   -- Available recipes
}
```

### API

#### `EntityRegistry.getEntity(entity_id)`
Returns the world-space configuration for an entity.
```lua
local data = EntityRegistry.getEntity("SkeletonAssembler")
-- { class = "Assembler", size = Vector(64, 64), ... }
```

#### `EntityRegistry.exists(entity_id)`
Returns true if the entity exists in the registry.
```lua
if EntityRegistry.exists("SkeletonAssembler") then
   -- entity is valid
end
```

#### `EntityRegistry.getEntitiesByClass(class_name)`
Returns all entities belonging to a specific class.
```lua
local assemblers = EntityRegistry.getEntitiesByClass("Assembler")
-- { SkeletonAssembler = {...}, IronAssembler = {...} }
```

#### `EntityRegistry.getAll()`
Returns all registered entities.
```lua
local allEntities = EntityRegistry.getAll()
```

---

## Item ↔ Entity Linkage

Items and Entities can be linked by a **shared ID** for deployable items:

1. **Inventory**: Player has an item with ID `skeleton_assembler`
2. **Lookup**: `ItemRegistry.getItem("skeleton_assembler")` shows `deployable = true`
3. **Deployment**: System calls `EntityRegistry.getEntity("skeleton_assembler")`
4. **Spawning**: Game uses entity data to create a world object

---

## Usage with Evolved ECS

### In Behavior Modules

The `ItemRegistry` is used in machine behaviors for stack size limits:

```lua
-- src/evolved/behaviors/assembler_behavior.lua
local ItemRegistry = require("src.registries.item_registry")

local function produceOutputs(recipe, inventory)
   for output_id, amount in pairs(recipe.outputs) do
      local maxStack = ItemRegistry.getMaxStackSize(output_id)
      -- ... stacking logic
   end
end
```

### In Setup Systems

The `EntityRegistry` can be used for dynamic entity spawning:

```lua
-- Example: spawning from entity data
local EntityRegistry = require("src.registries.entity_registry")

local function spawnEntity(entity_id, x, y)
   local data = EntityRegistry.getEntity(entity_id)
   if not data then return nil end
   
   return clone(PREFABS[data.class], {
      [FRAGMENTS.Position] = Vector(x, y),
      -- ... configure from data
   })
end
```

---

## Scaling Strategy

To maintain a project with hundreds of items without creating "mega-files":

1. **Split by Category**: Keep files under 100 items each
   - `ore_items_data.lua`
   - `gem_items_data.lua`
   - `weapon_items_data.lua`

2. **Register in Init**: Add the new file to the `categories` table:
   ```lua
   -- src/data/items/init.lua
   local categories = {
      require("src.data.items.material_items_data"),
      require("src.data.items.creature_items_data"),
      require("src.data.items.deployable_items_data"),
      require("src.data.items.ore_items_data"),  -- New category
   }
   ```

3. **Unique IDs**: The `init.lua` scripts automatically check for duplicate IDs and throw an error if a collision is found.

---

## Summary

| Registry | File | Purpose |
|:---------|:-----|:--------|
| ItemRegistry | `src/registries/item_registry.lua` | Item lookups, max stack sizes |
| EntityRegistry | `src/registries/entity_registry.lua` | Entity data for spawning, class filtering |