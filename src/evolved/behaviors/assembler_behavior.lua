--[[
   Assembler Behaviors

   Defines the update logic for Assembler-class machines.
   Each behavior receives a context table and can trigger FSM transitions.

   Context structure:
   {
      entityId = number,           -- Entity ID
      machineName = string,         -- Display name for logging
      fsm = table,                  -- State machine instance
      recipe = table,               -- Current recipe
      inventory = table,            -- Machine inventory
      inputQueue = table,           -- Input action queue
      mana = table,                 -- {current, max}
      processingTimer = table,      -- {current, saved}
      dt = number,                  -- Delta time
   }
]]

local Recipe                        = require("src.evolved.fragments.recipe")
local ItemRegistry                  = require("src.registries.item_registry")
local InventoryHelper               = require("src.helpers.inventory_helper")
local input_queue                   = require("src.evolved.fragments.input_queue")
local get                           = Evolved.get
local set                           = Evolved.set
local observe                       = Beholder.observe

local Assembler                     = {}

local DEBUG                         = true
local MANA_RESUME_THRESHOLD_SECONDS = 1.0

--------------------------------------------------------------------------------
-- Ingredient Helpers
--------------------------------------------------------------------------------

--- Count available ingredients in input slots
--- @param inventory table The machine inventory
--- @return table ingredientCounts Map of item_id to quantity
local function countIngredients(inventory)
   local counts = {}
   local slots = InventoryHelper.getSlots(inventory, "input")
   if not slots then return counts end

   for _, slot in ipairs(slots) do
      if slot.item_id then
         counts[slot.item_id] = (counts[slot.item_id] or 0) + (slot.quantity or 1)
      end
   end
   return counts
end

--- Check if inventory has required ingredients for recipe
--- @param recipe table The current recipe
--- @param inventory table The machine inventory
--- @return boolean hasIngredients
local function hasRequiredIngredients(recipe, inventory)
   if not recipe or not recipe.inputs then return true end

   local available = countIngredients(inventory)
   for ingredient, requiredAmount in pairs(recipe.inputs) do
      if (available[ingredient] or 0) < requiredAmount then
         return false
      end
   end
   return true
end

--- Consume ingredients from input slots
--- @param recipe table The current recipe
--- @param inventory table The machine inventory
--- @return boolean success
local function consumeIngredients(recipe, inventory)
   if not recipe or not recipe.inputs then return true end

   for ingredient, amount in pairs(recipe.inputs) do
      local remaining = amount
      local slots = InventoryHelper.getSlots(inventory, "input")
      for _, slot in ipairs(slots or {}) do
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
         Log.error("Assembler: Failed to consume all of ingredient: "..ingredient)
         return false
      end
   end

   return true
end

--- Check if recipe is valid (not empty/default)
--- @param recipe table The recipe to check
--- @return boolean isValid
local function isValidRecipe(recipe)
   return recipe and recipe.name ~= "empty" and recipe.name ~= "Empty Recipe"
end

--------------------------------------------------------------------------------
-- Mana Helpers
--------------------------------------------------------------------------------

--- Consume mana per tick
--- @param recipe table The current recipe
--- @param mana table The mana component {current, max}
--- @param dt number Delta time
--- @return boolean success True if mana was consumed, false if insufficient
local function consumeManaTick(recipe, mana, dt)
   if not recipe then return true end

   local manaPerTick = recipe.mana_per_tick or 0
   if manaPerTick == 0 then return true end

   local manaCost = manaPerTick * dt
   local manaEpsilon = 0.01

   if (mana.current or 0) >= manaCost - manaEpsilon then
      mana.current = mana.current - manaCost
      return true
   end

   return false
end

--- Check if machine has enough mana for at least one tick
--- @param recipe table The current recipe
--- @param mana table The mana component
--- @return boolean hasEnoughMana
local function hasEnoughManaForTick(recipe, mana)
   if not recipe then return true end

   local manaPerTick = recipe.mana_per_tick or 0
   if manaPerTick == 0 then return true end

   local requiredMana = manaPerTick * MANA_RESUME_THRESHOLD_SECONDS
   return (mana.current or 0) >= requiredMana
