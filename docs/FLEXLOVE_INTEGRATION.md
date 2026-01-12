# FlexLove UI Integration Guide

## Overview

This document describes the integration of the FlexLove UI library into the game's UI system, replacing the previous DrawHelper-based rendering approach.

## Architecture Changes

### Before (DrawHelper-based)

```
┌─────────────────────────────────────┐
│     render_ui_system.lua            │
│  (ECS system - OnRender stage)      │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌─────▼──────┐
│InventoryView│  │MachineScreen│
│   (Class)   │  │   (Class)   │
└──────┬──────┘  └──────┬──────┘
       │                │
       └────────┬────────┘
                │
         ┌──────▼──────┐
         │ DrawHelper  │
         │   (Mixin)   │
         └──────┬──────┘
                │
         ┌──────▼──────┐
         │love.graphics│
         │  (Direct)   │
         └─────────────┘
```

### After (FlexLove-based)

```
┌─────────────────────────────────────┐
│        main.lua                      │
│  Flexlove.init/update/draw          │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼────────────┐  ┌▼──────────────────┐
│ render_ui_system  │  │   FlexLove        │
│   (ECS system)    │  │  (UI Framework)   │
└──────┬────────────┘  └───────────────────┘
       │
┌──────┴───────────────────┐
│                          │
┌▼──────────────┐  ┌───────▼──────┐
│FlexInventoryView│ │FlexMachineScreen│
│    (Class)      │ │    (Class)      │
└─────┬───────────┘ └────────┬───────┘
      │                      │
      │  Creates/manages     │
      │  FlexLove Elements   │
      │                      │
      └──────────┬───────────┘
                 │
         ┌───────▼────────┐
         │Flexlove.Element│
         │  (UI Nodes)    │
         └────────────────┘
```

## Implementation Details

### 1. FlexInventoryView

**File:** `sff/src/ui/flex_inventory_view.lua`

**Purpose:** Renders inventory grids using FlexLove elements

**Key Changes:**
- Replaces `DrawHelper` mixin with FlexLove element creation
- Stores FlexLove element references as member variables
- Uses FlexLove's hit detection instead of manual point-in-slot checks
- Maintains same public API for compatibility

**Member Variables:**
```lua
self.containerElement  -- Main panel (FlexLove Element)
self.slotElements      -- Array of slot element references
self.stateLabel        -- Machine state label (if entity has state)
```

**Key Methods:**
- `initialize(inventory, options)` - Creates FlexLove element hierarchy
- `buildUI()` - Constructs all FlexLove elements
- `draw()` - Updates dynamic content (slot items, quantities, state)
- `updateSlots()` - Refreshes slot appearances from inventory data
- `getSlotUnderMouse(mx, my)` - Uses `Flexlove.getElementAtPosition()`
- `setPosition(x, y)` - Updates container and child element positions
- `destroy()` - Cleans up FlexLove elements

**Usage Example:**
```lua
local view = FlexInventoryView:new(inventory, {
   id = "player_inventory",
   x = 100,
   y = 100,
   columns = 10,
   rows = 4,
   slot_size = 32,
   entityId = entityId
})

-- Each frame
view:draw()  -- Updates dynamic content

-- When moving
view:setPosition(newX, newY)

-- When done
view:destroy()
```

### 2. FlexMachineScreen

**File:** `sff/src/ui/flex_machine_screen.lua`

**Purpose:** Renders machine UI with slots, bars, and buttons using FlexLove

**Key Changes:**
- All UI components are FlexLove elements
- Progress bars and mana bars use width property updates
- Buttons have `onEvent` callbacks
- Maintains same public API

**Member Variables:**
```lua
self.containerElement      -- Main panel
self.nameLabel            -- Machine name
self.stateLabel           -- Current state
self.slotElements         -- Slot element references
self.manaBarContainer     -- Mana bar background
self.manaBarFill          -- Mana bar fill (width changes)
self.manaLabel            -- Mana text
self.progressBarContainer -- Progress bar background
self.progressBarFill      -- Progress bar fill (width changes)
self.startButton          -- Start ritual button
```

