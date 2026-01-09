--- Assembler Class
--- A machine that uses mana and rituals to process recipes
--- Extends the Machine base class

local Machine = require("src.entities.machine")
local Assembler = Class("Assembler", Machine)

--- @class Assembler
--- @field id string Entity registry ID
--- @field position table Position vector
--- @field currentRecipe RecipeComponent Current recipe being processed
--- @field processingTimer number Timer for processing time
--- @field savedTimer number Timer for saved processing time
--- @field mana number Mana resource
--- @field name string Name of the machine
--- @field valid_recipes table Valid recipes for this machine
--- @field size table Size of the machine
--- @field color table Color of the machine
--- @field creative boolean Whether the machine is creative
--- @field interactable boolean Whether the machine is interactable
--- @field visual string Visual representation of the machine
--- @method getFSMEvents() Get the FSM events for the machine
--- @method getState() Get the current state of the machine
--- @method getProgress() Get the progress of the current recipe
--- @method isValidRecipe(recipe Recipe) Check if a recipe is valid for this machine

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
