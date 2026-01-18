--[[
   Render Entities System

   Handles animation updates and rendering for entities with the Visual tag.
   Uses peachy library for Aseprite spritesheet animation support.

   Responsibilities:
   - Update animation state based on entity velocity
   - Advance animation frames each tick
   - Draw sprites at entity positions
]]

local Visual = require("src.evolved.fragments.visual")
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
local visualQuery = builder()
   :name("QUERIES.Visual")
   :include(TAGS.Visual)
   :build()

-- Update system - handles animation state updates
builder()
   :name("SYSTEMS.UpdateEntityAnimations")
   :group(STAGES.OnUpdate)
   :include(TAGS.Visual)
   :execute(function(chunk, entityIds, entityCount)
      local visuals, velocities, positions = chunk:components(
         FRAGMENTS.Visual,
         FRAGMENTS.Velocity,
         FRAGMENTS.Position
      )

      local dt = love.timer.getDelta()

      for i = 1, entityCount do
         local visual = visuals[i]
         local velocity = velocities[i]

         if visual and visual.spritesheets then
            if velocity then
               Visual.setDirectionFromVelocity(visual, velocity.x, velocity.y)

               local moving = isMoving(velocity)
               local running = isRunning(velocity)

               local attacking = visual.isAttacking or false
               Visual.setStateFromMovement(visual, moving, running, attacking)
            end

            Visual.update(visual, dt)
         end
      end
   end):build()

-- Render system - draws sprites
builder()
   :name("SYSTEMS.RenderEntities")
   :group(STAGES.OnRender)
   :include(TAGS.Visual)
   :execute(function(chunk, entityIds, entityCount)
      local visuals, positions = chunk:components(
         FRAGMENTS.Visual,
         FRAGMENTS.Position
      )

      for i = 1, entityCount do
         local visual = visuals[i]
         local position = positions[i]
         if visual and position and visual.spritesheets then
            Visual.draw(visual, math.ceil(position.x), math.ceil(position.y))
         end
      end
   end):build()
