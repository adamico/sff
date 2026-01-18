-- ============================================================================
-- Render Mana System
-- ============================================================================
-- Renders mana bars above entities with the Damageable tag
-- Uses ManaBarView for consistent, customizable rendering

local ManaBarView = require("src.ui.mana_bar_view")
local builder = Evolved.builder

-- Create a shared mana bar renderer with default options
-- Can be customized by passing options: ManaBarView:new({ width = 60, ... })
local manaBarRenderer = ManaBarView:new()

builder()
   :name("SYSTEMS.RenderMana")
   :group(STAGES.OnRenderEntities)
   :include(FRAGMENTS.Mana)
   :execute(function(chunk, entityIds, entityCount)
      local positions, manas = chunk:components(FRAGMENTS.Position, FRAGMENTS.Mana)

      for i = 1, entityCount do
         local position = positions[i]
         local mana = manas[i]

         manaBarRenderer:draw(position, mana.current, mana.max)
      end
   end):build()
