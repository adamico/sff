local Assembler = Class("Assembler")

function Assembler:initialize(x, y, config)
   self.currentRecipe = nil
   self.input_slots = {}
   self.output_slots = {}
   self.position = Vector(x, y)

   self.color = config.color or Colors.WHITE
   self.creative = config.creative or false
   self.mana_per_tick = config.mana_per_tick or 0
   self.max_input_slots = config.max_input_slots or 0
   self.max_output_slots = config.max_output_slots or 0
   self.name = config.name or "assembler"
   self.recipes = config.recipes or {}
   self.size = config.size or Vector(64, 64)
   self.timers = config.timers or {}
   self.visual = config.visual or "square"
end

-- add function to clear input slots according to max_<>_slots

-- add utility functions, e.g. output per second, mana per second, etc.

return Assembler
