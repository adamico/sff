local RecipesData = require("src.data.recipes.creature_recipes")
local Recipe = {}

function Recipe.new(name)
   local data = RecipesData[name] or {}
   recipe = {
      name = data.name or "Empty Recipe",
      category = data.category or "Empty category",
      inputs = data.inputs or {},
      outputs = data.outputs or {},
      manaPerTick = data.manaPerTick or 0,
      processingTime = data.processingTime or 5,
      requiresRitual = data.requiresRitual or true,
   }

   return recipe
end

return Recipe
