--- Generator Class
--- A machine that automatically produces outputs over time
--- Does not require ingredients or preparation - starts working immediately
--- Extends the Machine base class

local Machine = require("src.entities.machine")
local Generator = Class("Generator", Machine)

--- Initialize a new generator
--- @param x number X position
--- @param y number Y position
--- @param id string Entity registry ID
function Generator:initialize(x, y, id)
   -- Call parent constructor
   Machine.initialize(self, x, y, id)

   -- Generator-specific: no additional properties needed
   -- Generators auto-start when recipe is set
end

--- Get FSM events for generator
--- Generator has simplified flow: set_recipe goes directly to working
--- No prepare state needed since there are no ingredients to wait for
--- @return table Array of FSM event definitions
function Generator:getFSMEvents()
   return {
      {name = "set_recipe", from = "blank",   to = "working"},
      {name = "complete",   from = "working", to = "idle"},
      {name = "restart",    from = "idle",    to = "working"},
      {name = "block",      from = "working", to = "blocked"},
      {name = "unblock",    from = "blocked", to = "idle"},
   }
end

return Generator
