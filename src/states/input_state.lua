--- Input State Model
--- Manages the abstract state of the input context (Exploring, Placing, InventoryOpen)
--- Passive model driven by Managers.

local machine = require("lib.statemachine")

local InputState = {}

InputState.fsm = machine.create({
   initial = "exploring",
   events = {
      {name = "openInventory", from = {"exploring", "placing"}, to = "inventoryOpen"},
      {name = "startPlacing",  from = "exploring",              to = "placing"},
      {name = "closeModal",    from = "inventoryOpen",          to = "exploring"},
      {name = "cancelPlacing", from = "placing",                to = "exploring"},
   }
})

return InputState
