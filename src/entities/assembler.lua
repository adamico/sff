local InventoryComponent = require("src.components.inventory_component")
local Assembler = Class("Assembler")
local ASSEMBLERS_DATA = require("src.data.assemblers_data")

function Assembler:initialize(x, y, id)
   local data = ASSEMBLERS_DATA[id] or {}
   self.id = id
   self.currentRecipe = nil
   self.position = Vector(x, y)

   self.color = data.color or Colors.WHITE
   self.creative = data.creative or false
   self.interactable = data.interactable or false
   self.mana_per_tick = data.mana_per_tick or 0
   self.name = data.name or "assembler"
   self.recipes = data.recipes or {}
   self.size = data.size or Vector(64, 64)
   self.timers = data.timers or {}
   self.visual = data.visual or "square"

   self.inventory = InventoryComponent:new(data.inventory)
end

-- add utility functions, e.g. output per second, mana per second, etc.

return Assembler
