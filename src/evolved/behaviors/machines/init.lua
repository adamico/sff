-- ============================================================================
-- Machine Behavior Registry
-- ============================================================================
-- Maps machine class names to their behavior modules
-- The processing system uses this to look up the correct behavior for each
-- entity based on its MachineClass fragment
--
-- Usage:
--    local Machines = require("src.evolved.behaviors.machines")
--    local behavior = Machines.get("Assembler")
--    behavior.update(context)
--
-- Adding a new machine type:
--    1. Create a new behavior module in machines/ (e.g., machines/furnace/)
--    2. Register it here with Machines.register("Furnace", require(...))

local Machines = {}

-- ============================================================================
-- Registry
-- ============================================================================

-- Registry table: class name -> behavior module
local registry = {}

--- Register a behavior module for a machine class
--- @param className string The machine class name (e.g., "Assembler")
--- @param behaviorModule table The behavior module with update(context) function
function Machines.register(className, behaviorModule)
   if registry[className] then
      Log.warn("Machines: Overwriting existing behavior for class: "..className)
   end
   registry[className] = behaviorModule
   Log.info("Machines: Registered behavior for class: "..className)
end

--- Get the behavior module for a machine class
--- @param className string The machine class name
--- @return table|nil The behavior module, or nil if not found
function Machines.get(className)
   return registry[className]
end

--- Check if a behavior is registered for a class
--- @param className string The machine class name
--- @return boolean
function Machines.has(className)
   return registry[className] ~= nil
end

--- Get all registered class names
--- @return table Array of registered class names
function Machines.getRegisteredClasses()
   local classes = {}
   for className, _ in pairs(registry) do
      table.insert(classes, className)
   end
   table.sort(classes) -- Sort alphabetically for consistency
   return classes
end

-- ============================================================================
-- Built-in Machine Behaviors
-- ============================================================================

Machines.register("Assembler", require("src.evolved.behaviors.machines.assembler"))

-- Future machine types can be registered here:
-- Machines.register("Furnace", require("src.evolved.behaviors.machines.furnace"))
-- Machines.register("Crusher", require("src.evolved.behaviors.machines.crusher"))
-- Machines.register("Centrifuge", require("src.evolved.behaviors.machines.centrifuge"))

return Machines
