# Processing System

A generic system for managing machine automation. Handles state transitions, processing timers, and cycling for any machine type with varying requirements.

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

## Machine Hierarchy

```
Machine (base class)
├── Assembler (mana + ritual + ingredients)
├── Generator (auto-start, no ingredients)
└── [Future machine types...]
```

### Machine Base Class

All machines extend the `Machine` base class which provides:

- Core properties (position, name, size, etc.)
- Processing state (currentRecipe, processingTimer, savedTimer)
- Mana resource
- Inventory component
- FSM infrastructure

```lua
-- src/entities/machine.lua
local Machine = Class("Machine")

function Machine:initialize(x, y, id)
   -- Core identity
   self.id = id
   self.position = Vector(x, y)
   
   -- Processing state
   self.currentRecipe = nil
   self.processingTimer = 0
   self.savedTimer = 0  -- For resuming after NO_MANA
   
   -- Resources
   self.mana = data.mana or 0
   
   -- Components
   self.inventory = InventoryComponent:new(data.inventory)
   
   -- FSM - subclasses override getFSMEvents()
   self.fsm = statemachine.create({
      initial = "blank",
      events = self:getFSMEvents(),
   })
end

function Machine:getFSMEvents()
   -- Override in subclasses
   return {}
end
```

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
{name = "set_recipe",   from = "blank",   to = "idle"},
{name = "prepare",      from = "idle",    to = "ready"},
{name = "start_ritual", from = "ready",   to = "working"},
{name = "complete",     from = "working", to = "idle"},
{name = "stop",         from = "working", to = "idle"},
{name = "block",        from = "working", to = "blocked"},
{name = "unblock",      from = "blocked", to = "idle"},
{name = "starve",       from = "working", to = "no_mana"},
{name = "refuel",       from = "no_mana", to = "working"},
```

### Generator FSM

Generators auto-start when recipe is set and don't require ingredients.

```
      [BLANK] ──set_recipe──► [WORKING] ◄────────┐
                                 │               │
                            complete         restart
                                 │               │
                                 ▼               │
                              [IDLE] ────────────┘
                                 │
                               block
                                 │
                                 ▼
                            [BLOCKED] ──unblock──► [IDLE]
```

**Transitions:**
```lua
{name = "set_recipe", from = "blank",   to = "working"},
{name = "complete",   from = "working", to = "idle"},
{name = "restart",    from = "idle",    to = "working"},
{name = "block",      from = "working", to = "blocked"},
{name = "unblock",    from = "blocked", to = "idle"},
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
   
   -- No-ingredient recipe (mana synthesizer)
   synthesize_essence = {
      name = "Synthesize Essence",
      outputs = { essence = 1 },
      mana_per_tick = 5,
      processing_time = 10,
   },
   
   -- Generator recipe (no inputs, no mana)
   generate_power = {
      name = "Generate Power",
      outputs = { power_crystal = 1 },
      processing_time = 30,
   },
}
```

## ECS Integration

The system uses a function filter to identify processing machines:

```lua
local function isProcessingMachine(entity)
   return entity.fsm ~= nil 
      and entity.inventory ~= nil 
      and entity.processingTimer ~= nil
end

pool = nata.new({
   groups = {
      processing = {filter = isProcessingMachine},
   },
   systems = {
      require("src.systems.processing_system"),
   },
})
```

## Usage

### 1. Create a Machine

```lua
-- Machines are created and added to the ECS pool
local assembler = pool:queue(Assembler:new(600, 100, AssemblerRegistry.SKELETON_ASSEMBLER))
```

### 2. Set a Recipe

```lua
-- Get the machine
local assembler = ecs.assembler

-- Set the recipe (transitions from BLANK to IDLE)
assembler.currentRecipe = assembler.valid_recipes[1]
if assembler.fsm:can("set_recipe") then
   assembler.fsm:set_recipe()
end
```

### 3. Add Ingredients (if required)

```lua
-- Add items to input slots
assembler.inventory:addItem("bone", 2)
assembler.inventory:addItem("essence", 1)

-- The system automatically detects ingredients and transitions:
-- IDLE → READY → WORKING
```

### 4. Automatic Processing

The system handles everything automatically:
- Detects ingredients → transitions to READY
- Starts ritual/processing → transitions to WORKING
- Consumes mana per tick
- On completion: consumes ingredients, produces outputs
- If more ingredients available → restarts cycle

### 5. Monitor Progress

```lua
-- Get current state
local state = assembler:getState()  -- "working", "idle", etc.

-- Get progress percentage (0-100)
local progress = assembler:getProgress()
```

## Output Stacking

Outputs are placed in slots with stacking support:

1. First, try to stack with existing slots of the same item type
2. Then, fill empty slots
3. Respects `max_stack_size` from ItemRegistry

```lua
-- Example: producing 3 bones when max_stack_size is 64
-- Slot 1: bone x 60 → becomes bone x 63
-- Remaining: 0 (all stacked)

-- Example: producing 5 bones when slot is nearly full
-- Slot 1: bone x 62 → becomes bone x 64 (max)
-- Slot 2: (empty) → becomes bone x 3
```

## Edge Cases Handled

| Scenario | Behavior |
|:---------|:---------|
| No ingredients, only mana | Works - recipe.inputs is nil/empty |
| No mana, only ingredients | Works - mana_per_tick defaults to 0 |
| No ingredients, no mana | Works - auto-processes (generators) |
| Output slots full | BLOCKED state, waits for space |
| Output stacking | Stacks to max_stack_size |
| No output slots | Valid "sink" machine type |
| Ingredients stolen mid-cycle | Returns to IDLE (not consumed yet) |
| Mana depleted mid-cycle | NO_MANA state, preserves timer |
| Recipe changed | Resets to IDLE |
| Multiple outputs | Fills multiple slots as needed |
| Chance-based outputs | Rolled on complete, doesn't block if no space |

## Debug Logging

Enable/disable debug logging:

```lua
local ProcessingSystem = require("src.systems.processing_system")
ProcessingSystem.DEBUG = true  -- or false
```

Example output:
```
ProcessingSystem: Skeleton Assembler - Prepared, transitioning to READY
ProcessingSystem: Skeleton Assembler - Starting ritual
  Processing time: 5s
ProcessingSystem: Skeleton Assembler - Processing complete, produced outputs
```

## Adding New Machine Types

1. **Create the entity class** extending Machine:

```lua
local Machine = require("src.entities.machine")
local MyMachine = Class("MyMachine", Machine)

function MyMachine:initialize(x, y, id)
   Machine.initialize(self, x, y, id)
   -- Add machine-specific properties
end

function MyMachine:getFSMEvents()
   return {
      -- Define state transitions
   }
end

return MyMachine
```

2. **Define entity data** in deployable_entities_data.lua:

```lua
my_machine = {
   class = "MyMachine",
   name = "My Machine",
   mana = 50,
   inventory = {
      max_input_slots = 4,
      max_output_slots = 2,
   },
   recipes = {Recipes.my_recipe},
   -- ...
}
```

3. **Create recipes** in recipes_data.lua:

```lua
my_recipe = {
   name = "My Recipe",
   inputs = { ... },
   outputs = { ... },
   mana_per_tick = 1,
   processing_time = 10,
}
```

4. The processing system handles the rest automatically based on the FSM events defined.