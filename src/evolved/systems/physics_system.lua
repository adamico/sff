local builder = Evolved.builder

builder()
   :name("SYSTEMS.Physics")
   :group(STAGES.OnUpdate)
   :include(TAGS.Physical)
   :execute(function(chunk, _, entityCount)
      local deltaTime = UNIFORMS.getDeltaTime()
      local positions, velocities = chunk:components(FRAGMENTS.Position, FRAGMENTS.Velocity)

      for i = 1, entityCount do
         local position = positions[i]
         local velocity = velocities[i]
         position = position + velocity * deltaTime
         positions[i] = position
      end
   end):build()