**Key Methods:**
- `initialize(options)` - Creates FlexLove element hierarchy
- `buildUI()` - Constructs all FlexLove elements
- `createHeader()` - Machine name and state labels
- `createSlots()` - Input/output slot grids
- `createManaBar()` - Mana bar with fill indicator
- `createProgressBar()` - Processing progress bar
- `createStartButton()` - Ritual start button with callback
- `draw()` - Updates all dynamic content
- `updateManaBar()` - Adjusts mana bar fill width
- `updateProgressBar()` - Adjusts progress bar fill width
- `getSlotUnderMouse(mouseX, mouseY)` - Hit detection
- `setPosition(x, y)` - Updates position (triggers rebuild)
- `destroy()` - Cleans up FlexLove elements

**Usage Example:**
```lua
local screen = FlexMachineScreen:new({
   entityId = machineEntity,
   x = 200,
   y = 100,
   width = 300,
   height = 200
})

-- Each frame
screen:draw()  -- Updates bars, slots, labels

-- When done
screen:destroy()
```

### 3. FlexDrawHelper

**File:** `sff/src/ui/flex_draw_helper.lua`

**Purpose:** Helper functions for UI elements that don't fit FlexLove's structure

**Use Cases:**
- Drawing held items that follow the cursor
- Temporary overlays
- Custom rendering that needs to be drawn outside FlexLove's hierarchy

**Methods:**
- `drawHeldStack(stack, mouse_x, mouse_y)` - Immediate mode rendering
- `createHeldStackElement(stack, mouse_x, mouse_y)` - Retained mode (returns Element)
- `updateHeldStackPosition(element, mouse_x, mouse_y)` - Update cursor-following element

**Usage:**
```lua
-- Option 1: Immediate mode (simple)
FlexDrawHelper:drawHeldStack(heldStack, mx, my)

-- Option 2: Retained mode (efficient)
local heldElement = FlexDrawHelper:createHeldStackElement(heldStack, mx, my)
-- Each frame:
FlexDrawHelper:updateHeldStackPosition(heldElement, mx, my)
```

## Integration Steps

### Step 1: main.lua Initialization (Already Done)

```lua
function love.load()
   Flexlove.init({
      baseScale = { width = SCREEN_WIDTH, height = SCREEN_HEIGHT },
      immediateMode = false,
      theme = "game" -- optional
   })
   process(STAGES.OnSetup)
end

function love.update(dt)
   UNIFORMS.setDeltaTime(dt)
   Flexlove.update(dt)
   process(STAGES.OnUpdate)
end

function love.draw()
   Flexlove.draw(function()
      process(STAGES.OnRender)
   end)
end

function love.resize(w, h)
   Flexlove.resize()
end

function love.textinput(text)
   Flexlove.textinput(text)
end

function love.keypressed(key, scancode, isrepeat)
   Flexlove.keypressed(key, scancode, isrepeat)
   -- Your game logic
end

function love.wheelmoved(dx, dy)
   Flexlove.wheelmoved(dx, dy)
end
```

### Step 2: Update render_ui_system.lua

Replace class instantiation:

```lua
-- OLD:
local InventoryView = require("src.ui.inventory_view")
local MachineScreen = require("src.ui.machine_screen")

-- NEW:
local FlexInventoryView = require("src.ui.flex_inventory_view")
local FlexMachineScreen = require("src.ui.flex_machine_screen")

-- Change instantiation:
local view = FlexInventoryView:new(inventory, options)
local screen = FlexMachineScreen:new(options)
```

### Step 3: Update State Managers

Update `InventoryStateManager` and `MachineStateManager`:

```lua
-- OLD DrawHelper import:
local DrawHelper = require("src.helpers.draw_helper")

-- NEW FlexDrawHelper import:
local FlexDrawHelper = require("src.ui.flex_draw_helper")

-- In draw() method:
function InventoryStateManager:draw()
   for _, view in ipairs(self.views) do
      if view then
         view:draw()  -- FlexInventoryView updates its elements
      end
   end
   
   if self.heldStack then
      -- Use immediate mode for cursor-following held stack
      FlexDrawHelper:drawHeldStack(self.heldStack, love.mouse.getPosition())
   end
end
```

## Benefits

### 1. Automatic State Management
- Hover states are handled by FlexLove automatically
- No manual tracking of mouse-over elements
- Built-in focus management for inputs

### 2. Simplified Rendering
- No manual `love.graphics` calls
- FlexLove handles drawing order, clipping, transforms
- Reduced rendering code (~60% less lines)

