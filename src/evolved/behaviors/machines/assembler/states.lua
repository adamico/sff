-- ============================================================================
-- Assembler State Behaviors
-- ============================================================================
-- State-specific behavior functions for the Assembler state machine
-- Each function receives a context table and can trigger FSM transitions

local Recipe = require("src.evolved.fragments.recipe")
local helpers = require("src.evolved.behaviors.machines.assembler.helpers")
local set = Evolved.set

local states = {}
local DEBUG = true

-- ============================================================================
-- BLANK State - No recipe set
-- ============================================================================

--- Handle BLANK state (no recipe set)
--- @param context table The update context
function states.blank(context)
   -- REFACTOR: Auto-assign recipe if none set (this could be driven by UI later)
   if not helpers.isValidRecipe(context.recipe) then
      local newRecipe = Recipe.new("createSkeleton")
      set(context.machineId, FRAGMENTS.CurrentRecipe, newRecipe)
      context.recipe = newRecipe

      if DEBUG then
         Log.info("Assembler: "..context.machineName.." assigned recipe: "..newRecipe.name)
      end
   end

   -- Transition to idle once we have a valid recipe
   if helpers.isValidRecipe(context.recipe) then
      context.fsm:set_recipe()
      set(context.machineId, FRAGMENTS.ProcessingTimer, {current = context.recipe.processingTime, saved = 0})
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." -> idle")
      end
   end
end

-- ============================================================================
-- IDLE State - Recipe set, waiting for ingredients
-- ============================================================================

--- Handle IDLE state (recipe set, waiting for ingredients)
--- @param context table The update context
function states.idle(context)
   if helpers.hasRequiredIngredients(context.recipe, context.inventory) then
      context.fsm:prepare()
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." has ingredients -> ready")
      end
   end
end

-- ============================================================================
-- READY State - Has ingredients, ready to start
-- ============================================================================

--- Handle READY state (has ingredients, ready to start)
--- @param context table The update context
function states.ready(context)
   if not context.recipe then return end

   -- Check if ingredients were removed
   if not helpers.hasRequiredIngredients(context.recipe, context.inventory) then
      context.fsm:removeIngredients()
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." ingredients removed -> idle")
      end
   end
end

-- ============================================================================
-- WORKING State - Processing in progress
-- ============================================================================

--- Handle WORKING state (processing in progress)
--- @param context table The update context
function states.working(context)
   if not context.recipe then return end

   local timer = context.processingTimer
   local dt = context.dt

   -- Initialize timer if not set
   if timer.current <= 0 then
      timer.current = context.recipe.processingTime or 1
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." initialized timer: "..timer.current.."s")
      end
   end

   -- Check ingredients still present (consumed on complete)
   if context.recipe.inputs and not helpers.hasRequiredIngredients(context.recipe, context.inventory) then
      timer.current = 0
      if context.fsm:can("stop_ritual") then
         context.fsm:stop_ritual()
      elseif context.fsm:can("stop") then
         context.fsm:stop()
      end
      if DEBUG then
         Log.warn("Assembler: "..context.machineName.." ingredients missing -> idle")
      end

      return
   end

   -- Consume mana per tick
   if not helpers.consumeManaTick(context.recipe, context.mana, dt) then
      timer.saved = timer.current
      context.fsm:starve()
      if DEBUG then
         Log.warn("Assembler: "..context.machineName.." mana depleted -> noMana")
      end

      return
   end

   -- Update processing timer
   timer.current = timer.current - dt

   -- Check completion
   if timer.current <= 0 then
      -- Consume ingredients on complete
      if not helpers.consumeIngredients(context.recipe, context.inventory) then
         context.fsm:stop()

         return
      end

      -- Check output space and produce
      if helpers.hasOutputSpace(context.recipe, context.inventory) then
         local success = helpers.produceOutputs(context.recipe, context.inventory)

         if success then
            if DEBUG then
               Log.info("Assembler: "..context.machineName.." complete, produced outputs")
            end
            context.fsm:complete()
            timer.current = 0
         else
            context.fsm:block()
            if DEBUG then
               Log.warn("Assembler: "..context.machineName.." output full -> blocked")
            end
         end
      else
         context.fsm:block()
         if DEBUG then
            Log.warn("Assembler: "..context.machineName.." output full -> blocked")
         end
      end
   end
end

-- ============================================================================
-- BLOCKED State - Output slots full
-- ============================================================================

--- Handle BLOCKED state (output slots full)
--- @param context table The update context
function states.blocked(context)
   if helpers.hasOutputSpace(context.recipe, context.inventory) then
      context.fsm:unblock()
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." output space available -> idle")
      end
   end
end

-- ============================================================================
-- NO_MANA State - Mana depleted during processing
-- ============================================================================

--- Handle NO_MANA state (mana depleted during processing)
--- @param context table The update context
function states.noMana(context)
   if not helpers.hasEnoughManaForTick(context.recipe, context.mana) then
      return
   end

   -- Restore saved timer and resume
   local timer = context.processingTimer
   timer.current = timer.saved or 0
   timer.saved = 0

   context.fsm:refuel()
   if DEBUG then
      Log.info("Assembler: "..context.machineName.." mana restored -> working")
      Log.info("  Remaining time: "..timer.current.."s")
   end
end

return states
