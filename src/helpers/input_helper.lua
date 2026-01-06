local InputHelper = {}
local lk = love.keyboard

--- Creates and edge detector for detecting rising edges (press events)
--- @param options table|nil Options: {threshold = number}
--- @return table EdgeDetector with methods: check(isPressed)
function InputHelper.createEdgeDetector(options)
   options = options or {}
   local threshold = options.threshold or 0.1

   return {
      wasPressed = false,
      lastPressTime = 0,

      --- Checks if the input has been pressed since the last check
      --- @param isPressed boolean Whether the input is currently pressed
      --- @return boolean Whether the input was pressed since the last check
      check = function(self, isPressed)
         local triggered = false
         local currentTime = love.timer.getTime()

         if isPressed and not self.wasPressed then
            if (currentTime - self.lastPressTime) > threshold then
               self.lastPressTime = currentTime
               triggered = true
            end
         end

         self.wasPressed = isPressed
         return triggered
      end
   }
end

--- Checks if an action is currently pressed
--- @param action string The action to check
--- @return boolean Whether the action is currently pressed
function InputHelper.isActionPressed(action)
   local binding = Bindings.actionsToKeys[action]
   if not binding then return false end

   if binding.type == "key" then
      return lk.isScancodeDown(binding.scancode)
   elseif binding.type == "mouse" then
      return love.mouse.isDown(binding.button)
   end

   return false
end

return InputHelper
