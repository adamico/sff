local RecipesData = require("src.data.recipes_data")
local Recipe = {}

function Recipe.new(name)
   local data = RecipesData[name] or {}
   recipe = {
      name = data.name or "Empty Recipe",
      category = data.category or "Empty category",
      inputs = data.inputs or {},
      outputs = data.outputs or {},
      mana_per_tick = data.mana_per_tick or 0,
      processing_time = data.processing_time or 5,
      requires_ritual = data.requires_ritual or true,
   }

   return recipe
end

return Recipe
