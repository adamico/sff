# FlexLove Quick Reference Card

Quick reference for common FlexLove operations in the game UI system.

---

## Creating UI Elements

### Basic Panel
```lua
local panel = Flexlove.new({
   id = "my_panel",
   x = 100,
   y = 100,
   width = 200,
   height = 150,
   backgroundColor = Flexlove.Color.new(0.5, 0.45, 0.5),
   border = { width = 2, color = Flexlove.Color.new(1, 1, 1) },
   positioning = "absolute"
})
```

### Slot Element
```lua
local slot = Flexlove.new({
   id = "slot_1",
   x = slotX,
   y = slotY,
   width = 32,
   height = 32,
   backgroundColor = Flexlove.Color.new(0.5, 0.45, 0.5),
   border = { width = 2, color = Flexlove.Color.new(1, 1, 1) },
   text = "A",
   textColor = Flexlove.Color.new(1, 1, 1),
   textSize = 14,
   textAlign = "center",
   positioning = "absolute",
   parent = containerElement,
   userdata = { slotIndex = 1, slotType = "input" }
})
```

### Text Label
```lua
local label = Flexlove.new({
   id = "label",
   x = 10,
   y = 10,
   text = "Machine Name",
   textColor = Flexlove.Color.new(1, 1, 1),
   textSize = 14,
   positioning = "absolute",
   parent = containerElement
})
```

### Progress Bar
```lua
-- Background
local barBg = Flexlove.new({
   id = "bar_bg",
   x = 10,
   y = 100,
   width = 200,
   height = 8,
   backgroundColor = Flexlove.Color.new(0.2, 0.2, 0.2),
   border = { width = 1, color = Flexlove.Color.new(1, 1, 1) },
   positioning = "absolute",
   parent = containerElement
})

-- Fill (child of background)
local barFill = Flexlove.new({
   id = "bar_fill",
   x = 10,
   y = 100,
   width = 100, -- 50% fill
   height = 8,
   backgroundColor = Flexlove.Color.new(0.3, 0.5, 0.9),
   positioning = "absolute",
   parent = barBg
})
```

### Button with Callback
```lua
local button = Flexlove.new({
   id = "start_button",
   x = 50,
   y = 150,
   width = 100,
   height = 24,
   backgroundColor = Flexlove.Color.new(0.2, 0.2, 0.2),
   text = "Start",
   textColor = Flexlove.Color.new(1, 1, 1),
   textAlign = "center",
   positioning = "absolute",
   parent = containerElement,
   onEvent = function(element, event)
      if event.type == "click" then
         print("Button clicked!")
         -- Your logic here
      end
   end
})
```

---

## Updating Elements

### Update Text
```lua
element:setText("New Text")
```

### Update Width (for bars)
```lua
element.width = newWidth
```

### Update Position
```lua
element.x = newX
element.y = newY
```

### Update Color
```lua
element.backgroundColor = Flexlove.Color.new(1, 0, 0)
element.textColor = Flexlove.Color.new(1, 1, 1)
```

### Show/Hide Element
```lua
element:show()  -- Sets opacity to 1
element:hide()  -- Sets opacity to 0
```

### Update Opacity
```lua
element:updateOpacity(0.5)  -- 50% transparent
```

---

## Hit Detection

### Get Element at Mouse Position
```lua
local mx, my = love.mouse.getPosition()
local element = Flexlove.getElementAtPosition(mx, my)

if element then
   print("Element ID:", element.id)
   if element.userdata then
      print("Slot Index:", element.userdata.slotIndex)
      print("Slot Type:", element.userdata.slotType)
   end
end
```

### Check if Point is in Element
```lua
if element:contains(mx, my) then
   print("Mouse is over element!")
end
```

---

## Element Hierarchy

### Add Child Element
```lua
local child = Flexlove.new({
   id = "child",
   -- properties...
   parent = parentElement  -- Set parent during creation
})

-- OR add after creation:
parentElement:addChild(child)
```

### Remove Child
```lua
parentElement:removeChild(child)
```

### Clear All Children
```lua
parentElement:clearChildren()
```

### Get Child Count
```lua
local count = parentElement:getChildCount()
```

---

## Element Lifecycle

### Create Element
```lua
local element = Flexlove.new({ id = "my_element", ... })
```

### Destroy Element
```lua
element:destroy()  -- Removes element and all children
```

### Store Reference
```lua
-- In class:
self.myElement = Flexlove.new({...})

-- In userdata (for reverse lookup):
userdata = { view = self, slotIndex = i }
```

---

## Colors

### Create Color
```lua
local color = Flexlove.Color.new(r, g, b, a)  -- Values 0-1
-- Example:
local red = Flexlove.Color.new(1, 0, 0, 1)
local transparentBlue = Flexlove.Color.new(0, 0, 1, 0.5)
```

### From Hex
```lua
local color = Flexlove.Color.fromHex("#FF5733")
local colorWithAlpha = Flexlove.Color.fromHex("#FF5733AA")
```

### Named Colors (if using theme)
```lua
local color = Theme.getColor("primary")
```

---

## Layout Properties

### Positioning Modes
```lua
positioning = "absolute"  -- Manual x, y positioning
positioning = "relative"  -- Positioned relative to parent
positioning = "flex"      -- Flexbox layout
positioning = "grid"      -- Grid layout
```

