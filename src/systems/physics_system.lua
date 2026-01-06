local PhysicsSystem = {}
local EntityHelper = require("src.helpers.entity_helper")

function PhysicsSystem:init()
   self.pool:on("input:move", function(vector)
      for _entityIndex, entity in ipairs(self.pool.groups.controllable.entities) do
         entity.velocity = vector * entity.maxSpeed
      end
   end)
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
            if EntityHelper.areColliding(entity, otherEntity) then
               self.pool:emit("collide", entity, otherEntity)
               self.pool:emit("collide", otherEntity, entity)
            end
         end
      end
   end
end

return PhysicsSystem