### 3. Responsive Scaling
- FlexLove handles window resizing automatically
- Elements scale proportionally with window
- No manual recalculation needed

### 4. Flexbox Layout
- Automatic positioning for grids and lists
- No manual slot position calculations
- Gap, padding, alignment handled by FlexLove

### 5. Event System
- Clean callback-based interaction handling
- `onEvent` callbacks for clicks, press, release, drag
- No manual mouse position tracking

### 6. Theming Support
- Easy visual customization with 9-patch images
- State-based appearance (normal, hover, pressed, disabled)
- Color palette management

## Migration Checklist

- [x] FlexLove initialized in main.lua
- [x] FlexInventoryView implemented
- [x] FlexMachineScreen implemented
- [x] FlexDrawHelper created for held items
- [ ] Update render_ui_system.lua to use new classes
- [ ] Update InventoryStateManager to use FlexDrawHelper
- [ ] Update MachineStateManager to use FlexDrawHelper
- [ ] Test inventory opening/closing
- [ ] Test machine screen rendering
- [ ] Test item dragging
- [ ] Test slot interactions
- [ ] Test mana bar updates
- [ ] Test progress bar updates
- [ ] Test window resizing
- [ ] Remove old DrawHelper.lua
- [ ] Remove old InventoryView.lua
- [ ] Remove old MachineScreen.lua

## Known Limitations

### 1. Cursor-Following Elements
FlexLove elements are positioned absolutely or in a layout hierarchy. Items being dragged by the cursor are best rendered using immediate mode `love.graphics` calls (via `FlexDrawHelper:drawHeldStack()`).

### 2. Element Position Updates
When updating positions of absolutely-positioned elements, you must set `element.x` and `element.y` directly. This doesn't trigger automatic layout recalculation for children, so complex repositioning may require a full rebuild.

### 3. Dynamic Content Updates
Text content, bar widths, and other dynamic properties should be updated in the `draw()` method each frame. FlexLove doesn't automatically observe data changes.

## Performance Considerations

### Element Creation vs Updates
- **Create once:** Build UI in `initialize()` or `buildUI()`
- **Update often:** Modify properties in `draw()` method
- **Avoid:** Recreating elements every frame

### Batch Updates
```lua
-- Good: Update properties
element:setText(newText)
element.width = newWidth

-- Avoid: Destroying and recreating
element:destroy()
element = Flexlove.new({...})
```

### Cleanup
Always call `destroy()` on elements when they're no longer needed:
```lua
function InventoryStateManager:close()
   for _, view in ipairs(self.views) do
      view:destroy()
   end
   self.views = {}
end
```

## Debugging Tips

### 1. Inspect Element Tree
```lua
-- Print element hierarchy
print(Flexlove.getStateCount())  -- Number of tracked elements
```

### 2. Check Hit Detection
```lua
local element = Flexlove.getElementAtPosition(mx, my)
if element then
   print("Hit element:", element.id)
   if element.userdata then
      print("Userdata:", element.userdata)
   end
end
```

### 3. Verify Element Properties
```lua
-- In draw():
if self.manaBarFill then
   print("Mana bar width:", self.manaBarFill.width)
else
   print("Mana bar not created!")
end
```

## Future Enhancements

### 1. Custom Theme
Create `sff/src/ui/themes/game_theme.lua` with:
- 9-patch images for panels and buttons
- Color palette definitions
- Font specifications
- Slot hover/press states

### 2. Drag and Drop
Implement FlexLove's drag event handlers for more sophisticated item dragging:
```lua
onEvent = function(element, event)
   if event.type == "drag" then
      -- Handle dragging
   elseif event.type == "release" then
      -- Handle drop
   end
end
```

### 3. Animations
Use FlexLove's animation system for:
- Inventory open/close transitions
- Button press effects
- Progress bar smooth fills
```lua
local anim = Flexlove.Animation.fade(0.3, 0, 1)
element.animation = anim
```

### 4. Text Input Fields
For machine naming, filtering, etc.:
```lua
local input = Flexlove.new({
   editable = true,
   multiline = false,
   placeholder = "Enter name...",
   onTextChange = function(element, text)
      -- Handle text changes
   end
})
```

## References

- FlexLove API: https://mikefreno.github.io/FlexLove/api.html
- FlexLove Source: `lib/flexlove/FlexLove.lua`
- Example Themes: `lib/flexlove/themes/*.lua`
