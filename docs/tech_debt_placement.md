# Tech Debt Assessment: EntityPlacementManager (Factorio Model)

**Context**: Factorio distinguishes between "Instant Placement" (Toolbar) and "Ghost Placement" (Blueprints). Blueprints spawn persistent "Ghost Entities" into the world that are constructed later.

## Architecture Implications

This model **simplifies** the future requirements for `EntityPlacementManager`.

### 1. Separation of Concerns

- **Placement Manager**: Only needs to handle the *initial* placement of the Blueprint.
  - Action: Spawn N "Ghost Entities" into the ECS.
  - **Done**. Its job is finished immediately after the click.
- **Construction System** (New): Handles turning "Ghost Entities" into "Real Entities".
  - Detects player interaction with Ghost.
  - Checks Inventory for materials.
  - Swaps Ghost -> Real Entity.

### 2. Impact on Current Code

- **Validation**: `PlacementValidationHelper` is still valid. It will verify if the *Ghosts* can be placed (e.g., overlapping obstacles).
- **Rendering**: The "Interactive Ghost" (on cursor) logic remains. We just need to render the Blueprint layout relative to the cursor.
- **State**: No complex persistent state needed in Manager. Once placed, the data lives in the ECS (as Ghost entities).

## Detailed Debt Analysis

| Feature | Current | Future (Blueprint) | Debt / Friction |
| :--- | :--- | :--- | :--- |
| **Input** | Single Item (`spawnsEntity`) | Blueprint Item (`entities[]`) | **Low**. Need to handle `item.blueprintData`. |
| **Visuals** | Draw 1 Box | Draw N Boxes | **Low**. `draw` method iterates the blueprint list. |
| **Action** | Spawn 1 Entity | Spawn N Ghost Entities | **Low**. Logic is just a loop. |
| **Inventory** | Consume 1 Item | **Do Nothing** | **Zero**. Blueprint placement doesn't consume the building materials immediately. It places *Ghosts*. |

## Key Realization

By adopting the "Ghost Entity" model, you **remove** the need for the Placement Manager to scan the inventory for building materials during blueprint placement. The inventory check happens later, when the player (or drone) actually constructs the ghost.

This means the "High Friction" point identified in the previous report (Inventory Consumption) is actually **Non-Existent** for Blueprints in this model.

## Verdict

**Green Light**. The current architecture is essentially "Ready" for this approach.

- You will eventually add a "Blueprint" item type.
- You will eventually add a "Ghost" entity type.
- You need a new `ConstructionSystem` later.
- `EntityPlacementManager` requires only minor extensions (loops) to support this.
