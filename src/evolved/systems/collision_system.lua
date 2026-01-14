--[[
   Collision System

   Detects and resolves collisions between entities with the Physical tag.
   Runs after physics to prevent overlapping entities.

   - Circle-circle, rectangle-rectangle, and circle-rectangle collisions
   - Moving entities are pushed away from static/other entities
   - Static entities (zero velocity) don't get pushed
]]

local CollisionHelper = require("src.helpers.collision_helper")
local builder = Evolved.builder
local execute = Evolved.execute
local get = Evolved.get
local set = Evolved.set

-- Query for all physical entities
local physicalQuery = builder()
   :name("QUERIES.Physical")
   :include(TAGS.Physical)
   :build()

--- Check if an entity is static (has zero or near-zero velocity)
--- @param velocity table Velocity vector
--- @return boolean
local function isStatic(velocity)
   local threshold = 0.001
   return math.abs(velocity.x) < threshold and math.abs(velocity.y) < threshold
end

--- Collect all physical entities with their bounds
--- @return table Array of { id, bounds, position, velocity, isStatic }
local function collectEntities()
   local entities = {}

   for chunk, entityIds, entityCount in execute(physicalQuery) do
      local positions, velocities, hitboxes = chunk:components(
         FRAGMENTS.Position,
         FRAGMENTS.Velocity,
         FRAGMENTS.Hitbox
      )

      for i = 1, entityCount do
         local id = entityIds[i]
         local position = positions[i]
         local velocity = velocities[i]
         local hitbox = hitboxes[i]

         local bounds = CollisionHelper.getHitboxBounds(position, hitbox)

         table.insert(entities, {
            id = id,
            bounds = bounds,
            position = position,
            velocity = velocity,
            isStatic = isStatic(velocity),
         })
      end
   end

   return entities
end

--- Resolve collision between two entities
--- @param entityA table Entity data
--- @param entityB table Entity data
local function resolveCollision(entityA, entityB)
   if not CollisionHelper.areColliding(entityA.bounds, entityB.bounds) then
      return
   end

   local pushX, pushY = CollisionHelper.getPushVector(entityA.bounds, entityB.bounds)

   if pushX == 0 and pushY == 0 then
      return
   end

   -- Determine how to distribute the push
   if entityA.isStatic and entityB.isStatic then
      -- Both static, no push applied
      return
   elseif entityA.isStatic then
      -- Only B moves
      local newPos = Vector(
         entityB.position.x - pushX,
         entityB.position.y - pushY
      )
      set(entityB.id, FRAGMENTS.Position, newPos)
   elseif entityB.isStatic then
      -- Only A moves
      local newPos = Vector(
         entityA.position.x + pushX,
         entityA.position.y + pushY
      )
      set(entityA.id, FRAGMENTS.Position, newPos)
   else
      -- Both move, split the push
      local newPosA = Vector(
         entityA.position.x + pushX * 0.5,
         entityA.position.y + pushY * 0.5
      )
      local newPosB = Vector(
         entityB.position.x - pushX * 0.5,
         entityB.position.y - pushY * 0.5
      )
      set(entityA.id, FRAGMENTS.Position, newPosA)
      set(entityB.id, FRAGMENTS.Position, newPosB)
   end
end

builder()
   :name("SYSTEMS.Collision")
   :group(STAGES.OnUpdate)
   :epilogue(function()
      local entities = collectEntities()
      local count = #entities

      -- Pairwise collision detection and resolution
      for i = 1, count - 1 do
         for j = i + 1, count do
            resolveCollision(entities[i], entities[j])
         end
      end
   end):build()
