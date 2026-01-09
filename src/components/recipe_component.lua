local RecipeComponent = Class("RecipeComponent")

--- @class RecipeComponent
--- @field category string Category of the recipe
--- @field inputs table Inputs required for the recipe
--- @field mana_cost number Mana cost for the recipe
--- @field name string Name of the recipe
--- @field outputs table Outputs produced by the recipe
--- @field processing_time number Processing time for the recipe

function RecipeComponent:initialize(config)
   self.category = config.category or ""
   self.inputs = config.inputs or {}
   self.mana_cost = config.mana_cost or 0
   self.name = config.name or "recipe"
   self.outputs = config.outputs or {}
   self.processing_time = config.processing_time or 0
end

return RecipeComponent
