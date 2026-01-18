-- ============================================================================
-- DamageDealer State Behaviors
-- ============================================================================
-- State-specific behavior functions for DamageDealer creatures (e.g., Skeleton)
-- Each function receives a context table and can trigger FSM transitions
--
-- State flow:
--   blank → (spawn) → idle → (alert) → alert → (chase) → chasing → (attack) → attacking
--   Any state → (reset) → idle

local helpers = require("src.evolved.behaviors.creatures.damage_dealer.helpers")

local get = Evolved.get
local set = Evolved.set

local states = {}
local DEBUG = false

-- Per-creature timers (keyed by entity ID)
local alertTimers = {}
local attackCooldowns = {}
local attackTimers = {}

-- ============================================================================
-- BLANK State - Initial state before spawn
-- ============================================================================

--- Handle BLANK state - trigger spawn transition immediately
--- @param context table The update context
function states.blank(context)
   -- Clear any stale cooldowns to ensure first attack is immediate
   attackCooldowns[context.creatureId] = nil
   attackTimers[context.creatureId] = nil
   alertTimers[context.creatureId] = nil

   -- Transition to idle on first update
   context.fsm:spawn()

   if DEBUG then
      Log.info("DamageDealer: "..context.creatureName.." spawned")
   end
end

-- ============================================================================
-- IDLE State - Waiting, checking for player
-- ============================================================================

--- Handle IDLE state - patrol or wait, detect player in range
--- @param context table The update context
function states.idle(context)
   -- Clear attacking flag
   if context.visual then
      context.visual.isAttacking = false
   end

   -- Stop movement while idle
   helpers.stopMovement(context.creatureId)

   -- Get distance to player once
   local distance = helpers.getDistanceToPlayer(context.position)
   if not distance then return end

   -- Check if player is within attack range (skip alert, go straight to chase)
   if distance <= helpers.ATTACK_RANGE then
      context.fsm:alert()
      context.fsm:chase() -- Immediately chain to chase

      if DEBUG then
         Log.info("DamageDealer: "..context.creatureName.." player in attack range, chasing!")
      end
      -- Check if player is within alert range
   elseif distance <= helpers.ALERT_RANGE then
      -- Initialize alert timer
      alertTimers[context.creatureId] = helpers.ALERT_DURATION
      context.fsm:alert()

      if DEBUG then
         Log.info("DamageDealer: "..context.creatureName.." detected player!")
      end
   end
end

-- ============================================================================
-- ALERT State - Player detected, brief pause before chasing
-- ============================================================================

--- Handle ALERT state - face player, brief pause, then chase
--- @param context table The update context
function states.alert(context)
   -- Clear attacking flag
   if context.visual then
      context.visual.isAttacking = false
   end

   -- Stop movement during alert
   helpers.stopMovement(context.creatureId)

   -- Countdown alert timer
   local timer = alertTimers[context.creatureId] or 0
   timer = timer - context.dt

   if timer <= 0 then
      -- Alert period over, start chasing
      alertTimers[context.creatureId] = nil
      context.fsm:chase()

      if DEBUG then
         Log.info("DamageDealer: "..context.creatureName.." starting chase!")
      end
   else
      alertTimers[context.creatureId] = timer
   end
end

-- ============================================================================
-- CHASING State - Actively pursuing the player
-- ============================================================================

--- Handle CHASING state - move towards player, attack when in range
--- @param context table The update context
function states.chasing(context)
   -- Clear attacking flag (we're running now)
   if context.visual then
      context.visual.isAttacking = false
   end

   local distance = helpers.getDistanceToPlayer(context.position)

   -- If player is gone or too far, reset to idle
   if not distance or distance > helpers.ALERT_RANGE * 1.5 then
      helpers.stopMovement(context.creatureId)
      context.fsm:reset()

      if DEBUG then
         Log.info("DamageDealer: "..context.creatureName.." lost player, returning to idle")
      end
      return
   end

   -- Check cooldown
   local cooldown = attackCooldowns[context.creatureId] or 0
   if cooldown > 0 then
      attackCooldowns[context.creatureId] = cooldown - context.dt
   end

   -- Check if in attack range
   if distance <= helpers.ATTACK_RANGE then
      -- Stop movement when in attack range (whether attacking or waiting for cooldown)
      helpers.stopMovement(context.creatureId)

      -- Attack if cooldown is ready
      if cooldown <= 0 then
         context.fsm:attack()

         if DEBUG then
            Log.info("DamageDealer: "..context.creatureName.." attacking!")
         end
      end
      -- Otherwise just wait for cooldown (idle animation will play due to velocity=0)
   else
      helpers.moveTowardsPlayer(context.creatureId, helpers.CHASE_SPEED)
   end
end

-- ============================================================================
-- ATTACKING State - Executing attack animation/action
-- ============================================================================

--- Handle ATTACKING state - perform attack, return to chasing
--- @param context table The update context
function states.attacking(context)
   -- Set attacking flag for animation
   if context.visual then
      context.visual.isAttacking = true
   end

   -- Stop movement during attack
   helpers.stopMovement(context.creatureId)

   -- Initialize attack timer if not set
   if not attackTimers[context.creatureId] then
      attackTimers[context.creatureId] = helpers.ATTACK_DURATION

      -- TODO: Apply damage to player here (at start of attack)
      if DEBUG then
         Log.info("DamageDealer: "..context.creatureName.." started attack!")
      end
   end

   -- Countdown attack timer
   local timer = attackTimers[context.creatureId]
   timer = timer - context.dt

   if timer <= 0 then
      -- Attack animation complete
      attackTimers[context.creatureId] = nil

      -- Check if player is still in attack range
      local distance = helpers.getDistanceToPlayer(context.position)
      if distance and distance <= helpers.ATTACK_RANGE then
         -- Player still in range, start cooldown then attack again
         attackCooldowns[context.creatureId] = helpers.ATTACK_COOLDOWN

         if DEBUG then
            Log.info("DamageDealer: "..context.creatureName.." attack complete, player still in range")
         end
         -- Stay in attacking state, will wait for cooldown in chasing transition check
         -- Actually, let's just restart the attack timer after cooldown
         -- For now, transition to a brief "waiting" by going to chasing which will re-attack
         context.fsm:reset()
      else
         -- Player out of range, return to idle
         attackCooldowns[context.creatureId] = helpers.ATTACK_COOLDOWN
         context.fsm:reset()

         if DEBUG then
            Log.info("DamageDealer: "..context.creatureName.." attack complete, player left range")
         end
      end
   else
      attackTimers[context.creatureId] = timer
   end
end

-- ============================================================================
-- DEAD State - Creature has died
-- ============================================================================

--- Handle DEAD state - play death animation, await cleanup
--- @param context table The update context
function states.dead(context)
   -- Stop all movement
   helpers.stopMovement(context.creatureId)

   -- Clean up timers
   alertTimers[context.creatureId] = nil
   attackCooldowns[context.creatureId] = nil

   -- Death animation is handled by visual system
end

-- ============================================================================
-- LOOTED State - Creature has been looted
-- ============================================================================

--- Handle LOOTED state - waiting to be destroyed
--- @param context table The update context
function states.looted(context)
   -- When the creature has been looted for a certain amount of time,
   -- the loot system will destroy it
end

return states
