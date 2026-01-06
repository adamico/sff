local Bindings = {}

Bindings.actions = {
   MOVE_UP        = "move_up",
   MOVE_DOWN      = "move_down",
   MOVE_LEFT      = "move_left",
   MOVE_RIGHT     = "move_right",
   INTERACT       = "interact",
   OPEN_INVENTORY = "open_inventory",
}

Bindings.actionsToKeys = {
   move_up        = {type = "key", scancode = "w"},
   move_down      = {type = "key", scancode = "s"},
   move_left      = {type = "key", scancode = "a"},
   move_right     = {type = "key", scancode = "d"},
   interact       = {type = "mouse", button = 1},
   open_inventory = {type = "key", scancode = "e"},
}

return Bindings
