--[[
   Update ZIndex System

   Syncs the ZIndex fragment from entity Position.y for Y-based depth sorting.
   Entities lower on screen (higher Y) render in front.

   Run in OnUpdate stage before rendering.
]]

local builder = Evolved.builder

builder()
   :name("SYSTEMS.UpdateZIndex")
   :group(STAGES.OnUpdate)
   :include(FRAGMENTS.Position, FRAGMENTS.ZIndex)
   :execute(function(chunk, entityIds, entityCount)
      local positions, zindices = chunk:components(
         FRAGMENTS.Position,
         FRAGMENTS.ZIndex
      )

      for i = 1, entityCount do
         zindices[i] = positions[i].y
      end
   end):build()
