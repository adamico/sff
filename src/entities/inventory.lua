local Inventory = Class("Inventory")

function Inventory:initialize(config)
   self.max_slots = config.max_slots or 0
   self.items = config.items or {}
end

return Inventory
