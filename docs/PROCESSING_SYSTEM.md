# Processing System

A generic system for managing machine automation using the Evolved ECS architecture. Handles state transitions, processing timers, and cycling for any machine type with varying requirements.

## Overview

The Processing System manages the lifecycle of any machine that processes recipes:

1. **Detect ingredients** in input slots (if required by recipe)
2. **Start processing** with timer countdown
3. **Consume mana** per tick during processing (if required by recipe)
4. **Consume ingredients** on completion (not on start)
5. **Produce outputs** with stacking support
6. **Auto-restart** if more ingredients available

## Resource Consumption Model

| Resource | When Consumed | On Interrupt |
|:---------|:--------------|:-------------|
| Ingredients | On COMPLETE | Not consumed yet, no refund needed |
| Mana | Per tick during WORKING | Stops draining, resumes when refueled |

This model is player-friendly:
- Changing recipe mid-cycle doesn't lose ingredients
- Stealing ingredients stops the machine (no punishment)
- Mana drain is predictable and recoverable

## Architecture

The processing system uses a **behavior-based architecture** where each machine class has its own behavior module:

```
src/evolved/
├── behaviors/
│   ├── init.lua              # Behavior registry
│   └── assembler_behavior.lua # Assembler-specific logic
├── systems/
│   ├── processing_system.lua # Main system (dispatches to behaviors)
│   └── mana_system.lua       # Mana regeneration
└── fragments.lua             # ECS components (Mana, ProcessingTimer, etc.)
```

### Key Components

| Component | File | Purpose |
|:----------|:-----|:--------|
| Processing System | `src/evolved/systems/processing_system.lua` | Iterates entities, builds context, dispatches to behaviors |
| Behavior Registry | `src/evolved/behaviors/init.lua` | Maps machine class names to behavior modules |
| Assembler Behavior | `src/evolved/behaviors/assembler_behavior.lua` | State-specific logic for Assembler machines |
| Mana System | `src/evolved/systems/mana_system.lua` | Regenerates mana for entities with Mana fragment |

### ECS Fragments

Machines require these fragments (defined in `src/evolved/fragments.lua`):

| Fragment | Type | Description |
|:---------|:-----|:------------|
| `MachineClass` | string | Machine type (e.g., "Assembler") - used to look up behavior |
| `CurrentRecipe` | table | Active recipe data |
| `StateMachine` | table | FSM instance with current state and transitions |
| `Mana` | table | `{current, max, regen_rate}` |
| `ProcessingTimer` | table | `{current, saved}` for timing and pause/resume |
| `Inventory` | table | Input/output slots |
| `ValidRecipes` | table | Array of recipes this machine can process |

## State Machines

### Assembler FSM

Assemblers use mana and rituals to process recipes with ingredients.

```
         ┌──────────────────────────────────────────┐
         │                                          │
         ▼                                          │
      [BLANK] ──set_recipe──► [IDLE] ◄─────────────┘
                                │  ▲                │
                           prepare  complete        │
                                ▼  │                │
                             [READY]                │
                                │                   │
                          start_ritual              │
                                │                   │
                                ▼                   │
     [NO_MANA] ◄───starve─── [WORKING] ───block───► [BLOCKED]
         │                      ▲  │                    │
         │                      │  │ stop               │
         └───────refuel─────────┘  │ (ingredients       │
                                   │  missing)          │
                                   ▼                    │
                               [IDLE] ◄────unblock──────┘
```

**States:**
- `blank` - No recipe set
- `idle` - Recipe set, waiting for ingredients
- `ready` - Has ingredients, ready to start ritual
- `working` - Processing in progress, consuming mana per tick
- `blocked` - Output slots full
- `no_mana` - Mana depleted mid-cycle (preserves timer)

