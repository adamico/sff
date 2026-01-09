local InputHelper = require("src.helpers.input_helper")
local A = require("src.config.input_bindings").actions
local builder = Evolved.builder

builder()
   :name("SYSTEMS.PlayerInput")
   :group(STAGES.OnUpdate)
   :include(FRAGMENTS.Input)
   :execute(function(chunk, _, entityCount)
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
   end):build()

builder()
   :name("SYSTEMS.Movement")
   :group(STAGES.OnUpdate)
   :include(TAGS.Physical, TAGS.Controllable)
   :execute(function(chunk, _, entityCount)
      local deltaTime = UNIFORMS.DeltaTime
      local positions, velocities = chunk:components(FRAGMENTS.Position, FRAGMENTS.Velocity)
      local maxSpeeds = chunk:components(FRAGMENTS.MaxSpeed)
      local inputVectors = chunk:components(FRAGMENTS.Input)

      for i = 1, entityCount do
         local position = positions[i]
         local velocity = velocities[i]
         local inputVector = inputVectors[i]
         local maxSpeed = maxSpeeds[i]
         velocity = inputVector * maxSpeed
         position = position + velocity * deltaTime
         positions[i] = position
      end
   end):build()
