local builder = Evolved.builder
local set = Evolved.set
local get = Evolved.get
local FPS = 60

local evolved_config = {}

evolved_config.STAGES = {
   OnSetup = builder():name("STAGES.OnSetup"):build(),
   OnUpdate = builder():name("STAGES.OnUpdate"):build(),
   OnRender = builder():name("STAGES.OnRender"):build(),
}

-- Create UNIFORMS as singleton fragments (fragments attached to themselves)
local DeltaTime = builder()
   :name("UNIFORMS.DeltaTime")
   :default(1.0 / FPS)
   :build()

-- Initialize singleton values
set(DeltaTime, DeltaTime, 1.0 / FPS)

evolved_config.UNIFORMS = {
   DeltaTime = DeltaTime,

   -- Getter for DeltaTime value
   getDeltaTime = function()
      return get(DeltaTime, DeltaTime)
   end,

   -- Setter for DeltaTime value
   setDeltaTime = function(value)
      set(DeltaTime, DeltaTime, value)
   end,
}

return evolved_config