**Transitions:**
```lua
{name = "set_recipe",         from = "blank",   to = "idle"},
{name = "prepare",            from = "idle",    to = "ready"},
{name = "remove_ingredients", from = "ready",   to = "idle"},
{name = "start_ritual",       from = "ready",   to = "working"},
{name = "stop_ritual",        from = "working", to = "idle"},
{name = "complete",           from = "working", to = "idle"},
{name = "stop",               from = "working", to = "idle"},
{name = "block",              from = "working", to = "blocked"},
{name = "unblock",            from = "blocked", to = "idle"},
{name = "starve",             from = "working", to = "no_mana"},
{name = "refuel",             from = "no_mana", to = "working"},
```

## Behavior System

### Context Object

The processing system builds a context object for each machine and passes it to the behavior:

```lua
local context = {
   machineId = number,           -- Entity ID
   machineName = string,         -- Display name for logging
   fsm = table,                  -- State machine instance
   recipe = table,               -- Current recipe
   inventory = table,            -- Machine inventory
   mana = table,                 -- {current, max, regen_rate}
   processingTimer = table,      -- {current, saved}
   dt = number,                  -- Delta time
}
```

### Behavior Module Structure

Each behavior module exports state handler functions and an `update()` dispatcher:

```lua
local Assembler = {}

function Assembler.blank(context)
   -- Handle blank state
end

function Assembler.idle(context)
   -- Handle idle state
end

function Assembler.ready(context)
   -- Handle ready state
end

function Assembler.working(context)
   -- Handle working state (timer, mana, completion)
end

function Assembler.blocked(context)
   -- Handle blocked state
end

function Assembler.no_mana(context)
   -- Handle no_mana state
end

function Assembler.update(context)
   local state = context.fsm.current
   local behavior = Assembler[state]
   if behavior then
      behavior(context)
   end
end

return Assembler
```

### Behavior Registry

Behaviors are registered in `src/evolved/behaviors/init.lua`:

```lua
local Behaviors = {}
local registry = {}

function Behaviors.register(className, behaviorModule)
   registry[className] = behaviorModule
end

function Behaviors.get(className)
   return registry[className]
end

-- Register built-in behaviors
Behaviors.register("Assembler", require("src.evolved.behaviors.assembler_behavior"))

return Behaviors
```

## Recipe Format

```lua
return {
   create_skeleton = {
      name = "Create Skeleton",
      category = "creature_creation",
      
      -- Ingredients (consumed on complete)
      inputs = {
         bone = 2,
         essence = 1,
      },
      
      -- Outputs (with stacking support)
      outputs = {
         skeleton = 1,
      },
      
      -- Optional: chance-based bonus outputs
      output_chances = {
         bonus_bone = 0.1,  -- 10% chance
      },
      
      -- Mana consumed per second during WORKING
      mana_per_tick = 2,
      
      -- Processing duration in seconds
      processing_time = 5,
      
      -- Optional: requires ritual transition (for assemblers)
      requires_ritual = true,
   },
}
```

## Entity Setup

### Prefab Definition (`src/evolved/entities.lua`)

```lua
evolved_config.PREFABS = {
   Assembler = builder()
      :name("PREFABS.Assembler")
      :prefab()
      :set(FRAGMENTS.Color, Colors.PURPLE)
      :set(FRAGMENTS.Inventory, Inventory.new())
      :set(FRAGMENTS.MachineClass, "Assembler")
      :set(FRAGMENTS.Mana, {current = 0, max = 100, regen_rate = 1})
      :set(FRAGMENTS.ProcessingTimer, {current = 0, saved = 0})
      :set(FRAGMENTS.StateMachine, StateMachine.new())
      :set(TAGS.Interactable)
      :set(TAGS.Physical)
      :set(TAGS.Visual)
      :set(TAGS.Processing)
      :build(),
}
```

### Entity Data (`src/data/entities/deployable_entities_data.lua`)

```lua
SkeletonAssembler = {
   class = "Assembler",
   color = Colors.PURPLE,
   events = {
      {name = "set_recipe",         from = "blank",   to = "idle"},
      {name = "prepare",            from = "idle",    to = "ready"},
      -- ... more events
   },
   inventory = {
      max_input_slots = 2,
      max_output_slots = 1,
   },
   mana = {
      current = 10,
      max = 100,
      regen_rate = 1,
   },
   valid_recipes = {Recipes.create_skeleton},
},
```

