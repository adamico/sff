local Class = require("lib.middleclass")

local RenderSystem = Class("RenderSystem")

local DEFAULT_COLOR = {255, 255, 255}

function RenderSystem:initialize(pool)
   self.pool = pool
end

function RenderSystem:draw()
   for entityIndex, entity in ipairs(self.pool.groups.physics.entities) do
      love.graphics.setColor(entity.color or DEFAULT_COLOR)
      love.graphics.circle("fill", entity.position.x, entity.position.y, entity.r, entity.segments or 64)
   end
end

return RenderSystem
