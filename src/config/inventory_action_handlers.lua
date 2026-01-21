-- ============================================================================
-- Inventory Actions
-- ============================================================================
-- Defines action names, input-to-action mapping, and action handlers

local MOUSE_BUTTON_LEFT = 1
local MOUSE_BUTTON_RIGHT = 2

-- ============================================================================
-- Action Names
-- ============================================================================

local Actions = {
   PICK_HALF      = "pick_half",
   PICK_ONE       = "pick_one",
   PICK_OR_PLACE  = "pick_or_place",
   QUICK_TRANSFER = "quick_transfer",
   COLLECT_STACK  = "collect_stack",
}

-- ============================================================================
-- Input Mapping
-- ============================================================================

--- Get the current state of shift and ctrl keys
--- @return table
local function getModifiers()
   return {
      shift = love.keyboard.isDown("lshift", "rshift"),
      ctrl = love.keyboard.isDown("lctrl", "rctrl"),
   }
end

--- Determine the action based on mouse button, modifiers, and double-click state
--- @param mouseButton number
--- @param modifiers table
--- @return string|nil
local function getMouseAction(mouseButton, modifiers)
   local shift = modifiers.shift
   local ctrl = modifiers.ctrl
   local isDoubleClick = modifiers.isDoubleClick

   if mouseButton == MOUSE_BUTTON_LEFT then
      if isDoubleClick then
         return Actions.COLLECT_STACK
      elseif shift then
         return Actions.QUICK_TRANSFER
      else
         return Actions.PICK_OR_PLACE
      end
   elseif mouseButton == MOUSE_BUTTON_RIGHT then
      if ctrl then
         return Actions.PICK_ONE
      else
         return Actions.PICK_HALF
      end
   end

   return nil
end

-- ============================================================================
-- Action Handlers
-- ============================================================================

local Handlers = {
   [Actions.PICK_HALF] = function(self, slotInfo)
      return self:pickHalf(slotInfo)
   end,
   [Actions.PICK_ONE] = function(self, slotInfo)
      return self:pickOne(slotInfo)
   end,
   [Actions.PICK_OR_PLACE] = function(self, slotInfo)
      return self:pickOrPlace(slotInfo)
   end,
   [Actions.QUICK_TRANSFER] = function(self, slotInfo)
      return self:quickTransfer(slotInfo)
   end,
   [Actions.COLLECT_STACK] = function(self, slotInfo)
      return self:collectStack(slotInfo)
   end,
}

-- ============================================================================
-- Module Export
-- ============================================================================

return {
   Actions = Actions,
   Handlers = Handlers,
   getMouseAction = getMouseAction,
   getModifiers = getModifiers,
}
