local RenderSystem = Class("RenderSystem")

local DEFAULT_COLOR = Colors.WHITE

function RenderSystem:initialize(pool)
   self.pool = pool
end

function RenderSystem:draw()
   for entityIndex, entity in ipairs(self.pool.groups.render.entities) do
      love.graphics.setColor(entity.color or DEFAULT_COLOR)
      if entity.visual == "circle" then
         love.graphics.circle("fill", entity.position.x, entity.position.y, entity.size)
      elseif entity.visual == "square" then
         love.graphics.rectangle("fill", entity.position.x, entity.position.y, entity.size.x, entity.size.y)
      end
   end

   self.pool:on("player:interacted", function(entity)
      print("Player interacted with", entity, "at "..entity.position.x..", "..entity.position.y)
   end)
end

return RenderSystem
