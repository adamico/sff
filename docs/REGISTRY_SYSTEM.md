# Registry System

> **Last Updated:** 2026-01-13

Centralized lookups for items (inventory) and entities (world objects).

---

## Structure

```
src/
├── data/
│   ├── entities/
│   │   ├── init.lua                    # Merges categories
│   │   ├── deployable_entities_data.lua
│   │   └── creature_entities_data.lua
│   ├── items/
│   │   ├── init.lua
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

### Properties

```lua
{
   id = "bone",
   name = "Bone",
   max_stack_size = 64,
   deployable = false,
}
```

### API

| Method | Returns |
|:-------|:--------|
| `getItem(item_id)` | Full item data |
| `getMaxStackSize(item_id)` | Stack limit (default 64) |
| `exists(item_id)` | Boolean |
| `getAll()` | All items |

---

## Entity Registry

**File:** `src/registries/entity_registry.lua`

### Properties

```lua
{
   id = "SkeletonAssembler",
   class = "Assembler",
   name = "Skeleton Assembler",
   color = Colors.PURPLE,
   size = Vector(64, 64),
   events = { ... },
   inventory = { ... },
   mana = { ... },
   valid_recipes = { ... },
}
```

### API

| Method | Returns |
|:-------|:--------|
| `getEntity(entity_id)` | Entity data |
| `exists(entity_id)` | Boolean |
| `getEntitiesByClass(class)` | Filtered entities |
| `getAll()` | All entities |

---

## Item ↔ Entity Link

Deployable items share ID with their entity counterpart:

1. Player has item `skeleton_assembler`
2. Item has `deployable = true`
3. System calls `EntityRegistry.getEntity("skeleton_assembler")`
4. Spawns world entity

---

## Scaling

- Keep files under ~100 items each
- Add new category files to `init.lua`
- IDs are auto-checked for duplicates
