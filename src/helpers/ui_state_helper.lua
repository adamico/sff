--- UI State Machine
--- Manages the current UI context for input handling
--- States: exploring, placing, inventoryOpen
local machine = require("lib.statemachine")
local observe = Beholder.observe

local UIState = {}

UIState.fsm = machine.create({
   initial = "exploring",
   events = {
      {name = "openInventory", from = {"exploring", "placing"}, to = "inventoryOpen"},
      {name = "startPlacing",  from = "exploring",              to = "placing"},
      {name = "closeModal",    from = "inventoryOpen",          to = "exploring"},
      {name = "cancelPlacing", from = "placing",                to = "exploring"},
   }
})

-- Bind state transitions to game events
observe(Events.INPUT_INVENTORY_OPENED, function()
   UIState.fsm:openInventory()
end)

observe(Events.INPUT_INTERACTION_CLICKED, function()
   UIState.fsm:openInventory()
end)

observe(Events.MACHINE_INTERACTED, function()
   UIState.fsm:openInventory()
end)

observe(Events.PLACEMENT_MODE_ENTERED, function()
   UIState.fsm:startPlacing()
end)

observe(Events.PLACEMENT_MODE_EXITED, function()
   UIState.fsm:cancelPlacing()
end)

observe(Events.UI_MODAL_CLOSED, function()
   UIState.fsm:closeModal()
end)

return UIState
