local RenderSystem = Class("RenderSystem")

local DEFAULT_COLOR = Colors.WHITE

function RenderSystem:initialize(pool)
   self.pool = pool
end

function RenderSystem:draw()
   for entityIndex, entity in ipairs(self.pool.groups.physics.entities) do
      love.graphics.setColor(entity.color or DEFAULT_COLOR)
      if entity.visual == "circle" then
         love.graphics.circle("fill", entity.position.x, entity.position.y, entity.size)
      elseif entity.visual == "square" then
         love.graphics.rectangle("fill", entity.position.x, entity.position.y, entity.size.x, entity.size.y)
      end
   end
end

return RenderSystem
