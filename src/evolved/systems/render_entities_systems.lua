local lg = love.graphics
local builder = Evolved.builder

builder()
   :name("SYSTEMS.RenderEntities")
   :group(STAGES.OnRender)
   :include(TAGS.Visual, TAGS.Physical)
   :execute(function(chunk, _, entityCount)
      local positions, sizes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Size)
      local visuals = chunk:components(FRAGMENTS.Shape)
      local colors = chunk:components(FRAGMENTS.Color)

      for i = 1, entityCount do
         local px, py = positions[i]:split()
         local size = sizes[i]
         local visual = visuals[i]
         local color = colors[i]

         lg.setColor(color)
         if visual == "circle" then
            lg.circle("fill", px, py, size.x)
         elseif visual == "rectangle" then
            lg.rectangle("fill", px, py, size.x, size.y)
         end
      end
   end):build()
