local data = require("src/data/mana_pool_data")
local ManaPool = Class("ManaPool")

function ManaPool:initialize()
   self.max_mana = data.max_mana
   self.regen_rate = data.regen_rate

   self.mana = self.max_mana
end

return ManaPool