end

--------------------------------------------------------------------------------
-- Output Helpers
--------------------------------------------------------------------------------

--- Check if output slots have space for recipe outputs
--- @param recipe table The current recipe
--- @param inventory table The machine inventory
--- @return boolean hasSpace
local function hasOutputSpace(recipe, inventory)
   local slots = InventoryHelper.getSlots(inventory, "output")
   if not slots then return true end
   if #slots == 0 then return true end

   -- Check for empty slots
   for _, slot in ipairs(slots) do
      if not slot.item_id then
         return true
      end
   end

   -- Check if any existing slot can stack more
   if recipe and recipe.outputs then
      for output_id, _ in pairs(recipe.outputs) do
         local maxStack = ItemRegistry.getMaxStackSize(output_id)
         for _, slot in ipairs(slots) do
            if slot.item_id == output_id and (slot.quantity or 0) < maxStack then
               return true
            end
         end
      end
   end

   return false
end

--- Produce output items in the output slots with stacking support
--- @param recipe table The current recipe
--- @param inventory table The machine inventory
--- @return boolean success
local function produceOutputs(recipe, inventory)
   if not recipe or not recipe.outputs then return true end
   local slots = InventoryHelper.getSlots(inventory, "output")
   if not slots or #slots == 0 then return true end

   for output_id, amount in pairs(recipe.outputs) do
      local remaining = amount
      local maxStack = ItemRegistry.getMaxStackSize(output_id)

      -- First, try to stack with existing slots
      for _, slot in ipairs(slots) do
         if remaining <= 0 then break end

         if slot.item_id == output_id and (slot.quantity or 0) < maxStack then
            local canAdd = math.min(remaining, maxStack - (slot.quantity or 0))
            slot.quantity = (slot.quantity or 0) + canAdd
            remaining = remaining - canAdd
         end
      end

      -- Then, fill empty slots
      for _, slot in ipairs(slots) do
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

            for _, slot in ipairs(slots) do
               if slot.item_id == output_id and (slot.quantity or 0) < maxStack then
                  slot.quantity = (slot.quantity or 0) + 1
                  break
               elseif not slot.item_id then
                  slot.item_id = output_id
                  slot.quantity = 1
                  break
               end
            end
            -- If no space for bonus, silently skip
         end
      end
   end

   return true
end

--------------------------------------------------------------------------------
-- State Behaviors
--------------------------------------------------------------------------------

--- Handle BLANK state (no recipe set)
--- @param context table The update context
function Assembler.blank(context)
   -- REFACTOR: Auto-assign recipe if none set (this could be driven by UI later)
   if not isValidRecipe(context.recipe) then
      local newRecipe = Recipe.new("createSkeleton")
      set(context.machineId, FRAGMENTS.CurrentRecipe, newRecipe)
      context.recipe = newRecipe

      if DEBUG then
         Log.info("Assembler: "..context.machineName.." assigned recipe: "..newRecipe.name)
      end
   end

   -- Transition to idle once we have a valid recipe
   if isValidRecipe(context.recipe) then
      context.fsm:set_recipe()
      set(context.machineId, FRAGMENTS.ProcessingTimer, {current = recipe.processing_time, saved = 0})
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." -> idle")
      end
   end
end

--- Handle IDLE state (recipe set, waiting for ingredients)
--- @param context table The update context
function Assembler.idle(context)
   if hasRequiredIngredients(context.recipe, context.inventory) then
      context.fsm:prepare()
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." has ingredients -> ready")
      end
   end
end

--- Handle READY state (has ingredients, ready to start)
--- @param context table The update context
function Assembler.ready(context)
   if not context.recipe then return end

   -- Check if ingredients were removed
   if not hasRequiredIngredients(context.recipe, context.inventory) then
      context.fsm:remove_ingredients()
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." ingredients removed -> idle")
      end
   end
end

