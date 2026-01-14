local builder = Evolved.builder
local set = Evolved.set
local get = Evolved.get
local FPS = 60

local evolvedConfig = {}

evolvedConfig.STAGES = {
   OnSetup = builder():name("STAGES.OnSetup"):build(),
   OnUpdate = builder():name("STAGES.OnUpdate"):build(),
   OnRender = builder():name("STAGES.OnRender"):build(),
}

-- Create UNIFORMS as singleton fragments (fragments attached to themselves)
local DeltaTime = builder()
   :name("UNIFORMS.DeltaTime")
   :default(1.0 / FPS)
   :build()

local ShowHitboxes = builder()
   :name("UNIFORMS.ShowHitboxes")
   :default(true)
   :build()

-- Initialize singleton values
set(DeltaTime, DeltaTime, 1.0 / FPS)
set(ShowHitboxes, ShowHitboxes, true)

evolvedConfig.UNIFORMS = {
   DeltaTime = DeltaTime,
   ShowHitboxes = ShowHitboxes,

   -- Getter for DeltaTime value
   getDeltaTime = function()
      return get(DeltaTime, DeltaTime)
   end,

   -- Setter for DeltaTime value
   setDeltaTime = function(value)
      set(DeltaTime, DeltaTime, value)
   end,

   -- Getter for ShowHitboxes value
   getShowHitboxes = function()
      return get(ShowHitboxes, ShowHitboxes)
   end,

   -- Setter for ShowHitboxes value
   setShowHitboxes = function(value)
      set(ShowHitboxes, ShowHitboxes, value)
   end,

   -- Toggle hitbox visibility
   toggleHitboxes = function()
      local current = get(ShowHitboxes, ShowHitboxes)
      set(ShowHitboxes, ShowHitboxes, not current)
      return not current
   end,
}

return evolvedConfig
