local builder = Evolved.builder
local Behaviors = require("src.evolved.behaviors")

builder()
   :name("SYSTEMS.Processing")
   :group(STAGES.OnUpdate)
   :include(TAGS.Processing)
   :execute(function(chunk, entityIds, entityCount)
      local stateMachines = chunk:components(FRAGMENTS.StateMachine)
      local recipes = chunk:components(FRAGMENTS.CurrentRecipe)
      local inventories = chunk:components(FRAGMENTS.Inventory)
      local machineClasses = chunk:components(FRAGMENTS.MachineClass)
      local manas = chunk:components(FRAGMENTS.Mana)
      local processingTimers = chunk:components(FRAGMENTS.ProcessingTimer)
      local names = chunk:components(Evolved.NAME)

      local dt = UNIFORMS.getDeltaTime()

      for i = 1, entityCount do
         local machineClass = machineClasses[i]
         local behavior = Behaviors.get(machineClass)

         if behavior then
            local context = {
               machineId = entityIds[i],
               machineName = (names[i] or "Machine")..entityIds[i],
               fsm = stateMachines[i],
               recipe = recipes[i],
               inventory = inventories[i],
               mana = manas[i],
               processingTimer = processingTimers[i],
               dt = dt,
            }

            behavior.update(context)
         else
            Log.warn("ProcessingSystem: No behavior registered for class: "..tostring(machineClass))
         end
      end
   end):build()
