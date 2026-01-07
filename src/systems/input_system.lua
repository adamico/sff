local InputHelper = require("src.helpers.input_helper")
local Bindings = require("src.config.input_bindings")
local Events = require("src.config.events")
local InventoryStateManager = require("src.ui.inventory_state_manager")

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
   pool:emit(Events.INPUT_MOVE, vector.normalized)
end

function InputSystem:update()
   movementDetection(self.pool)

   if self.edgeDetector:check(InputHelper.isActionPressed(Bindings.actions.OPEN_INVENTORY)) then
      self.pool:emit(Events.INPUT_OPEN_INVENTORY, self.pool.groups.controllable.entities[1])
   end

   if self.edgeDetector:check(InputHelper.isActionPressed(Bindings.actions.CLOSE_INVENTORY)) then
      self.pool:emit(Events.INPUT_CLOSE_INVENTORY)
   end

   if self.edgeDetector:check(InputHelper.isActionPressed(Bindings.actions.INTERACT)) then
      if InventoryStateManager.isOpen then
         self.pool:emit(Events.INPUT_INVENTORY_CLICK)
      else
         self.pool:emit(Events.INPUT_INTERACT)
      end
   end
end

return InputSystem
