local builder = Evolved.builder
local FPS = 60

local evolved_config = {}

evolved_config.STAGES = {
   OnSetup = builder():name("STAGES.OnSetup"):build(),
   OnUpdate = builder():name("STAGES.OnUpdate"):build(),
   OnRender = builder():name("STAGES.OnRender"):build(),
}

evolved_config.UNIFORMS = {
   DeltaTime = 1.0 / FPS,
}

return evolved_config
