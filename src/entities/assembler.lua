--- Assembler Class
--- A machine that uses mana and rituals to process recipes
--- Extends the Machine base class

local Machine = require("src.entities.machine")
local Assembler = Class("Assembler", Machine)

--- Initialize a new assembler
--- @param x number X position
--- @param y number Y position
--- @param id string Entity registry ID
function Assembler:initialize(x, y, id)
   -- Call parent constructor
   Machine.initialize(self, x, y, id)

   -- Assembler-specific: no additional properties needed
   -- Mana is already set in Machine base class from data.mana
end

--- Get FSM events for assembler
--- Assembler has ritual-based start and mana-related states
--- @return table Array of FSM event definitions
function Assembler:getFSMEvents()
   return {
      {name = "set_recipe",   from = "blank",   to = "idle"},
      {name = "prepare",      from = "idle",    to = "ready"},
      {name = "start_ritual", from = "ready",   to = "working"},
      {name = "complete",     from = "working", to = "idle"},
      {name = "stop",         from = "working", to = "idle"},
      {name = "block",        from = "working", to = "blocked"},
      {name = "unblock",      from = "blocked", to = "idle"},
      {name = "starve",       from = "working", to = "no_mana"},
      {name = "refuel",       from = "no_mana", to = "working"},
   }
end

return Assembler
