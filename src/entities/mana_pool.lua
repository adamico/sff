local ManaPool = Class("ManaPool")

function ManaPool:initialize(config)
   self.max_mana = config.max_mana or 0
   self.regen_rate = config.regen_rate or 0

   self.mana = self.max_mana
end

return ManaPool
