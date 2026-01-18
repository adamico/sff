local A = require("src.config.inventory_action_handlers").Actions

local InventoryInputHandler = {}

local MOUSE_BUTTON_LEFT = 1
local MOUSE_BUTTON_RIGHT = 2

--- Determine the action based on mouse button and modifiers
--- @param mouseButton number
--- @param modifiers table
--- @return string|nil
function InventoryInputHandler.getAction(mouseButton, modifiers)
   local shift = modifiers.shift
   local ctrl = modifiers.ctrl

   if mouseButton == MOUSE_BUTTON_LEFT then
      if shift then
         return A.QUICK_TRANSFER
      else
         return A.PICK_OR_PLACE
      end
   elseif mouseButton == MOUSE_BUTTON_RIGHT then
      if ctrl then
         return A.PICK_ONE
      else
         return A.PICK_HALF
      end
   end

   return nil
end

--- Get the current state of shift and ctrl keys
--- @return table
function InventoryInputHandler.getModifiers()
   return {
      shift = love.keyboard.isDown("lshift", "rshift"),
      ctrl = love.keyboard.isDown("lctrl", "rctrl"),
   }
end

return InventoryInputHandler
