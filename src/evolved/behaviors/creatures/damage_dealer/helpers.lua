-- ============================================================================
-- DamageDealer Helper Functions
-- ============================================================================
-- Utility functions for DamageDealer creature AI
-- Handles player detection, distance calculation, and movement direction

local EntityHelper = require("src.helpers.entity_helper")
local execute = Evolved.execute
local get = Evolved.get

local helpers = {}

-- ============================================================================
-- Configuration
-- ============================================================================

-- AI behavior thresholds
helpers.ALERT_RANGE = 150     -- Distance at which skeleton notices player
helpers.ATTACK_RANGE = 20     -- Distance at which skeleton can attack
helpers.CHASE_SPEED = 160     -- Speed at which skeleton chases player (> 150 for Run anim)
helpers.ATTACK_COOLDOWN = 1.0 -- Time between attacks
helpers.ALERT_DURATION = 0.5  -- Time spent in alert state before chasing
helpers.ATTACK_DURATION = 0.6 -- Time spent in attacking state (for animation)

-- ============================================================================
-- Player Detection
-- ============================================================================

--- Get the player entity ID
--- @return number|nil The player entity ID or nil
function helpers.getPlayerId()
   return ENTITIES.Player
end

--- Get the player's position
--- @return table|nil The player position vector or nil
function helpers.getPlayerPosition()
   local playerId = helpers.getPlayerId()
   if not playerId then return nil end

   return get(playerId, FRAGMENTS.Position)
end

--- Calculate distance to the player
--- @param position table The creature's position
--- @return number|nil Distance to player, or nil if no player
function helpers.getDistanceToPlayer(position)
   local playerPos = helpers.getPlayerPosition()
   if not playerPos then return nil end

   local dx = playerPos.x - position.x
   local dy = playerPos.y - position.y
   return math.sqrt(dx * dx + dy * dy)
end

--- Check if player is within a given range
--- @param position table The creature's position
--- @param range number The detection range
--- @return boolean True if player is within range
function helpers.isPlayerInRange(position, range)
   local distance = helpers.getDistanceToPlayer(position)
   return distance ~= nil and distance <= range
end

--- Get direction vector towards the player
--- @param position table The creature's position
--- @return table|nil Normalized direction vector {x, y} or nil
function helpers.getDirectionToPlayer(position)
   local playerPos = helpers.getPlayerPosition()
   if not playerPos then return nil end

   local dx = playerPos.x - position.x
   local dy = playerPos.y - position.y
   local distance = math.sqrt(dx * dx + dy * dy)

   if distance == 0 then
      return {x = 0, y = 0}
   end

   return {
      x = dx / distance,
      y = dy / distance,
   }
end

-- ============================================================================
-- Movement & Animation Helpers
-- ============================================================================

--- Set creature velocity towards player
--- @param creatureId number The creature entity ID
--- @param speed number Movement speed
function helpers.moveTowardsPlayer(creatureId, speed)
   local position = get(creatureId, FRAGMENTS.Position)
   local velocity = get(creatureId, FRAGMENTS.Velocity)

   if not position or not velocity then return end

   local direction = helpers.getDirectionToPlayer(position)
   if direction then
      velocity.x = direction.x * speed
      velocity.y = direction.y * speed
   end
end

--- Stop creature movement
--- @param creatureId number The creature entity ID
function helpers.stopMovement(creatureId)
   local velocity = get(creatureId, FRAGMENTS.Velocity)
   if velocity then
      velocity.x = 0
      velocity.y = 0
   end
end

--- Get the cardinal direction name towards player for animation
--- @param position table The creature's position
--- @return string Direction name ("Front", "Back", "Left", "Right")
function helpers.getDirectionNameToPlayer(position)
   local direction = helpers.getDirectionToPlayer(position)
   if not direction then
      return "Front" -- Default
   end

   -- Determine primary direction based on larger component
   if math.abs(direction.x) > math.abs(direction.y) then
      return direction.x > 0 and "Right" or "Left"
   else
      return direction.y > 0 and "Front" or "Back"
   end
end

return helpers
