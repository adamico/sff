-- ============================================================================
-- Creature Behavior Registry
-- ============================================================================
-- Maps creature class names to their behavior modules
-- The processing system uses this to look up the correct behavior for each
-- entity based on its CreatureClass fragment
--
-- Usage:
--    local Creatures = require("src.evolved.behaviors.creatures")
--    local behavior = Creatures.get("Tank")
--    behavior.update(context)
--
-- Adding a new creature type:
--    1. Create a new behavior module in creatures/ (e.g., creatures/damage_dealer/)
--    2. Register it here with Creatures.register("DamageDealer", require(...))

local Creatures = {}

-- ============================================================================
-- Registry
-- ============================================================================

-- Registry table: class name -> behavior module
local registry = {}

--- Register a behavior module for a creature class
--- @param className string The creature class name (e.g., "Tank")
--- @param behaviorModule table The behavior module with update(context) function
function Creatures.register(className, behaviorModule)
   if registry[className] then
      Log.warn("Creatures: Overwriting existing behavior for class: "..className)
   end
   registry[className] = behaviorModule
   Log.info("Creatures: Registered behavior for class: "..className)
end

--- Get the behavior module for a creature class
--- @param className string The creature class name
--- @return table|nil The behavior module, or nil if not found
function Creatures.get(className)
   return registry[className]
end

--- Check if a behavior is registered for a class
--- @param className string The creature class name
--- @return boolean
function Creatures.has(className)
   return registry[className] ~= nil
end

--- Get all registered class names
--- @return table Array of registered class names
function Creatures.getRegisteredClasses()
   local classes = {}
   for className, _ in pairs(registry) do
      table.insert(classes, className)
   end
   table.sort(classes) -- Sort alphabetically for consistency
   return classes
end

-- ============================================================================
-- Built-in Creature Behaviors
-- ============================================================================

Creatures.register("DamageDealer", require("src.evolved.behaviors.creatures.damage_dealer"))

-- Future creature types can be registered here:
-- Creatures.register("Tank", require("src.evolved.behaviors.creatures.tank"))
-- Creatures.register("Healer", require("src.evolved.behaviors.creatures.healer"))

return Creatures
