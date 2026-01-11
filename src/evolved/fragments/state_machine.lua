local statemachine = require("lib.statemachine")
local StateMachine = {}

function StateMachine.new(data)
   data = data or {}
   local fsm = statemachine.create({
      initial = "blank",
      events = data.events or {},
      callbacks = data.callbacks or {},
   })

   return fsm
end

function StateMachine.duplicate(fsm)
   local new_fsm = statemachine.create({
      initial = fsm.current,
      events = fsm.options.events,
      callbacks = fsm.options.callbacks,
   })

   return new_fsm
end

return StateMachine
