--[[
   Render Entities System

   Handles animation updates and rendering for entities with the Animated tag.
   Uses peachy library for Aseprite spritesheet animation support.

   Responsibilities:
   - Update animation state based on entity velocity
   - Advance animation frames each tick
   - Draw sprites at entity positions
]]

local Animation = require("src.evolved.fragments.animation")
local builder = Evolved.builder

-- Movement threshold for determining if entity is moving
local MOVEMENT_THRESHOLD = 0.1

-- Running speed threshold (entities moving faster than this are "running")
local RUN_SPEED_THRESHOLD = 150

--- Determine if entity is moving based on velocity
--- @param velocity table Velocity vector
--- @return boolean
local function isMoving(velocity)
   return math.abs(velocity.x) > MOVEMENT_THRESHOLD or
      math.abs(velocity.y) > MOVEMENT_THRESHOLD
end

--- Determine if entity is running based on speed
--- @param velocity table Velocity vector
--- @return boolean
local function isRunning(velocity)
   local speed = math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
   return speed > RUN_SPEED_THRESHOLD
end

-- Create query for visual entities
local animatedQuery = builder()
   :name("QUERIES.Animated")
   :include(TAGS.Animated)
   :build()

-- Update system - handles animation state updates
builder()
   :name("SYSTEMS.UpdateEntityAnimations")
   :group(STAGES.OnUpdate)
   :include(TAGS.Animated)
   :execute(function(chunk, entityIds, entityCount)
      local animations, velocities, positions = chunk:components(
         FRAGMENTS.Animation,
         FRAGMENTS.Velocity,
         FRAGMENTS.Position
      )

      local dt = love.timer.getDelta()

      for i = 1, entityCount do
         local animation = animations[i]
         local velocity = velocities[i]

         if animation and animation.spritesheets then
            if velocity then
               Animation.setDirectionFromVelocity(animation, velocity.x, velocity.y)

               local moving = isMoving(velocity)
               local running = isRunning(velocity)

               local attacking = animation.isAttacking or false
               Animation.setStateFromMovement(animation, moving, running, attacking)
            end

            Animation.update(animation, dt)
         end
      end
   end):build()

-- Render animated entities - draws peachy sprites
builder()
   :name("SYSTEMS.RenderAnimatedEntities")
   :group(STAGES.OnRenderEntities)
   :include(TAGS.Animated)
   :execute(function(chunk, entityIds, entityCount)
      local animations, positions = chunk:components(
         FRAGMENTS.Animation,
         FRAGMENTS.Position
      )

      for i = 1, entityCount do
         local animation = animations[i]
         local position = positions[i]
         if animation and position and animation.spritesheets then
            Animation.draw(animation, math.ceil(position.x), math.ceil(position.y))
         end
      end
   end):build()

-- Render static entities - draws quad-based sprites
local Sprite = require("src.evolved.fragments.sprite")

builder()
   :name("SYSTEMS.RenderStaticSprites")
   :group(STAGES.OnRenderEntities)
   :include(TAGS.Static)
   :execute(function(chunk, entityIds, entityCount)
      local sprites, positions = chunk:components(
         FRAGMENTS.Sprite,
         FRAGMENTS.Position
      )

      for i = 1, entityCount do
         local sprite = sprites[i]
         local position = positions[i]
         if sprite and position then
            Sprite.draw(sprite, math.ceil(position.x), math.ceil(position.y))
         end
      end
   end):build()
