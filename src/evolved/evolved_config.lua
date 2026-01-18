local builder = Evolved.builder
local set = Evolved.set
local get = Evolved.get
local FPS = 60

local evolvedConfig = {}

-- ============================================================================
-- STAGES
-- ============================================================================
evolvedConfig.STAGES = {
   OnSetup = builder():name("STAGES.OnSetup"):build(),
   OnUpdate = builder():name("STAGES.OnUpdate"):build(),
   OnRenderDebug = builder():name("STAGES.OnRenderDebug"):build(),
   OnRender = builder():name("STAGES.OnRender"):build(),
}

-- ============================================================================
-- UNIFORMS (Singleton Fragments)
-- ============================================================================

--- Creates a uniform (singleton fragment) with getter/setter methods
--- @param name string The name of the uniform
--- @param defaultValue any The default value
--- @return table The uniform fragment and accessor methods
local function createUniform(name, defaultValue)
   local fragment = builder()
      :name(name)
      :default(defaultValue)
      :build()

   -- Initialize the singleton value
   set(fragment, fragment, defaultValue)

   return {
      fragment = fragment,
      get = function()
         return get(fragment, fragment)
      end,
      set = function(value)
         set(fragment, fragment, value)
      end,
   }
end

local DeltaTime = createUniform("UNIFORMS.DeltaTime", 1.0 / FPS)
local ShowHitboxes = createUniform("UNIFORMS.ShowHitboxes", true)

evolvedConfig.UNIFORMS = {
   DeltaTime = DeltaTime.fragment,
   ShowHitboxes = ShowHitboxes.fragment,

   getDeltaTime = DeltaTime.get,
   setDeltaTime = DeltaTime.set,

   getShowHitboxes = ShowHitboxes.get,
   setShowHitboxes = ShowHitboxes.set,

   toggleHitboxes = function()
      local current = ShowHitboxes.get()
      ShowHitboxes.set(not current)
      return not current
   end,
}

-- ============================================================================
-- FRAGMENTS (Populated by fragments.lua)
-- ============================================================================
evolvedConfig.FRAGMENTS = {}

-- ============================================================================
-- TAGS (Populated by fragments.lua)
-- ============================================================================
evolvedConfig.TAGS = {}

-- ============================================================================
-- ENTITIES (Populated at runtime by setup_systems)
-- ============================================================================
evolvedConfig.ENTITIES = {}

return evolvedConfig
