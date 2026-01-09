local InputHelper = require("src.helpers.input_helper")
local Bindings = require("src.config.input_bindings")
local Events = require("src.config.events")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local A = Bindings.actions

local InputSystem = {}

function InputSystem:init()
   self.input = InputHelper.createActionDetector()
end

local function movementDetection(pool)
   local vector = Vector()
   if InputHelper.isActionPressed(A.MOVE_UP) then
      vector.y = -1
   elseif InputHelper.isActionPressed(A.MOVE_DOWN) then
      vector.y = 1
   end
   if InputHelper.isActionPressed(A.MOVE_LEFT) then
      vector.x = -1
   elseif InputHelper.isActionPressed(A.MOVE_RIGHT) then
      vector.x = 1
   end
   if InventoryStateManager.isOpen then
      vector.y = 0
      vector.x = 0
   end
   pool:emit(Events.INPUT_MOVED, vector.normalized)
end

function InputSystem:update()
   local pool = self.pool
   local player = pool.groups.controllable.entities[1]
   local mouse_x, mouse_y = love.mouse.getX(), love.mouse.getY()
   movementDetection(pool)

   if self.input:pressed(A.OPEN_INVENTORY) and not InventoryStateManager.isOpen then
      pool:emit(Events.INPUT_INVENTORY_OPENED, player)
   end

   if self.input:pressed(A.CLOSE_INVENTORY) then
      pool:emit(Events.INPUT_INVENTORY_CLOSED)
   end

   if self.input:pressed(A.INTERACT) then
      if InventoryStateManager.isOpen then
         pool:emit(Events.INPUT_INVENTORY_CLICKED, {mouse_x = mouse_x, mouse_y = mouse_y})
      else
         pool:emit(Events.INPUT_INTERACTED, {mouse_x = mouse_x, mouse_y = mouse_y})
      end
   end
end

return InputSystem
