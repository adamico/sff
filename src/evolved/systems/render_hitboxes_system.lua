local lg = love.graphics
local builder = Evolved.builder
local EntityDrawHelper = require("src.helpers.entity_draw_helper")

builder()
   :name("SYSTEMS.RenderHitboxes")
   :group(STAGES.OnRender)
   :include(TAGS.Visual)
   :prologue(function()
      -- Skip hitbox rendering if disabled
      if not UNIFORMS.getShowHitboxes() then
         return true -- return true to skip system execution
      end
   end)
   :execute(function(chunk, entityIds, entityCount)
      local positions, sizes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Size)
      local hitboxShapes = chunk:components(FRAGMENTS.Shape)
      local hitboxColors = chunk:components(FRAGMENTS.Color)
      local names = chunk:components(Evolved.NAME)

      for i = 1, entityCount do
         local id = entityIds[i]
         local name = names[i]
         local label = string.format("%s%d", name, id)

         EntityDrawHelper.drawHitbox(
            hitboxShapes[i],
            positions[i],
            sizes[i],
            hitboxColors[i],
            label
         )
      end
   end):build()
