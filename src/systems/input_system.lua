local InputHelper = require("src.helpers.input_helper")
local Bindings = require("src.config.input_bindings")
local Events = require("src.config.events")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local A = Bindings.actions

local InputSystem = {}

function InputSystem:init()
   self.input = InputHelper.createEdgeDetector()
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
   pool:emit(Events.INPUT_MOVE, vector.normalized)
end

function InputSystem:update()
   local input = self.input
   local pool = self.pool
   local player = pool.groups.controllable.entities[1]

   movementDetection(pool)

   if input:pressed(A.OPEN_INVENTORY) and not InventoryStateManager.isOpen then
      pool:emit(Events.INPUT_OPEN_INVENTORY, player)
   end

   if input:pressed(A.CLOSE_INVENTORY) then
      pool:emit(Events.INPUT_CLOSE_INVENTORY)
   end

   if input:pressed(A.INTERACT) then
      if InventoryStateManager.isOpen then
         pool:emit(Events.INPUT_INVENTORY_CLICK, Bindings.actionsToKeys[A.INTERACT].button)
      else
         pool:emit(Events.INPUT_INTERACT)
      end
   end
end

return InputSystem
