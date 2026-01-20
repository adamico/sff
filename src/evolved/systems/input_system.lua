local InputHelper = require("src.helpers.input_helper")
local CameraHelper = require("src.helpers.camera_helper")
local UIState = require("src.helpers.ui_state_machine")

local builder = Evolved.builder
local execute = Evolved.execute
local get = Evolved.get
local set = Evolved.set
local observe = Beholder.observe
local trigger = Beholder.trigger

local TOOLBAR_KEYS_MAX = 9
local A = require("src.config.input_bindings").actions

-------------------------------------------------------------------------------
-- ACTION DETECTOR
-------------------------------------------------------------------------------
local actionDetector

local function getActionDetector()
   if not actionDetector then
      actionDetector = InputHelper.createActionDetector()
   end
   return actionDetector
end

-------------------------------------------------------------------------------
-- STATE-SPECIFIC ACTION HANDLERS
-------------------------------------------------------------------------------

--- Handle actions when in "exploring" state (normal gameplay)
local function handleExploringActions(mx, my, playerInventory, playerToolbar, playerEquipment)
   if actionDetector:pressed(A.OPEN_INVENTORY) then
      trigger(Events.INPUT_INVENTORY_OPENED, playerInventory, playerToolbar, playerEquipment)
   end

   if actionDetector:pressed(A.INTERACT) then
      trigger(Events.INPUT_INTERACTED, mx, my)
   end

   for i = 0, TOOLBAR_KEYS_MAX do
      if actionDetector:pressed(A["TOOLBAR_USE_"..i]) then
         trigger(Events.TOOLBAR_SLOT_ACTIVATED, i)
      end
   end
end

--- Handle actions when in "placing" state (entity placement mode)
local function handlePlacingActions()
   if actionDetector:pressed(A.CANCEL_PLACEMENT) then
      trigger(Events.PLACEMENT_CLICKED, 2)
   elseif actionDetector:pressed(A.INTERACT) then
      trigger(Events.PLACEMENT_CLICKED, 1)
   end
end

--- Handle actions available in all states
local function handleGlobalActions(mx, my)
   if actionDetector:pressed(A.CLOSE_INVENTORY) then
      trigger(Events.UI_MODAL_CLOSED)
   end

   if actionDetector:pressed(A.WEAPON_USE) then
      trigger(Events.WEAPON_ACTIVATED, mx, my)
   end

   if actionDetector:pressed(A.TOGGLE_HITBOXES) then
      UNIFORMS.toggleHitboxes()
   end
end

-------------------------------------------------------------------------------
-- STATE DISPATCH TABLE
-------------------------------------------------------------------------------
local stateHandlers = {
   exploring = handleExploringActions,
   placing = handlePlacingActions,
}

-------------------------------------------------------------------------------
-- MOVEMENT DETECTION
-------------------------------------------------------------------------------
local function movementDetection(chunk, entityCount)
   local vector = Vector()

   -- Only allow movement in exploring state
   if UIState:is("exploring") then
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
   end

   local inputVectors = chunk:components(FRAGMENTS.Input)

   for i = 1, entityCount do
      local inputVector = inputVectors[i]
      inputVector = Vector(vector.x, vector.y).normalized
      inputVectors[i] = inputVector
   end

   trigger(Events.INPUT_VECTOR_CHANGED)
end

-------------------------------------------------------------------------------
-- ACTION DETECTION (main entry point)
-------------------------------------------------------------------------------
local function actionDetection(playerInventory, playerToolbar, playerEquipment)
   local _, screenX, screenY = shove.mouseToViewport()
   local mx, my = CameraHelper.screenToWorld(screenX, screenY)
   actionDetector = getActionDetector()

   -- Dispatch to current state handler
   local handler = stateHandlers[UIState.current]
   if handler then
      handler(mx, my, playerInventory, playerToolbar, playerEquipment)
   end

   -- Always-available actions
   handleGlobalActions(mx, my)
end

-------------------------------------------------------------------------------
-- SYSTEM REGISTRATION
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- VELOCITY UPDATE (observes INPUT_VECTOR_CHANGED)
-------------------------------------------------------------------------------
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
