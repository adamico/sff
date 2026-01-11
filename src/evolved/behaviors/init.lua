--[[
   Behavior Registry

   Maps machine class names to their behavior modules.
   The processing system uses this to look up the correct
   behavior for each entity based on its class.

   Usage:
      local Behaviors = require("src.evolved.behaviors")
      local behavior = Behaviors.get("Assembler")
      behavior.update(context)

   Adding a new machine type:
      1. Create a new behavior module (e.g., behaviors/furnace.lua)
      2. Register it here with Behaviors.register("Furnace", require(...))
]]

local Behaviors = {}

-- Registry table: class name -> behavior module
local registry = {}

--- Register a behavior module for a machine class
--- @param className string The machine class name (e.g., "Assembler")
--- @param behaviorModule table The behavior module with update(context) function
function Behaviors.register(className, behaviorModule)
   if registry[className] then
      Log.warn("Behaviors: Overwriting existing behavior for class: "..className)
   end
   registry[className] = behaviorModule
end

--- Get the behavior module for a machine class
--- @param className string The machine class name
--- @return table|nil The behavior module, or nil if not found
function Behaviors.get(className)
   return registry[className]
end

--- Check if a behavior is registered for a class
--- @param className string The machine class name
--- @return boolean
function Behaviors.has(className)
   return registry[className] ~= nil
end

--- Get all registered class names
--- @return table Array of registered class names
function Behaviors.getRegisteredClasses()
   local classes = {}
   for className, _ in pairs(registry) do
      table.insert(classes, className)
   end
   return classes
end

-- =============================================================================
-- Register built-in behaviors
-- =============================================================================

Behaviors.register("Assembler", require("src.evolved.behaviors.assembler_behavior"))

return Behaviors
