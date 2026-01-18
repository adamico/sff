local InputHelper = require("src.helpers.input_helper")
local InventoryStateManager = require("src.managers.inventory_state_manager")
local MachineStateManager = require("src.managers.machine_state_manager")
local EntityPlacementManager = require("src.managers.entity_placement_manager")
local builder = Evolved.builder
local execute = Evolved.execute
local get = Evolved.get
local set = Evolved.set
local observe = Beholder.observe
local trigger = Beholder.trigger

local TOOLBAR_KEYS_MAX = 9

local A = require("src.config.input_bindings").actions

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

   trigger(Events.INPUT_VECTOR_CHANGED)
end

local actionDetector

local function getActionDetector()
   if not actionDetector then
      actionDetector = InputHelper.createActionDetector()
   end

   return actionDetector
end

local function actionDetection(playerInventory, playerToolbar, playerEquipment)
   local inViewport, mx, my = shove.mouseToViewport()
   actionDetector = getActionDetector()

   if actionDetector:pressed(A.OPEN_INVENTORY) and not InventoryStateManager.isOpen then
      trigger(Events.INPUT_INVENTORY_OPENED, playerInventory, playerToolbar, playerEquipment)
   end

   if actionDetector:pressed(A.CLOSE_INVENTORY) then
      trigger(Events.INPUT_INVENTORY_CLOSED)
   end

   if actionDetector:pressed(A.INTERACT) then
      if EntityPlacementManager.isPlacing then
         EntityPlacementManager:handleClick(1)
      elseif not InventoryStateManager.isOpen and not MachineStateManager.isOpen then
         trigger(Events.INPUT_INTERACTED, mx, my)
      end
   end

   if actionDetector:pressed(A.CANCEL_PLACEMENT) then
      if EntityPlacementManager.isPlacing then
         EntityPlacementManager:handleClick(2)
      end
   end

   for i = 0, TOOLBAR_KEYS_MAX do
      if actionDetector:pressed(A["TOOLBAR_USE_"..i])
         and not InventoryStateManager.isOpen and not MachineStateManager.isOpen then
         trigger(Events.TOOLBAR_SLOT_ACTIVATED, i)
      end
   end

   if actionDetector:pressed(A.WEAPON_USE) then
      trigger(Events.WEAPON_ACTIVATED, mx, my)
   end

   -- Debug: Toggle hitbox visibility
   if actionDetector:pressed(A.TOGGLE_HITBOXES) then
      UNIFORMS.toggleHitboxes()
   end
end

builder()
   :name("SYSTEMS.PlayerInput")
   :group(STAGES.OnUpdate)
   :include(TAGS.Controllable)
   :execute(function(chunk, _, entityCount)
      movementDetection(chunk, entityCount)
      local playerInventories = chunk:components(FRAGMENTS.Inventory)
      local playerToolbars = chunk:components(FRAGMENTS.Toolbar)
      local playerEquipments = chunk:components(FRAGMENTS.Equipment)
      for i = 1, entityCount do
         actionDetection(playerInventories[i], playerToolbars[i], playerEquipments[i])
      end
   end):build()

local controllableQuery = builder()
   :name("QUERIES.Controllable")
   :include(TAGS.Controllable)
   :build()

local function updateControllableVelocity()
   for _chunk, entityIds, entityCount in execute(controllableQuery) do
      for i = 1, entityCount do
         local entityId = entityIds[i]
         local inputVector = get(entityId, FRAGMENTS.Input)
         local maxSpeed = get(entityId, FRAGMENTS.MaxSpeed)
         set(entityId, FRAGMENTS.Velocity, inputVector * maxSpeed)
      end
   end
end

observe(Events.INPUT_VECTOR_CHANGED, updateControllableVelocity)
