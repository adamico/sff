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

-- Render list for collecting entities before sorting
local renderList = {}

-- Collection system - gathers all renderable entities with ZIndex
builder()
   :name("SYSTEMS.SortEntities")
   :group(STAGES.OnRenderEntities)
   :include(FRAGMENTS.ZIndex)
   :execute(function(chunk, entityIds, entityCount)
      local positions, zindices, animations, sprites = chunk:components(
         FRAGMENTS.Position,
         FRAGMENTS.ZIndex,
         FRAGMENTS.Animation,
         FRAGMENTS.Sprite
      )

      for i = 1, entityCount do
         local position = positions[i]
         if position then
            renderList[#renderList + 1] = {
               zindex = zindices[i],
               position = position,
               animation = animations and animations[i],
               sprite = sprites and sprites[i]
            }
         end
      end
   end):build()

-- Render system - sorts collected entities and draws them in order
local Sprite = require("src.evolved.fragments.sprite")

builder()
   :name("SYSTEMS.RenderSortedEntities")
   :group(STAGES.OnRenderEntities)
   :execute(function()
      -- Sort by ZIndex (lower Y = further back = render first)
      table.sort(renderList, function(a, b) return a.zindex < b.zindex end)

      -- Draw in sorted order
      for i = 1, #renderList do
         local item = renderList[i]
         local x, y = math.ceil(item.position.x), math.ceil(item.position.y)
         if item.animation and item.animation.spritesheets then
            Animation.draw(item.animation, x, y)
         elseif item.sprite then
            Sprite.draw(item.sprite, x, y)
         end
      end

      -- Clear for next frame
      for i = #renderList, 1, -1 do renderList[i] = nil end
   end):build()
