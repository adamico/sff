local DEFAULT_COLOR = Colors.WHITE
local lg = love.graphics

local RenderSystem = {}

function RenderSystem:init()
   -- pool is automatically set by nata
end

function RenderSystem:draw()
   for entityIndex, entity in ipairs(self.pool.groups.render.entities) do
      lg.setColor(entity.color or DEFAULT_COLOR)
      local ex, ey = entity.position.x, entity.position.y
      local labelX, labelY = ex, ey
      if entity.visual == "circle" then
         labelY = labelY - entity.size
         lg.circle("fill", ex, ey, entity.size)
      elseif entity.visual == "rectangle" then
         lg.rectangle("fill", ex, ey, entity.size.x, entity.size.y)
      end
      local entity_info = (entity.name or "").." "..entity.position.x..", "..entity.position.y
      lg.print(entity_info, labelX, labelY - 16)
   end

   lg.setColor(1, 1, 1, 1)
end

return RenderSystem
