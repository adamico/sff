local Creature = Class("Creature")

function Creature:initialize(x, y, config)
   self.position = Vector(x, y)

   self.color = config.color or Colors.WHITE
   self.harvest_time = config.harvest_time or 5
   self.harvest_yield = config.harvest_yield or 25
   self.name = config.name or "creature"
   self.recycle_returns = config.recycle_returns or {}
   self.size = config.size or 16
   self.tier = config.tier or "basic"
   self.visual = config.visual or "square"
end

return Creature
