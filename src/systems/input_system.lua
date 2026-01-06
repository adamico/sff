local InputHelper = require("src.helpers.input_helper")

local InputSystem = {}

function InputSystem:init()
   self.edgeDetector = InputHelper.createEdgeDetector()
end

local function movementDetection(pool)
   local vector = Vector()
   if InputHelper.isActionPressed("move_up") then
      vector.y = -1
   elseif InputHelper.isActionPressed("move_down") then
      vector.y = 1
   end
   if InputHelper.isActionPressed("move_left") then
      vector.x = -1
   elseif InputHelper.isActionPressed("move_right") then
      vector.x = 1
   end
   pool:emit("input:move", vector.normalized)
end

function InputSystem:update()
   movementDetection(self.pool)

   if self.edgeDetector:check(InputHelper.isActionPressed("open_inventory")) then
      self.pool:emit("input:open_inventory")
   end

   if self.edgeDetector:check(InputHelper.isActionPressed("interact")) then
      self.pool:emit("input:interact")
   end
end

return InputSystem
