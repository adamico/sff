local lg = love.graphics
local builder = Evolved.builder
local EntityDrawHelper = require("src.helpers.entity_draw_helper")

builder()
   :name("SYSTEMS.RenderEntities")
   :group(STAGES.OnRender)
   :include(TAGS.Visual)
   :execute(function(chunk, entityIds, entityCount)
      local positions, sizes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Size)
      local visuals = chunk:components(FRAGMENTS.Shape)
      local colors = chunk:components(FRAGMENTS.Color)
      local names = chunk:components(Evolved.NAME)

      for i = 1, entityCount do
         local id = entityIds[i]
         local name = names[i]
         local label = string.format("%s%d", name, id)

         EntityDrawHelper.drawShape(
            visuals[i],
            positions[i],
            sizes[i],
            colors[i],
            label
         )
      end
   end):build()