### Flexbox Layout
```lua
local container = Flexlove.new({
   flexDirection = "horizontal",  -- or "vertical"
   flexWrap = "wrap",             -- or "nowrap", "wrap-reverse"
   justifyContent = "flex-start", -- or "center", "flex-end", "space-between"
   alignItems = "stretch",        -- or "center", "flex-start", "flex-end"
   gap = 10,                      -- Space between children
   padding = { top = 5, right = 5, bottom = 5, left = 5 }
})
```

### Size Units
```lua
width = 200          -- Pixels
width = "50%"        -- Percentage of parent
width = "10vh"       -- 10% of viewport height
width = "5vw"        -- 5% of viewport width
```

---

## Event Handling

### Event Types
- `"click"` - Mouse click (press and release)
- `"press"` - Mouse button pressed
- `"release"` - Mouse button released
- `"drag"` - Mouse dragged while pressed
- `"hover"` - Mouse over element (via FlexLove's automatic handling)

### Event Callback
```lua
onEvent = function(element, event)
   print("Event type:", event.type)
   print("Mouse position:", event.x, event.y)
   print("Button:", event.button)  -- 1=left, 2=right, 3=middle
   print("Click count:", event.clickCount)  -- For double-click detection
   
   if event.type == "click" then
      -- Handle click
   elseif event.type == "drag" then
      -- Handle drag
      print("Drag delta:", event.dx, event.dy)
   end
end
```

---

## FlexLove Lifecycle (Already in main.lua)

### Initialization
```lua
function love.load()
   Flexlove.init({
      baseScale = { width = 1920, height = 1080 },
      immediateMode = false
   })
end
```

### Update
```lua
function love.update(dt)
   Flexlove.update(dt)
end
```

### Draw
```lua
function love.draw()
   Flexlove.draw(function()
      -- Your game rendering here
   end)
end
```

### Input Callbacks
```lua
function love.resize(w, h)
   Flexlove.resize()
end

function love.textinput(text)
   Flexlove.textinput(text)
end

function love.keypressed(key, scancode, isrepeat)
   Flexlove.keypressed(key, scancode, isrepeat)
end

function love.wheelmoved(dx, dy)
   Flexlove.wheelmoved(dx, dy)
end
```

---

## Common Patterns

### Creating a Slot Grid
```lua
local slots = {}
for i = 1, slotCount do
   local col = (i - 1) % columns
   local row = math.floor((i - 1) / columns)
   local x = startX + col * (slotSize + gap)
   local y = startY + row * (slotSize + gap)
   
   slots[i] = Flexlove.new({
      id = "slot_"..i,
      x = x,
      y = y,
      width = slotSize,
      height = slotSize,
      backgroundColor = Flexlove.Color.new(0.5, 0.45, 0.5),
      positioning = "absolute",
      parent = container,
      userdata = { slotIndex = i }
   })
end
```

### Dynamic Bar Update
```lua
function updateBar(barFill, current, max, barWidth)
   local fillRatio = current / max
   barFill.width = barWidth * fillRatio
end

-- Usage:
updateBar(self.manaBarFill, mana.current, mana.max, 200)
```

### Updating Slot Content
```lua
function updateSlot(slotElement, slot)
   local itemText = slot.item_id and string.sub(slot.item_id, 1, 1) or ""
   slotElement:setText(itemText)
end
```

### Drawing Held Item (Cursor-Following)
```lua
-- In state manager's draw():
if self.heldStack then
   local mx, my = love.mouse.getPosition()
   FlexDrawHelper:drawHeldStack(self.heldStack, mx, my)
end
```

---

## Debugging

### Check Element Count
```lua
print("Active elements:", Flexlove.getStateCount())
```

### Get Element Info
```lua
if element then
   print("ID:", element.id)
   print("Position:", element.x, element.y)
   print("Size:", element.width, element.height)
   print("Visible:", element.opacity > 0)
   print("Has parent:", element.parent ~= nil)
   print("Child count:", element:getChildCount())
end
```

### Check Hit Detection
```lua
local mx, my = love.mouse.getPosition()
local element = Flexlove.getElementAtPosition(mx, my)
print("Element at cursor:", element and element.id or "none")
```

---

## Performance Tips

1. **Create elements once** (in `initialize()` or `buildUI()`)
2. **Update properties** (in `draw()` method)
3. **Avoid recreating** elements every frame
4. **Call destroy()** when elements are no longer needed
5. **Use absolute positioning** for complex layouts (simpler than flex initially)
6. **Batch updates** - update multiple properties before frame renders

---

## Common Issues

### Elements not appearing
- Check if `Flexlove.draw()` is called
- Verify `positioning` is set
- Ensure `opacity` is not 0
- Check if element is added to parent

### Click not detected
- Verify `userdata` is set correctly
- Check if element has `onEvent` callback
- Use `Flexlove.getElementAtPosition()` for debugging
- Ensure element is not hidden behind another element (check z-index)

### Position incorrect after resize
- Call `Flexlove.resize()` in `love.resize()`
- May need to manually recalculate absolute positions
- Consider using relative/flex positioning for auto-resize

---

## See Also

- `docs/FLEXLOVE_INTEGRATION.md` - Complete integration guide
- `docs/FLEXLOVE_IMPLEMENTATION_SUMMARY.md` - Implementation details
- `docs/MIGRATION_STEPS.md` - Step-by-step migration
- https://mikefreno.github.io/FlexLove/api.html - Official API docs