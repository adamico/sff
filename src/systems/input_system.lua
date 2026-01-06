local InputHelper = require("src.helpers.input_helper")
local Bindings = require("src.config.input_bindings")

local InputSystem = {}

function InputSystem:init()
   self.edgeDetector = InputHelper.createEdgeDetector()
end

local function movementDetection(pool)
   local vector = Vector()
   if InputHelper.isActionPressed(Bindings.actions.MOVE_UP) then
      vector.y = -1
   elseif InputHelper.isActionPressed(Bindings.actions.MOVE_DOWN) then
      vector.y = 1
   end
   if InputHelper.isActionPressed(Bindings.actions.MOVE_LEFT) then
      vector.x = -1
   elseif InputHelper.isActionPressed(Bindings.actions.MOVE_RIGHT) then
      vector.x = 1
   end
   pool:emit("input:move", vector.normalized)
end

function InputSystem:update()
   movementDetection(self.pool)

   if self.edgeDetector:check(InputHelper.isActionPressed(Bindings.actions.OPEN_INVENTORY)) then
      self.pool:emit("input:open_inventory")
   end

   if self.edgeDetector:check(InputHelper.isActionPressed(Bindings.actions.INTERACT)) then
      self.pool:emit("input:interact")
   end
end

return InputSystem
