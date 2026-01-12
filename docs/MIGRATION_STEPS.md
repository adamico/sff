# FlexLove Migration Steps

This document provides exact steps to migrate the existing UI system to use the new FlexLove-based classes.

## Prerequisites

✅ FlexLove initialized in `main.lua` (already done)
✅ `FlexInventoryView` created
✅ `FlexMachineScreen` created
✅ `FlexDrawHelper` created

## Step 1: Update render_ui_system.lua

**File:** `sff/src/evolved/systems/render_ui_system.lua`

### Change 1: Update Imports (Lines 1-4)

**BEFORE:**
```lua
local InventoryView = require("src.ui.inventory_view")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local MachineScreen = require("src.ui.machine_screen")
local MachineStateManager = require("src.ui.machine_state_manager")
```

**AFTER:**
```lua
local FlexInventoryView = require("src.ui.flex_inventory_view")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local FlexMachineScreen = require("src.ui.flex_machine_screen")
local MachineStateManager = require("src.ui.machine_state_manager")
```

### Change 2: Update getToolbarView function (Line 44)

**BEFORE:**
```lua
toolbarView = InventoryView:new(toolbar, {
```

**AFTER:**
```lua
toolbarView = FlexInventoryView:new(toolbar, {
```

### Change 3: Update getPlayerInventoryView function (Line 56)

**BEFORE:**
```lua
playerInventoryView = InventoryView:new(playerInventory, {
```

**AFTER:**
```lua
playerInventoryView = FlexInventoryView:new(playerInventory, {
```

### Change 4: Update openTargetInventory function (Line 112)

**BEFORE:**
```lua
local targetInventoryView = InventoryView:new(targetInventory, options)
```

**AFTER:**
```lua
local targetInventoryView = FlexInventoryView:new(targetInventory, options)
```

### Change 5: Update openMachineScreen function (Line 147)

**BEFORE:**
```lua
local machineScreen = MachineScreen:new({
```

**AFTER:**
```lua
local machineScreen = FlexMachineScreen:new({
```

**Summary:** 5 changes in `render_ui_system.lua`

---

## Step 2: Update inventory_state_manager.lua

**File:** `sff/src/ui/inventory_state_manager.lua`

### Change 1: Update Import (Line 1)

**BEFORE:**
```lua
local DrawHelper = require("src.helpers.draw_helper")
```

**AFTER:**
```lua
local FlexDrawHelper = require("src.ui.flex_draw_helper")
```

### Change 2: Update draw method (Line 132)

**BEFORE:**
```lua
function InventoryStateManager:draw()
   for i = 1, #self.views do
      local view = self.views[i]
      if view then
         view:draw()
      end
   end
   if self.heldStack then
      DrawHelper:drawHeldStack(self.heldStack, love.mouse.getPosition())
   end
end
```

**AFTER:**
```lua
function InventoryStateManager:draw()
   for i = 1, #self.views do
      local view = self.views[i]
      if view then
         view:draw()
      end
   end
   if self.heldStack then
      FlexDrawHelper:drawHeldStack(self.heldStack, love.mouse.getPosition())
   end
end
```

**Summary:** 2 changes in `inventory_state_manager.lua`

---

## Step 3: Update machine_state_manager.lua

**File:** `sff/src/ui/machine_state_manager.lua`

### Change 1: Update Import (Line 1)

**BEFORE:**
```lua
local DrawHelper = require("src.helpers.draw_helper")
```

**AFTER:**
```lua
local FlexDrawHelper = require("src.ui.flex_draw_helper")
```

### Change 2: Update draw method (Line 168)

**BEFORE:**
```lua
function MachineStateManager:draw()
   -- Draw inventory views first (they appear below machine screen)
   for _, view in ipairs(self.views) do
      if view then
         view:draw()
      end
   end

   -- Draw machine screen on top
   if self.screen then
      self.screen:draw()
   end

   -- Draw held stack last (always on top)
   if self.heldStack then
      DrawHelper:drawHeldStack(self.heldStack, love.mouse.getPosition())
   end
end
```

**AFTER:**
```lua
function MachineStateManager:draw()
   -- Draw inventory views first (they appear below machine screen)
   for _, view in ipairs(self.views) do
      if view then
         view:draw()
      end
   end

   -- Draw machine screen on top
   if self.screen then
      self.screen:draw()
   end

   -- Draw held stack last (always on top)
   if self.heldStack then
      FlexDrawHelper:drawHeldStack(self.heldStack, love.mouse.getPosition())
   end
end
```

**Summary:** 2 changes in `machine_state_manager.lua`

---

## Step 4: Testing

After making the above changes, test the following:

### Test 1: Toolbar Rendering
1. Run the game: `love .`
2. Verify toolbar appears at bottom of screen
3. Verify slots are visible with borders
4. Verify items render correctly

**Expected:** Toolbar shows with FlexLove elements instead of DrawHelper

### Test 2: Player Inventory
1. Press inventory key (typically 'i' or 'e')
2. Verify inventory panel opens
3. Verify all slots are clickable
4. Close inventory

**Expected:** Inventory opens/closes smoothly

### Test 3: Item Interaction
1. Open inventory
2. Click on an item slot
3. Item should be picked up (mouse cursor hidden, held stack rendered)
4. Click on another slot
5. Item should be placed/swapped/stacked

**Expected:** Item dragging works with FlexDrawHelper rendering

### Test 4: Machine Screen
1. Interact with a machine entity
2. Machine screen should open with:
   - Machine name label
   - State label
   - Input/output slots
   - Mana bar (if entity has mana)
   - Progress bar (if processing)
   - Start button
