--- Processing System
--- Generic system for managing machine automation
--- Handles state transitions, processing timers, and cycling for any machine type
---
--- Resource consumption model:
--- - Ingredients: Consumed on COMPLETE (not on start)
--- - Mana: Consumed per tick during WORKING state
---
--- Machines can have different FSMs (Assembler, Generator, etc.)

local ItemRegistry = require("src.registries.item_registry")

local ProcessingSystem = {}

ProcessingSystem.DEBUG = true -- Set to false to disable debug logging
ProcessingSystem.MANA_RESUME_THRESHOLD_SECONDS = 1.0

--- Initialize the system
function ProcessingSystem:init()
   -- Nothing to initialize
end

--- Update all processing machines
--- @param dt number Delta time
function ProcessingSystem:update(dt)
   for _, entity in ipairs(self.pool.groups.processing.entities) do
      ProcessingSystem.updateMachine(entity, dt)
   end
end

--------------------------------------------------------------------------------
-- Ingredient Helpers
--------------------------------------------------------------------------------

--- Count available ingredients in machine's input slots
--- @param machine table The machine entity
--- @return table ingredientCounts Map of item_id to quantity
local function countIngredients(machine)
   local counts = {}
   for _, slot in ipairs(machine.inventory.input_slots) do
      if slot.item_id then
         counts[slot.item_id] = (counts[slot.item_id] or 0) + (slot.quantity or 1)
      end
   end
   return counts
end

--- Check if machine has required ingredients for its current recipe
--- @param machine table The machine entity
--- @return boolean hasIngredients
local function hasRequiredIngredients(machine)
   if not machine.currentRecipe then return false end

   local recipe = machine.currentRecipe
   if not recipe.inputs then return true end -- Recipe has no ingredient requirements

   local available = countIngredients(machine)

   for ingredient, requiredAmount in pairs(recipe.inputs) do
      if (available[ingredient] or 0) < requiredAmount then
         return false
      end
   end

   return true
end

--- Consume ingredients from machine's input slots
--- @param machine table The machine entity
--- @return boolean success
local function consumeIngredients(machine)
   if not machine.currentRecipe then return false end

   local recipe = machine.currentRecipe
   if not recipe.inputs then return true end

   for ingredient, amount in pairs(recipe.inputs) do
      local remaining = amount
      for _, slot in ipairs(machine.inventory.input_slots) do
         if slot.item_id == ingredient and remaining > 0 then
            local toRemove = math.min(remaining, slot.quantity or 0)
            slot.quantity = slot.quantity - toRemove
            remaining = remaining - toRemove

            if slot.quantity <= 0 then
               slot.item_id = nil
               slot.quantity = nil
            end
         end
      end

      if remaining > 0 then
         Log.error("ProcessingSystem: Failed to consume all of ingredient: "..ingredient)
         return false
      end
   end

   return true
end

--------------------------------------------------------------------------------
-- Mana Helpers
--------------------------------------------------------------------------------

--- Consume mana per tick from machine
--- @param machine table The machine entity
--- @param dt number Delta time
--- @return boolean success True if mana was consumed, false if insufficient
local function consumeManaTick(machine, dt)
   if not machine.currentRecipe then return true end

   local manaPerTick = machine.currentRecipe.mana_per_tick or 0
   if manaPerTick == 0 then return true end

   local manaCost = manaPerTick * dt
   local manaEpsilon = 0.01
   if (machine.mana or 0) >= -manaEpsilon and (machine.mana or 0) >= manaCost - manaEpsilon then
      machine.mana = machine.mana - manaCost
      return true
   end

   return false
end

--- Check if machine has enough mana for at least one tick
--- @param machine table The machine entity
--- @return boolean hasEnoughMana
local function hasEnoughManaForTick(machine)
   if not machine.currentRecipe then return true end

   local manaPerTick = machine.currentRecipe.mana_per_tick or 0
   if manaPerTick == 0 then return true end

   local requiredMana = manaPerTick * ProcessingSystem.MANA_RESUME_THRESHOLD_SECONDS

   return (machine.mana or 0) >= requiredMana
end

--------------------------------------------------------------------------------
-- Output Helpers
--------------------------------------------------------------------------------

