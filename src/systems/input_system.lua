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
   if InventoryStateManager.isOpen then return end

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
   pool:emit(Events.INPUT_MOVE, vector.normalized)
end

function InputSystem:update()
   local pool = self.pool
   local player = pool.groups.controllable.entities[1]
   local mouse_x, mouse_y = love.mouse.getX(), love.mouse.getY()
   movementDetection(pool)

   if self.input:pressed(A.OPEN_INVENTORY) and not InventoryStateManager.isOpen then
      pool:emit(Events.INPUT_OPEN_INVENTORY, player)
   end

   if self.input:pressed(A.CLOSE_INVENTORY) then
      pool:emit(Events.INPUT_CLOSE_INVENTORY)
   end

   if self.input:pressed(A.INTERACT) then
      if InventoryStateManager.isOpen then
         pool:emit(Events.INPUT_INVENTORY_CLICK, {mouse_x = mouse_x, mouse_y = mouse_y})
      else
         pool:emit(Events.INPUT_INTERACT, {mouse_x = mouse_x, mouse_y = mouse_y})
      end
   end
end

return InputSystem