--- Handle WORKING state (processing in progress)
--- @param context table The update context
function Assembler.working(context)
   if not context.recipe then return end

   local timer = context.processingTimer
   local dt = context.dt

   -- Initialize timer if not set
   if timer.current <= 0 then
      timer.current = context.recipe.processing_time or 1
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." initialized timer: "..timer.current.."s")
      end
   end

   -- Check ingredients still present (consumed on complete)
   if context.recipe.inputs and not hasRequiredIngredients(context.recipe, context.inventory) then
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
   if not consumeManaTick(context.recipe, context.mana, dt) then
      timer.saved = timer.current
      context.fsm:starve()
      if DEBUG then
         Log.warn("Assembler: "..context.machineName.." mana depleted -> no_mana")
      end

      return
   end

   -- Update processing timer
   timer.current = timer.current - dt

   -- Check completion
   if timer.current <= 0 then
      -- Consume ingredients on complete
      if not consumeIngredients(context.recipe, context.inventory) then
         context.fsm:stop()

         return
      end

      -- Check output space and produce
      if hasOutputSpace(context.recipe, context.inventory) then
         local success = produceOutputs(context.recipe, context.inventory)

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

--- Handle BLOCKED state (output slots full)
--- @param context table The update context
function Assembler.blocked(context)
   if hasOutputSpace(context.recipe, context.inventory) then
      context.fsm:unblock()
      if DEBUG then
         Log.info("Assembler: "..context.machineName.." output space available -> idle")
      end
   end
end

--- Handle NO_MANA state (mana depleted during processing)
--- @param context table The update context
function Assembler.no_mana(context)
   if not hasEnoughManaForTick(context.recipe, context.mana) then
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

--------------------------------------------------------------------------------
-- Action Handlers
--------------------------------------------------------------------------------

--- Handlers for queued actions
--- Each handler receives the context and returns true if the action was handled
local ACTION_HANDLERS = {
   --- Start the ritual if FSM can transition
   start_ritual = function(context)
      -- Validate preconditions
      if not isValidRecipe(context.recipe) then
         if DEBUG then
            Log.warn("Assembler: "..context.machineName.." no valid recipe set")
         end
         return false
      end

      if not hasRequiredIngredients(context.recipe, context.inventory) then
         if DEBUG then
            Log.warn("Assembler: "..context.machineName.." missing ingredients")
         end
         return false
      end

      -- Set processing timer and transition
      context.processingTimer.current = context.recipe.processing_time or 1
      context.fsm:start_ritual()

      if DEBUG then
         Log.info("Assembler: "..context.machineName.." ritual started")
         Log.info("  Processing time: "..context.processingTimer.current.."s")
      end

      return true
   end,
}

--- Drain the input queue and process all pending actions
--- @param context table The update context
local function drainQueue(context)
   if not context.inputQueue then return end

   input_queue.drain(context.inputQueue, function(action)
      local handler = ACTION_HANDLERS[action.type]
      if handler then
         handler(context)
      elseif DEBUG then
         Log.warn("Assembler: Unknown action type: "..tostring(action.type))
      end
   end)
end

--------------------------------------------------------------------------------
-- Main Update
--------------------------------------------------------------------------------

--- Update function called by the processing system
--- Dispatches to the appropriate state behavior
--- @param context table The update context
function Assembler.update(context)
   -- First, drain any pending actions from external sources
   drainQueue(context)

   -- Then, run state-specific behavior
   local state = context.fsm.current
   local behavior = Assembler[state]

   if behavior then
      behavior(context)
   elseif DEBUG then
      Log.warn("Assembler: No behavior defined for state: "..tostring(state))
   end
end

--------------------------------------------------------------------------------
-- Observers setup
--------------------------------------------------------------------------------

observe(Events.RITUAL_STARTED, function(payload)
   local queue = get(payload.entityId, FRAGMENTS.InputQueue)
   if queue then
      input_queue.push(queue, {type = "start_ritual"})
   end
   if DEBUG then
      Log.info("Assembler: "..payload.machineName.." enqueued start_ritual")
   end
end)

return Assembler
