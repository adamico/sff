# Evolved ECS Structure

This directory contains the Entity Component System (ECS) configuration for the game using the Evolved library.

## Directory Structure

```
src/evolved/
├── README.md              # This file
├── evolved_config.lua     # Main configuration and exports
├── fragments.lua          # Component definitions (data)
├── tags.lua              # Entity type markers
├── systems.lua           # System loader (behavior)
├── behaviors/            # Reusable behavior definitions
├── fragments/            # Complex fragment implementations
├── systems/              # Individual system implementations
└── utils/                # Utility functions
    └── duplication.lua   # Cloning/duplication helpers
```

## File Purposes

### `evolved_config.lua`

Central configuration hub that exports:

- **STAGES**: Lifecycle stages (OnSetup, OnUpdate, OnRenderEntities)
- **UNIFORMS**: Global singleton values (DeltaTime, ShowHitboxes)
- **FRAGMENTS**: Empty table populated by fragments.lua
- **TAGS**: Empty table populated by tags.lua
- **ENTITIES**: Empty table populated at runtime by systems

### `fragments.lua`

Defines all ECS fragments (data components) organized by category:

- **Visual Components**: Color, Shape, Size
- **Physics Components**: Position, Velocity, MaxSpeed, Hitbox
- **Input & Control**: Input, InputQueue
- **Inventory & Storage**: Inventory, Toolbar
- **Machine & Processing**: MachineClass, CurrentRecipe, ValidRecipes, ProcessingTimer, StateMachine
- **Resource Components**: Mana
- **Interaction Components**: InteractionRange, Interaction

### `tags.lua`

Defines entity type markers with required fragments:

- **Controllable**: Entities that accept player input
- **Interactable**: Entities that can be interacted with
- **Player**: The player entity
- **Physical**: Entities with physics (position, velocity, collision)
- **Animated**: Entities with peachy-based animated sprites
- **Static**: Entities with simple quad-based static sprites

### `systems.lua`

Loads all system modules in execution order:

**Setup Stage:**

- setup_systems - Initialize world state
- spawner_system - Create entities from data

**Update Stage:**

- input_system - Process player input
- interaction_system - Handle entity interactions
- mana_system - Update resource regeneration
- processing_system - Process machine recipes
- physics_system - Update movement
- collision_system - Handle collisions

**Render Stage:**

- render_ui_system - Draw UI elements
- render_debug_system - Draw debug info
- render_hitboxes_system - Draw collision boxes

### `utils/duplication.lua`

Helper functions for cloning data:

- `duplicateVector(vector)` - Clone Vector objects
- `clone(table)` - Shallow array clone
- `deepClone(value)` - Recursive deep clone with metatable preservation

## Load Order

The files **must** be loaded in this order (handled by `main.lua`):

1. `evolved_config.lua` - Initialize structure
2. `fragments.lua` - Define components
3. `tags.lua` - Define entity types (requires fragments)
4. `systems.lua` - Load systems (requires fragments and tags)

## Usage

### Accessing in Code

All ECS elements are exported as globals from `main.lua`:

```lua
-- Components
local entity = spawn()
set(entity, FRAGMENTS.Position, Vector(100, 100))
set(entity, FRAGMENTS.Velocity, Vector(0, 0))

-- Tags
add(entity, TAGS.Physical)
add(entity, TAGS.Animated)

-- Uniforms
local dt = UNIFORMS.getDeltaTime()
UNIFORMS.setShowHitboxes(false)

-- Stages
process(STAGES.OnUpdate)

-- Entities
local player = ENTITIES.player
```

### Adding New Fragments

1. Add the fragment definition to `fragments.lua` in the appropriate category:

```lua
NewFragment = builder()
   :name("FRAGMENTS.NewFragment")
   :default(defaultValue)
   :duplicate(duplication.deepClone) -- if needed
   :build(),
```

1. If the fragment requires custom duplication logic, add it to `utils/duplication.lua`

### Adding New Tags

1. Add the tag definition to `tags.lua`:

```lua
NewTag = builder()
   :name("TAGS.NewTag")
   :tag()
   :require(FRAGMENTS.RequiredFragment) -- optional
   :build(),
```

### Adding New Systems

1. Create the system file in `systems/` directory
2. Add the require statement to `systems.lua` in the appropriate stage section

### Adding New Uniforms

1. Edit `evolved_config.lua` and use the `createUniform` helper:

```lua
local MyUniform = createUniform("UNIFORMS.MyUniform", defaultValue)

-- Add to UNIFORMS table:
evolvedConfig.UNIFORMS = {
   -- ... existing uniforms ...
   MyUniform = MyUniform.fragment,
   getMyUniform = MyUniform.get,
   setMyUniform = MyUniform.set,
}
```

## Design Principles

1. **Separation of Concerns**: Data (fragments) separate from types (tags) separate from behavior (systems)
2. **Clear Dependencies**: Load order enforced through file structure and documentation
3. **DRY**: Helper functions extracted to utilities; uniform creation automated
4. **Discoverability**: Clear categorization and comments make finding things easy
5. **Scalability**: Easy to add new fragments, tags, or systems following established patterns

## Migration Notes

### Changes from Previous Structure

- **Removed `entities.lua`**: Was nearly empty; ENTITIES now initialized in evolved_config.lua
- **Split fragments and tags**: Previously mixed in one file, now separate for clarity
- **Extracted utilities**: Duplication helpers moved to `utils/duplication.lua`
- **Documented systems**: Added execution order and stage information
- **Organized fragments**: Grouped by category with clear section headers

### Breaking Changes

None - the public API (global FRAGMENTS, TAGS, ENTITIES, UNIFORMS, STAGES) remains the same.
