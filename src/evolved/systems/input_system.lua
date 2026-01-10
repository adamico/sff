local InputHelper = require("src.helpers.input_helper")
local InventoryStateManager = require("src.ui.inventory_state_manager")
local builder = Evolved.builder
local A = require("src.config.input_bindings").actions
trigger = Beholder.trigger

local function movementDetection(chunk, entityCount)
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

   local inputVectors = chunk:components(FRAGMENTS.Input)

   for i = 1, entityCount do
      local inputVector = inputVectors[i]
      inputVector = Vector(vector.x, vector.y).normalized
      inputVectors[i] = inputVector
   end
end

local actionDetector

local function getActionDetector()
   if not actionDetector then
      actionDetector = InputHelper.createActionDetector()
   end

   return actionDetector
end

local function actionDetection(playerInventory, playerToolbar)
   local mx, my = love.mouse.getX(), love.mouse.getY()
   actionDetector = getActionDetector()

   if actionDetector:pressed(A.OPEN_INVENTORY) and not InventoryStateManager.isOpen then
      trigger(Events.INPUT_INVENTORY_OPENED, playerInventory, playerToolbar)
   end

   if actionDetector:pressed(A.CLOSE_INVENTORY) then
      trigger(Events.INPUT_INVENTORY_CLOSED)
   end

   if actionDetector:pressed(A.INTERACT) then
      if InventoryStateManager.isOpen then
         trigger(Events.INPUT_INVENTORY_CLICKED, mx, my)
      else
         trigger(Events.INPUT_INTERACTED, mx, my)
      end
   end
end

builder()
   :name("SYSTEMS.PlayerInput")
   :group(STAGES.OnUpdate)
   :include(FRAGMENTS.Input)
   :execute(function(chunk, _, entityCount)
      movementDetection(chunk, entityCount)
      local playerInventories = chunk:components(FRAGMENTS.Inventory)
      local playerToolbars = chunk:components(FRAGMENTS.Toolbar)
      for i = 1, entityCount do
         actionDetection(playerInventories[i], playerToolbars[i])
      end
   end):build()
