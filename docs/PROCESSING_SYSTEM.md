# Processing System

> **Last Updated:** 2026-01-13

Manages machine automation using behavior-based architecture in the Evolved ECS.

---

## Overview

1. Detect ingredients in input slots
2. Start processing with timer
3. Consume mana per tick during processing
4. Consume ingredients on completion (not on start)
5. Produce outputs with stacking
6. Auto-restart if more ingredients available

---

## Resource Consumption

| Resource | When Consumed | On Interrupt |
|:---------|:--------------|:-------------|
| Ingredients | On COMPLETE | Not consumed |
| Mana | Per tick during WORKING | Stops draining |

---

## Architecture

```
src/evolved/
├── behaviors/
│   ├── init.lua              # Behavior registry
│   └── assembler_behavior.lua
├── systems/
│   ├── processing_system.lua # Main system
│   └── mana_system.lua       # Mana regeneration
└── fragments.lua             # Mana, ProcessingTimer, etc.
```

---

## Required Fragments

| Fragment | Description |
|:---------|:------------|
| MachineClass | Machine type (e.g., "Assembler") |
| CurrentRecipe | Active recipe data |
| StateMachine | FSM instance |
| Mana | `{current, max, regenRate}` |
| ProcessingTimer | `{current, saved}` |
| Inventory | Input/output slots |

---

## Assembler State Machine

```
      [BLANK] ──set_recipe──► [IDLE] ◄─────────────┐
                                │                   │
                           prepare                  │
                                ▼                   │
                             [READY]                │
                                │                   │
                          startRitual              │
                                ▼                   │
     [NO_MANA] ◄───starve─── [WORKING] ───block───► [BLOCKED]
         │                      │                       │
         └───────refuel─────────┴───────unblock────────┘
                                ▼
                             [IDLE]
```

**States:**

- `blank` - No recipe
- `idle` - Waiting for ingredients
- `ready` - Has ingredients, awaiting start
- `working` - Processing, consuming mana
- `blocked` - Output full
- `noMana` - Depleted mid-cycle

---

## Behavior Module Structure

```lua
local Assembler = {}

function Assembler.idle(context) end
function Assembler.ready(context) end
function Assembler.working(context) end

function Assembler.update(context)
   local behavior = Assembler[context.fsm.current]
   if behavior then behavior(context) end
end

return Assembler
```

---

## Context Object

```lua
{
   machineId = number,
   machineName = string,
   fsm = table,
   recipe = table,
   inventory = table,
   mana = {current, max, regenRate},
   processingTimer = {current, saved},
   dt = number,
}
```

---

## Recipe Format

```lua
{
   name = "Create Skeleton",
   inputs = { bone = 2, essence = 1 },
   outputs = { skeleton = 1 },
   manaPerTick = 2,
   processingTime = 5,
   requiresRitual = true,
}
```

---

## Adding New Machine Types

1. Create behavior module: `src/evolved/behaviors/furnace_behavior.lua`
2. Register: `Behaviors.register("Furnace", require(...))`
3. Create prefab with `MachineClass = "Furnace"`
4. Define entity data

---

## Edge Cases

| Scenario | Behavior |
|:---------|:---------|
| No ingredients, only mana | Works |
| No mana, only ingredients | Works |
| Output slots full | BLOCKED state |
| Ingredients stolen mid-cycle | Returns to IDLE |
| Mana depleted mid-cycle | NO_MANA, preserves timer |
