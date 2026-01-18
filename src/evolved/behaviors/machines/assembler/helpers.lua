-- ============================================================================
-- Assembler Helpers
-- ============================================================================
-- Utility functions for managing ingredients, mana, and outputs in Assemblers

local Recipe = require("src.evolved.fragments.recipe")
local InventoryHelper = require("src.helpers.inventory_helper")

local helpers = {}

-- Constants
helpers.MANA_RESUME_THRESHOLD_SECONDS = 1.0

-- ============================================================================
-- Ingredient Helpers
-- ============================================================================

--- Count available ingredients in input slots
--- @param inventory table The machine inventory
--- @return table ingredientCounts Map of itemId to quantity
function helpers.countIngredients(inventory)
   local counts = {}
   local slots = InventoryHelper.getSlots(inventory, "input")
   if not slots then return counts end

   for _, slot in ipairs(slots) do
      if slot.itemId then
         counts[slot.itemId] = (counts[slot.itemId] or 0) + (slot.quantity or 1)
      end
   end
   return counts
end

--- Check if inventory has required ingredients for recipe
--- @param recipe table The current recipe
--- @param inventory table The machine inventory
--- @return boolean hasIngredients
function helpers.hasRequiredIngredients(recipe, inventory)
   if not recipe or not recipe.inputs then return true end

   local available = helpers.countIngredients(inventory)
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
function helpers.consumeIngredients(recipe, inventory)
   if not recipe or not recipe.inputs then return true end

   for ingredient, amount in pairs(recipe.inputs) do
      local remaining = amount
      local slots = InventoryHelper.getSlots(inventory, "input")
      for _, slot in ipairs(slots or {}) do
         if slot.itemId == ingredient and remaining > 0 then
            local toRemove = math.min(remaining, slot.quantity or 0)
            slot.quantity = slot.quantity - toRemove
            remaining = remaining - toRemove

            if slot.quantity <= 0 then
               slot.itemId = nil
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
function helpers.isValidRecipe(recipe)
   return recipe and recipe.name ~= "empty" and recipe.name ~= "Empty Recipe"
end

-- ============================================================================
-- Mana Helpers
-- ============================================================================

--- Consume mana per tick
--- @param recipe table The current recipe
--- @param mana table The mana component {current, max}
--- @param dt number Delta time
--- @return boolean success True if mana was consumed, false if insufficient
function helpers.consumeManaTick(recipe, mana, dt)
   if not recipe then return true end

   local manaPerTick = recipe.manaPerTick or 0
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
function helpers.hasEnoughManaForTick(recipe, mana)
   if not recipe then return true end

   local manaPerTick = recipe.manaPerTick or 0
   if manaPerTick == 0 then return true end

   local requiredMana = manaPerTick * helpers.MANA_RESUME_THRESHOLD_SECONDS
   return (mana.current or 0) >= requiredMana
end

-- ============================================================================
-- Output Helpers
-- ============================================================================

--- Check if output slots have space for recipe outputs
--- @param recipe table The current recipe
--- @param inventory table The machine inventory
--- @return boolean hasSpace
function helpers.hasOutputSpace(recipe, inventory)
   local slots = InventoryHelper.getSlots(inventory, "output")
   if not slots then return true end
   if #slots == 0 then return true end

   -- Check for empty slots
   for _, slot in ipairs(slots) do
      if not slot.itemId then
         return true
      end
   end

   -- Check if any existing slot can stack more
   if recipe and recipe.outputs then
      for outputId, _ in pairs(recipe.outputs) do
         local maxStack = InventoryHelper.getMaxStackQuantity(outputId)
         for _, slot in ipairs(slots) do
            if slot.itemId == outputId and (slot.quantity or 0) < maxStack then
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
function helpers.produceOutputs(recipe, inventory)
   if not recipe or not recipe.outputs then return true end

   -- Add each output item using the canonical addItem function
   for outputId, amount in pairs(recipe.outputs) do
      local amountAdded = InventoryHelper.addItem(inventory, outputId, amount, "output")

      -- If we couldn't place all outputs, fail
      if amountAdded < amount then
         return false
      end
   end

   -- Handle chance-based outputs
   if recipe.output_chances then
      for outputId, chance in pairs(recipe.output_chances) do
         if math.random() < chance then
            -- Try to add 1 bonus item, silently skip if no space
            InventoryHelper.addItem(inventory, outputId, 1, "output")
         end
      end
   end

   return true
end

return helpers