### Spawning (`src/evolved/systems/setup_systems.lua`)

```lua
clone(PREFABS.Assembler, {
   [Evolved.NAME] = "SkeletonAssembler",
   [FRAGMENTS.Inventory] = Inventory.new(skeletonAssemblerData.inventory),
   [FRAGMENTS.Mana] = {
      current = skeletonAssemblerData.mana.current,
      max = skeletonAssemblerData.mana.max,
      regen_rate = skeletonAssemblerData.mana.regen_rate,
   },
   [FRAGMENTS.ProcessingTimer] = {current = 0, saved = 0},
   [FRAGMENTS.StateMachine] = StateMachine.new({events = skeletonAssemblerData.events}),
   [FRAGMENTS.ValidRecipes] = skeletonAssemblerData.valid_recipes,
})
```

## Mana System

Mana regenerates automatically via `src/evolved/systems/mana_system.lua`:

```lua
builder()
   :name("SYSTEMS.Mana")
   :group(STAGES.OnUpdate)
   :include(FRAGMENTS.Mana)
   :execute(function(chunk, _, entityCount)
      local manas = chunk:components(FRAGMENTS.Mana)
      local dt = UNIFORMS.getDeltaTime()

      for i = 1, entityCount do
         local mana = manas[i]
         local regenRate = mana.regen_rate or 0

         if regenRate > 0 and mana.current < mana.max then
            mana.current = math.min(mana.current + regenRate * dt, mana.max)
         end
      end
   end):build()
```

## Adding New Machine Types

1. **Create the behavior module** (`src/evolved/behaviors/furnace_behavior.lua`):

```lua
local Furnace = {}

function Furnace.idle(context)
   -- Furnace-specific idle logic
end

function Furnace.smelting(context)
   -- Furnace-specific processing logic
end

function Furnace.update(context)
   local state = context.fsm.current
   local behavior = Furnace[state]
   if behavior then behavior(context) end
end

return Furnace
```

2. **Register the behavior** (`src/evolved/behaviors/init.lua`):

```lua
Behaviors.register("Furnace", require("src.evolved.behaviors.furnace_behavior"))
```

3. **Create a prefab** (`src/evolved/entities.lua`):

```lua
Furnace = builder()
   :name("PREFABS.Furnace")
   :prefab()
   :set(FRAGMENTS.MachineClass, "Furnace")
   -- ... other fragments
   :build(),
```

4. **Define entity data** (`src/data/entities/deployable_entities_data.lua`):

```lua
IronFurnace = {
   class = "Furnace",
   events = { ... },
   -- ... other properties
},
```

The processing system automatically dispatches to the correct behavior based on `MachineClass`.

## Edge Cases Handled

| Scenario | Behavior |
|:---------|:---------|
| No ingredients, only mana | Works - recipe.inputs is nil/empty |
| No mana, only ingredients | Works - mana_per_tick defaults to 0 |
| Output slots full | BLOCKED state, waits for space |
| Output stacking | Stacks to max_stack_size via ItemRegistry |
| No output slots | Valid "sink" machine type |
| Ingredients stolen mid-cycle | Returns to IDLE (not consumed yet) |
| Mana depleted mid-cycle | NO_MANA state, preserves timer |
| Multiple outputs | Fills multiple slots as needed |
| Chance-based outputs | Rolled on complete, doesn't block if no space |

## Debug Logging

Enable/disable debug logging in the behavior module:

```lua
local DEBUG = true  -- or false
```

Example output:
```
Assembler: SkeletonAssembler1048637 has ingredients -> ready
Assembler: SkeletonAssembler1048637 starting ritual
  Processing time: 5s
Assembler: SkeletonAssembler1048637 complete, produced outputs
```
