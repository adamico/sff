-- ============================================================================
-- Render Health System
-- ============================================================================
-- Renders health bars above entities with the Damageable tag
-- Uses HealthBarView for consistent, customizable rendering

local HealthBarView = require("src.ui.health_bar_view")
local builder = Evolved.builder

-- Create a shared health bar renderer with default options
-- Can be customized by passing options: HealthBarView:new({ width = 60, ... })
local healthBarRenderer = HealthBarView:new()

builder()
   :name("SYSTEMS.RenderHealth")
   :group(STAGES.OnRender)
   :include(TAGS.Damageable)
   :execute(function(chunk, entityIds, entityCount)
      local positions, healths = chunk:components(FRAGMENTS.Position, FRAGMENTS.Health)

      for i = 1, entityCount do
         local position = positions[i]
         local health = healths[i]

         healthBarRenderer:draw(position, health.current, health.max)
      end
   end):build()
