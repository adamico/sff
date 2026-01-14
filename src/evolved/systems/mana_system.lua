local builder = Evolved.builder

builder()
   :name("SYSTEMS.Mana")
   :group(STAGES.OnUpdate)
   :include(FRAGMENTS.Mana)
   :execute(function(chunk, _, entityCount)
      local manas = chunk:components(FRAGMENTS.Mana)
      local dt = UNIFORMS.getDeltaTime()

      for i = 1, entityCount do
         local mana = manas[i]
         local regenRate = mana.regenRate or 0

         if regenRate > 0 and mana.current < mana.max then
            mana.current = math.min(mana.current + regenRate * dt, mana.max)
         end
      end
   end):build()
