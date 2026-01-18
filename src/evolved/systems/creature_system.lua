--[[
   Creature Processing System

   Handles AI behavior updates for creatures with the Creature tag.
   Each creature has a CreatureClass that determines its behavior module.

   Similar to the processing_system for machines, this system:
   - Queries all creatures with the Creature tag
   - Looks up the appropriate behavior module based on CreatureClass
   - Calls the behavior's update function with a context containing entity data

   Context structure passed to behavior.update():
   {
      creatureId = number,     -- Entity ID
      creatureName = string,   -- Display name for logging
      fsm = table,             -- State machine instance
      position = table,        -- Current position vector
      velocity = table,        -- Current velocity vector (if exists)
      visual = table,          -- Visual component (if exists)
      health = table,          -- Health component (if exists)
      dt = number,             -- Delta time
   }
]]

local builder = Evolved.builder
local Creatures = require("src.evolved.behaviors.creatures")

builder()
   :name("SYSTEMS.CreatureProcessing")
   :group(STAGES.OnUpdate)
   :include(TAGS.Creature)
   :execute(function(chunk, entityIds, entityCount)
      local stateMachines = chunk:components(FRAGMENTS.StateMachine)
      local creatureClasses = chunk:components(FRAGMENTS.CreatureClass)
      local positions = chunk:components(FRAGMENTS.Position)
      local velocities = chunk:components(FRAGMENTS.Velocity)
      local visuals = chunk:components(FRAGMENTS.Visual)
      local healths = chunk:components(FRAGMENTS.Health)
      local names = chunk:components(Evolved.NAME)

      local dt = UNIFORMS.getDeltaTime()

      for i = 1, entityCount do
         local creatureClass = creatureClasses[i]
         local behavior = Creatures.get(creatureClass)

         if behavior then
            local context = {
               creatureId = entityIds[i],
               creatureName = (names[i] or "Creature")..entityIds[i],
               fsm = stateMachines[i],
               position = positions[i],
               velocity = velocities[i],
               visual = visuals[i],
               health = healths[i],
               dt = dt,
            }

            behavior.update(context)
         else
            Log.warn("CreatureSystem: No behavior registered for class: "..tostring(creatureClass))
         end
      end
   end):build()