3. Verify all elements render correctly

**Expected:** Machine screen shows all UI elements

### Test 5: Dynamic Updates
1. With machine screen open
2. Start a ritual/process
3. Verify progress bar animates
4. Verify mana bar updates
5. Verify state label changes

**Expected:** Dynamic content updates properly

### Test 6: Window Resize
1. Resize game window
2. Verify UI elements scale/reposition correctly

**Expected:** FlexLove handles resizing automatically

### Test 7: Slot Hit Detection
1. Open inventory or machine screen
2. Hover over slots
3. Click on slots
4. Verify correct slots are detected

**Expected:** FlexLove's hit detection works correctly

---

## Step 5: Cleanup (After Successful Testing)

Once all tests pass, remove the old files:

```bash
# Remove old UI classes
rm sff/src/ui/inventory_view.lua
rm sff/src/ui/machine_screen.lua

# Remove old helper
rm sff/src/helpers/draw_helper.lua
```

**IMPORTANT:** Only delete these files after confirming everything works!

---

## Troubleshooting

### Issue: UI doesn't appear

**Check:**
- Is `Flexlove.init()` called in `love.load()`?
- Is `Flexlove.update(dt)` called in `love.update()`?
- Is `Flexlove.draw()` called in `love.draw()`?

**Debug:**
```lua
-- In love.draw(), after Flexlove.draw():
print("Element count:", Flexlove.getStateCount())
```

### Issue: Slots not clickable

**Check:**
- Are elements using `positioning = "absolute"`?
- Is `userdata` set correctly on slot elements?
- Are elements being created in `buildUI()`?

**Debug:**
```lua
-- In getSlotUnderMouse():
local element = Flexlove.getElementAtPosition(mx, my)
print("Element at cursor:", element and element.id or "none")
```

### Issue: Held item not rendering

**Check:**
- Is `FlexDrawHelper:drawHeldStack()` being called in state manager's `draw()`?
- Is `heldStack` not nil?
- Is `love.mouse.getPosition()` returning valid coordinates?

**Debug:**
```lua
-- In InventoryStateManager:draw():
if self.heldStack then
   local mx, my = love.mouse.getPosition()
   print("Drawing held stack at:", mx, my)
   FlexDrawHelper:drawHeldStack(self.heldStack, mx, my)
end
```

### Issue: Bars not updating

**Check:**
- Is `screen:draw()` being called every frame?
- Are `manaBarFill` and `progressBarFill` elements created?
- Are entity components (Mana, ProcessingTimer) present?

**Debug:**
```lua
-- In FlexMachineScreen:updateManaBar():
print("Mana bar fill:", self.manaBarFill and "exists" or "nil")
if self.manaBarFill then
   print("New width:", barWidth * fillRatio)
end
```

### Issue: Elements positioned incorrectly after window resize

**Check:**
- Is `Flexlove.resize()` called in `love.resize()`?
- Are absolute positions recalculated in `setPosition()`?

**Fix:**
```lua
-- Add to love.resize():
function love.resize(w, h)
   Flexlove.resize()
   -- If needed, manually reposition UI elements
end
```

---

## Rollback Plan

If migration fails, revert changes:

```bash
# Using git:
git checkout -- sff/src/evolved/systems/render_ui_system.lua
git checkout -- sff/src/ui/inventory_state_manager.lua
git checkout -- sff/src/ui/machine_state_manager.lua

# The old files are still there, so the game will work with old system
```

---

## Performance Notes

### Before (DrawHelper)
- ~200-300 `love.graphics` calls per frame (depending on UI open)
- Manual drawing every frame
- No caching

### After (FlexLove)
- FlexLove batches rendering
- Elements only update when properties change
- Automatic dirty tracking
- Should be equal or better performance

**Benchmark:**
```lua
-- In love.draw():
local start = love.timer.getTime()
Flexlove.draw(function()
   process(STAGES.OnRender)
end)
local elapsed = (love.timer.getTime() - start) * 1000
print(string.format("Render time: %.2fms", elapsed))
```

---

## Migration Checklist

- [ ] Update `render_ui_system.lua` imports (5 changes)
- [ ] Update `inventory_state_manager.lua` (2 changes)
- [ ] Update `machine_state_manager.lua` (2 changes)
- [ ] Test toolbar rendering
- [ ] Test inventory open/close
- [ ] Test item dragging
- [ ] Test machine screen
- [ ] Test dynamic updates (bars)
- [ ] Test window resize
- [ ] Test slot hit detection
- [ ] Verify performance is acceptable
- [ ] Remove old files (after all tests pass)
- [ ] Update any other files that import old classes
- [ ] Commit changes

---

## Total Changes Summary

| File | Lines Changed | Type |
|------|---------------|------|
| `render_ui_system.lua` | 5 | Import + instantiation |
| `inventory_state_manager.lua` | 2 | Import + method |
| `machine_state_manager.lua` | 2 | Import + method |
| **Total** | **9 lines** | **Minimal changes** |

**New Files:**
- `flex_inventory_view.lua` (328 lines)
- `flex_machine_screen.lua` (566 lines)
- `flex_draw_helper.lua` (105 lines)

**Files to Remove (after testing):**
- `inventory_view.lua`
- `machine_screen.lua`
- `draw_helper.lua`

---

## Success Criteria

✅ All tests pass
✅ No visual regressions
✅ No gameplay regressions
✅ Performance equal or better
✅ Code is cleaner and more maintainable

---

## Need Help?

See `docs/FLEXLOVE_INTEGRATION.md` for detailed implementation guide.