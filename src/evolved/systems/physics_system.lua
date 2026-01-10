local builder = Evolved.builder

builder()
   :name("SYSTEMS.Physics")
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
