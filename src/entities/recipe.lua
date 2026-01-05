local Recipe = Class("Recipe")

function Recipe:initialize(config)
   self.category = config.category or ""
   self.inputs = config.inputs or {}
   self.mana_cost = config.mana_cost or 0
   self.name = config.name or "recipe"
   self.outputs = config.outputs or {}
   self.processing_time = config.processing_time or 0
end

return Recipe
