--- Machine Base Class
--- Abstract base class for all processing machines (Assembler, Generator, etc.)
--- Provides common properties, inventory, and FSM infrastructure

local statemachine = require("lib.statemachine")
local InventoryComponent = require("src.components.inventory_component")
local ManaComponent = require("src.components.mana_component")

local EntityRegistry = require("src.registries.entity_registry")

local Machine = Class("Machine")

--- @class Machine
--- Abstract base class for all processing machines (Assembler, Generator, etc.)
--- Provides common properties, inventory, and FSM infrastructure

--- Initialize a new machine
--- @param x number X position
--- @param y number Y position
--- @param id string Entity registry ID
function Machine:initialize(x, y, id)
   local data = EntityRegistry.getEntity(id) or {}

   -- Core identity
   self.id = id
   self.position = Vector(x, y)

   -- Processing state
   self.currentRecipe = nil
   self.processingTimer = 0
   self.savedTimer = 0 -- For resuming after NO_MANA

   -- Configuration from data
   self.name = data.name or "Machine"
   self.valid_recipes = data.recipes or {}
   self.size = data.size or Vector(64, 64)
   self.color = data.color or Colors.WHITE
   self.creative = data.creative or false
   self.interactable = data.interactable or false
   self.visual = data.visual or "square"

   -- Components
   self.inventory = InventoryComponent:new(data.inventory)
   self.mana = ManaComponent:new(data.mana)

   -- FSM - subclasses override getFSMEvents()
   self.fsm = statemachine.create({
      initial = "blank",
      events = self:getFSMEvents(),
   })
end

--- Get FSM events for this machine type
--- Subclasses should override this method
--- @return table Array of FSM event definitions
function Machine:getFSMEvents()
   return {}
end

--- Get the current FSM state
--- @return string Current state name
function Machine:getState()
   return self.fsm.current
end

--- Get processing progress as percentage (0-100)
--- @return number Progress percentage
function Machine:getProgress()
   if not self.currentRecipe or self.processingTimer <= 0 then
      return 0
   end

   local totalTime = self.currentRecipe.processing_time or 1
   local elapsed = totalTime - self.processingTimer
   return math.min(100, (elapsed / totalTime) * 100)
end

--- Check if a recipe is valid for this machine
--- @param recipe table The recipe to check
--- @return boolean True if valid
function Machine:isValidRecipe(recipe)
   for _, validRecipe in ipairs(self.valid_recipes) do
      if validRecipe == recipe then
         return true
      end
   end
   return false
end

return Machine
