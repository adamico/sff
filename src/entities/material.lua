local Material = Class("Material")

function Material:initialize(x, y, config)
   self.position = Vector(x, y)

   self.category = config.category or ""
   self.color = config.color or Colors.WHITE
   self.name = config.name or "material"
   self.size = config.size or Vector(8, 8)
   self.synthesis_cost = config.synthesis_cost or 0
   self.visual = config.visual or "square"
end

return Material
