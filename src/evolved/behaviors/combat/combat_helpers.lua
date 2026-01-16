-- ============================================================================
-- Combat Helpers
-- ============================================================================
-- Shared validation and utility functions for combat behaviors
-- Reduces code duplication across different combat behavior modules

local EntityHelper = require("src.helpers.entity_helper")

local get = Evolved.get

local CombatHelpers = {}

--- Validate that the attacker can attack the target
--- @param attackerId number The attacker's entity ID
--- @param targetId number The target's entity ID
--- @param damagedStat string The type of damage being dealt (e.g., "Health", "Mana")
--- @return boolean success True if attack is valid
--- @return string|nil error Error message if validation failed
function CombatHelpers.validateAttack(attackerId, targetId, damagedStat)
   -- Check attacker exists
   if not attackerId then
      return false, "No attacker specified"
   end

   -- Check target exists
   if not targetId then
      return false, "No target specified"
   end

   -- Prevent self-attack
   if attackerId == targetId then
      return false, string.format("Entity %d cannot attack itself", attackerId)
   end

   -- Check target has the damaged stat component
   local damagedStatComponent = get(targetId, FRAGMENTS[damagedStat])
   if not damagedStatComponent then
      return false, string.format("Target %d has no %s component", targetId, damagedStat)
   end

   -- Check target has remaining stat to damage
   if damagedStatComponent.current <= 0 then
      return false, string.format("Target %d has no %s remaining", targetId, damagedStat)
   end

   return true, nil
end

--- Validate that the attacker has the required equipment category
--- @param attackerId number The attacker's entity ID
--- @param requiredCategory string The required equipment category (e.g., "harvester", "weapon")
--- @return boolean success True if equipment is valid
--- @return string|nil error Error message if validation failed
function CombatHelpers.validateEquipment(attackerId, requiredCategory)
   local equipment = get(attackerId, FRAGMENTS.Equipment)
   if not equipment then
      return false, string.format("Entity %d has no equipment component", attackerId)
   end

   if not EntityHelper.isEquippedWith(attackerId, requiredCategory) then
      return false, string.format("Entity %d is not equipped with a %s", attackerId, requiredCategory)
   end

   return true, nil
end

--- Calculate damage based on equipped weapon damage
--- @param attackerId number The attacker's entity ID
--- @return number damage The calculated damage amount (0 if no damage component)
function CombatHelpers.calculateDamage(attackerId)
   local weapon = EntityHelper.getEquippedWeapon(attackerId)
   if not weapon then
      Log.warn(string.format("No damage component found for attacker: %d", attackerId))
      return 0
   end

   local min = weapon.damageMin or 0
   local max = weapon.damageMax or min

   if min >= max then
      return min
   end

   return math.random(min, max)
end

--- Full validation for a combat action
--- @param attackerId number The attacker's entity ID
--- @param targetId number The target's entity ID
--- @param damagedStat string The type of damage being dealt
--- @param requiredCategory string|nil Optional required equipment category
--- @return boolean success True if all validations pass
--- @return string|nil error Error message if any validation failed
function CombatHelpers.validateCombatAction(attackerId, targetId, damagedStat, requiredCategory)
   -- Validate basic attack requirements
   local attackValid, attackError = CombatHelpers.validateAttack(attackerId, targetId, damagedStat)
   if not attackValid then
      return false, attackError
   end

   -- Validate equipment if required
   if requiredCategory then
      local equipmentValid, equipmentError = CombatHelpers.validateEquipment(attackerId, requiredCategory)
      if not equipmentValid then
         return false, equipmentError
      end
   end

   return true, nil
end

return CombatHelpers