--- Check if output slots have space for at least one item
--- @param machine table The machine entity
--- @return boolean hasSpace
local function hasOutputSpace(machine)
   if not machine.inventory.output_slots then return true end
   if #machine.inventory.output_slots == 0 then return true end -- No output slots = sink machine

   for _, slot in ipairs(machine.inventory.output_slots) do
      if not slot.item_id then
         return true
      end
   end

   -- Check if any existing slot can stack more
   if machine.currentRecipe and machine.currentRecipe.outputs then
      for output_id, _ in pairs(machine.currentRecipe.outputs) do
         local maxStack = ItemRegistry.getMaxStackSize(output_id)
         for _, slot in ipairs(machine.inventory.output_slots) do
            if slot.item_id == output_id and (slot.quantity or 0) < maxStack then
               return true
            end
         end
      end
   end

   return false
end

--- Produce output items in the output slots with stacking support
--- @param machine table The machine entity
--- @return boolean success
local function produceOutputs(machine)
   if not machine.currentRecipe then return false end

   local recipe = machine.currentRecipe
   if not recipe.outputs then return true end -- No outputs = sink machine

   -- No output slots configured = sink machine (valid)
   if not machine.inventory.output_slots or #machine.inventory.output_slots == 0 then
      return true
   end

   for output_id, amount in pairs(recipe.outputs) do
      local remaining = amount
      local maxStack = ItemRegistry.getMaxStackSize(output_id)

      -- First, try to stack with existing slots
      for _, slot in ipairs(machine.inventory.output_slots) do
         if remaining <= 0 then break end

         if slot.item_id == output_id and (slot.quantity or 0) < maxStack then
            local canAdd = math.min(remaining, maxStack - (slot.quantity or 0))
            slot.quantity = (slot.quantity or 0) + canAdd
            remaining = remaining - canAdd
         end
      end

      -- Then, fill empty slots
      for _, slot in ipairs(machine.inventory.output_slots) do
         if remaining <= 0 then break end

         if not slot.item_id then
            local toAdd = math.min(remaining, maxStack)
            slot.item_id = output_id
            slot.quantity = toAdd
            remaining = remaining - toAdd
         end
      end

      -- If we couldn't place all outputs, fail
      if remaining > 0 then
         return false
      end
   end

   -- Handle chance-based outputs
   if recipe.output_chances then
      for output_id, chance in pairs(recipe.output_chances) do
         if math.random() < chance then
            local maxStack = ItemRegistry.getMaxStackSize(output_id)

            -- Try to add bonus output
            for _, slot in ipairs(machine.inventory.output_slots) do
               if slot.item_id == output_id and (slot.quantity or 0) < maxStack then
                  slot.quantity = (slot.quantity or 0) + 1
                  break
               elseif not slot.item_id then
                  slot.item_id = output_id
                  slot.quantity = 1
                  break
               end
            end
            -- If no space for bonus, silently skip (don't fail the main output)
         end
      end
   end

   return true
end

--------------------------------------------------------------------------------
-- State Handlers
--------------------------------------------------------------------------------

--- Handle BLANK state (no recipe set)
--- @param machine table The machine entity
local function handleBlankState(machine)
   -- Nothing to do - waiting for recipe to be set externally
end

--- Handle IDLE state (recipe set, waiting for ingredients or auto-restart)
--- @param machine table The machine entity
local function handleIdleState(machine)
   -- Check if we have ingredients (or recipe has no ingredients)
   if hasRequiredIngredients(machine) then
      if machine.fsm:can("prepare") then
         machine.fsm:prepare()
         if ProcessingSystem.DEBUG then
            Log.info("ProcessingSystem: "..machine.name.." - Prepared, transitioning to READY")
         end
      elseif machine.fsm:can("restart") then
         -- Generator-style: restart directly to working
         machine.processingTimer = machine.currentRecipe.processing_time or 1
         machine.fsm:restart()
         if ProcessingSystem.DEBUG then
            Log.info("ProcessingSystem: "..machine.name.." - Restarting, transitioning to WORKING")
         end
      end
   end
end

--- Handle READY state (has ingredients, ready to start)
--- @param machine table The machine entity
local function handleReadyState(machine)
   if not machine.currentRecipe then return end

   -- Set processing timer
   machine.processingTimer = machine.currentRecipe.processing_time or 1

   -- Transition to working
   if machine.fsm:can("start_ritual") then
      machine.fsm:start_ritual()
      if ProcessingSystem.DEBUG then
         Log.info("ProcessingSystem: "..machine.name.." - Starting ritual")
         Log.info("  Processing time: "..machine.processingTimer.."s")
      end
   elseif machine.fsm:can("start") then
      machine.fsm:start()
      if ProcessingSystem.DEBUG then
         Log.info("ProcessingSystem: "..machine.name.." - Starting processing")
         Log.info("  Processing time: "..machine.processingTimer.."s")
      end
   end
end

--- Handle WORKING state (processing in progress)
--- @param machine table The machine entity
--- @param dt number Delta time
local function handleWorkingState(machine, dt)
   if not machine.currentRecipe then return end

   -- 0. Initialize timer if not set (e.g., generator's set_recipe goes directly to working)
   if machine.processingTimer <= 0 then
      machine.processingTimer = machine.currentRecipe.processing_time or 1
      if ProcessingSystem.DEBUG then
         Log.info("ProcessingSystem: "..machine.name.." - Initialized timer: "..machine.processingTimer.."s")
      end
   end

   -- 1. Check ingredients still present (consumed on complete, so must still be there)
   if machine.currentRecipe.inputs and not hasRequiredIngredients(machine) then
      machine.processingTimer = 0
      machine.fsm:stop()
      if ProcessingSystem.DEBUG then
         Log.warn("ProcessingSystem: "..machine.name.." - Ingredients missing, transitioning to IDLE")
      end
      return
   end

   -- 2. Consume mana per tick
   if not consumeManaTick(machine, dt) then
      -- Save timer for resume
      machine.savedTimer = machine.processingTimer
      machine.fsm:starve()
      if ProcessingSystem.DEBUG then
         Log.warn("ProcessingSystem: "..machine.name.." - Mana depleted, transitioning to NO_MANA")
      end
      return
   end

   -- 3. Update processing timer
   machine.processingTimer = machine.processingTimer - dt

   -- 4. Check completion
   if machine.processingTimer <= 0 then
      -- Consume ingredients on complete
      if not consumeIngredients(machine) then
         -- Shouldn't happen if we checked above, but safety check
         machine.fsm:stop()
         return
      end

      -- Check output space and produce
      if hasOutputSpace(machine) then
         local success = produceOutputs(machine)

         if success then
            if ProcessingSystem.DEBUG then
               Log.info("ProcessingSystem: "..machine.name.." - Processing complete, produced outputs")
            end

            machine.fsm:complete()

            machine.processingTimer = 0
            -- Will check for restart on next update in IDLE state
         else
            -- Partial output space but couldn't fit everything
            machine.fsm:block()
            if ProcessingSystem.DEBUG then
               Log.warn("ProcessingSystem: "..machine.name.." - Output full, transitioning to BLOCKED")
            end
         end
      else
         -- No output space at all
         machine.fsm:block()
         if ProcessingSystem.DEBUG then
            Log.warn("ProcessingSystem: "..machine.name.." - Output full, transitioning to BLOCKED")
         end
      end
   end
end

--- Handle BLOCKED state (output slots full)
--- @param machine table The machine entity
local function handleBlockedState(machine)
   if hasOutputSpace(machine) then
      machine.fsm:unblock()
      if ProcessingSystem.DEBUG then
         Log.info("ProcessingSystem: "..machine.name.." - Output space available, transitioning to IDLE")
      end
   end
end

--- Handle NO_MANA state (mana depleted during processing)
--- @param machine Machine The machine entity
local function handleNoManaState(machine)
   -- Require meaningful amount of mana before resuming (prevents oscillation)
   if not hasEnoughManaForTick(machine) then return end
   -- Restore saved timer and resume
   machine.processingTimer = machine.savedTimer or 0
   machine.savedTimer = 0

   machine.fsm:refuel()
   if ProcessingSystem.DEBUG then
      Log.info("ProcessingSystem: "..machine.name.." - Mana restored, resuming WORKING")
      Log.info("  Remaining time: "..machine.processingTimer.."s")
   end
end

--------------------------------------------------------------------------------
-- Main Update
--------------------------------------------------------------------------------

--- Update a single machine
--- @param machine table The machine entity
--- @param dt number Delta time
function ProcessingSystem.updateMachine(machine, dt)
   local state = machine.fsm.current

   if state == "blank" then
      handleBlankState(machine)
   elseif state == "idle" then
      handleIdleState(machine)
   elseif state == "ready" then
      handleReadyState(machine)
   elseif state == "working" then
      handleWorkingState(machine, dt)
   elseif state == "blocked" then
      handleBlockedState(machine)
   elseif state == "no_mana" then
      handleNoManaState(machine, dt)
   end
end

return ProcessingSystem
