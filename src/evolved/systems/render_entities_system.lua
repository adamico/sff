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
      local names = chunk:components(Evolved.NAME)

      for i = 1, entityCount do
         local px, py = positions[i]:split()
         local size = sizes[i]
         local visual = visuals[i]
         local color = colors[i]
         local name = names[i]

         lg.setColor(color)
         local labelX, labelY = px, py
         if visual == "circle" then
            labelY = labelY - size.x
            lg.circle("fill", px, py, size.x)
         elseif visual == "rectangle" then
            lg.rectangle("fill", px, py, size.x, size.y)
         end
         local entityInfo = string.format("%s (%d, %d)", name, px, py)
         lg.print(entityInfo, labelX, labelY - 16)
      end
   end):build()
