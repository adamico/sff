local PhysicsSystem = Class("PhysicsSystem")

local function isCircleColliding(a, b)
   return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 < (a.r + b.r) ^ 2
end

function PhysicsSystem:initialize(pool)
   self.pool = pool
end

function PhysicsSystem:update(dt)
   self:move(dt)
   self:collide()
end

function PhysicsSystem:move(dt)
   for _entityIndex, entity in ipairs(self.pool.groups.physics.entities) do
      entity.position = entity.position + entity.velocity * dt
   end
end

function PhysicsSystem:collide()
   for entityIndex, entity in ipairs(self.pool.groups.physics.entities) do
      for otherEntityIndex, otherEntity in ipairs(self.pool.groups.physics.entities) do
         if entityIndex ~= otherEntityIndex then
            if isCircleColliding(entity, otherEntity) then
               self.pool:emit("collide", entity, otherEntity)
               self.pool:emit("collide", otherEntity, entity)
            end
         end
      end
   end
end

return PhysicsSystem
