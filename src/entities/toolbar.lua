local Toolbar = Class("Toolbar")

function Toolbar:initialize(config)
   self.active_row = 1
   self.active_slot = 1
   self.max_rows = 2
   self.slots_per_row = 10

   self.rows = config.rows or {}
end

return Toolbar
