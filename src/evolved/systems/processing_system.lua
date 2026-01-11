local builder = Evolved.builder
local set = Evolved.set
local Recipe = require("src.evolved.fragments.recipe")
local PROCESSING_DEBUG = true -- Set to false to disable debug logging

local function countIngredients(inputSlots)
   local counts = {}
   for _, slot in ipairs(inputSlots) do
      if slot.item_id then
         counts[slot.item_id] = (counts[slot.item_id] or 0) + (slot.quantity or 1)
      end
   end

   return counts
end

local requiredIngredientsNotify = false
local function hasRequiredIngredients(recipe, inventory)
   if not recipe.inputs then return true end -- Recipe has no ingredient requirements
   if not requiredIngredientsNotify and PROCESSING_DEBUG then
      Log.debug("ProcessingSystem: Checking required ingredients for recipe "..recipe.name)
      Log.debug("ProcessingSystem: Recipe "..recipe.name.." has ingredient requirements")
      Log.debug("ProcessingSystem: Recipe "..recipe.name.." has "..inspect(recipe.inputs).." ingredient requirements")
      requiredIngredientsNotify = true
   end

   local available = countIngredients(inventory.input_slots)
   for ingredient, requiredAmount in pairs(recipe.inputs) do
      if (available[ingredient] or 0) < requiredAmount then
         return false
      end
   end
   return true
end

local blankNotify = false
local function handleBlankState(machineName, fsm, recipe)
   if not recipe or recipe.name == "empty" or recipe.name == "Empty Recipe" then
      if not blankNotify and PROCESSING_DEBUG then
         Log.warn("ProcessingSystem: "..machineName.." waiting for recipe to be set.")
         blankNotify = true
      end
      return
   end

   if PROCESSING_DEBUG then
      Log.info("ProcessingSystem: "..machineName.." - Recipe "..inspect(recipe).." set, transitioning to IDLE")
      blankNotify = false
   end
   fsm:set_recipe()
end

local function handleIdleState(machineName, fsm, recipe, inventory)
   if hasRequiredIngredients(recipe, inventory) then
      fsm:prepare()
      if PROCESSING_DEBUG then
         Log.info("ProcessingSystem: "..machineName.." - Prepared, transitioning to READY")
      end
   end
end

local readyNotify = false
local function handleReadyState(machineName)
   if not readyNotify and PROCESSING_DEBUG then
      Log.info("ProcessingSystem: "..machineName.." - Ready")
      readyNotify = true
   end
end

local workingNotify = false
local function handleWorkingState(machineName)
   if not workingNotify and PROCESSING_DEBUG then
      Log.info("ProcessingSystem: "..machineName.." - Working")
      workingNotify = true
   end
end

local blockedNotify = false
local function handleBlockedState(machineName)
   if not blockedNotify and PROCESSING_DEBUG then
      Log.info("ProcessingSystem: "..machineName.." - Blocked")
      blockedNotify = true
   end
end

local noManaNotify = false
local function handleNoManaState(machineName)
   if not noManaNotify and PROCESSING_DEBUG then
      Log.info("ProcessingSystem: "..machineName.." - No Mana")
      noManaNotify = true
   end
end

builder()
   :name("SYSTEMS.Processing")
   :group(STAGES.OnUpdate)
   :include(TAGS.Processing)
   :execute(function(chunk, entityIds, entityCount)
      for i = 1, entityCount do
         local state = chunk:components(FRAGMENTS.StateMachine)[i].current
         local machineId = entityIds[i]
         local machineName = chunk:components(Evolved.NAME)[i]..machineId
         local fsm = chunk:components(FRAGMENTS.StateMachine)[i]
         local recipe = chunk:components(FRAGMENTS.CurrentRecipe)[i]
         local inventory = chunk:components(FRAGMENTS.Inventory)[i]

         if state == "blank" then
            local newRecipe = Recipe.new("create_skeleton")
            set(machineId, FRAGMENTS.CurrentRecipe, newRecipe)
            handleBlankState(machineName, fsm, newRecipe)
         elseif state == "idle" then
            handleIdleState(machineName, fsm, recipe, inventory)
         elseif state == "ready" then
            handleReadyState(machineName)
         elseif state == "working" then
            handleWorkingState(machineName)
         elseif state == "blocked" then
            handleBlockedState(machineName)
         elseif state == "no_mana" then
            handleNoManaState(machineName)
         end
      end
   end):build()
