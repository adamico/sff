local Bindings = {}

Bindings.actions = {
   MOVE_UP          = "move_up",
   MOVE_DOWN        = "move_down",
   MOVE_LEFT        = "move_left",
   MOVE_RIGHT       = "move_right",
   INTERACT         = "interact",
   CANCEL_PLACEMENT = "cancel_placement",
   OPEN_INVENTORY   = "open_inventory",
   CLOSE_INVENTORY  = "close_inventory",
   TOOLBAR_USE_0    = "toolbar_use_0",
   TOOLBAR_USE_1    = "toolbar_use_1",
   TOOLBAR_USE_2    = "toolbar_use_2",
   TOOLBAR_USE_3    = "toolbar_use_3",
   TOOLBAR_USE_4    = "toolbar_use_4",
   TOOLBAR_USE_5    = "toolbar_use_5",
   TOOLBAR_USE_6    = "toolbar_use_6",
   TOOLBAR_USE_7    = "toolbar_use_7",
   TOOLBAR_USE_8    = "toolbar_use_8",
   TOOLBAR_USE_9    = "toolbar_use_9",
}

Bindings.actionsToKeys = {
   move_up          = {type = "key", scancode = "w"},
   move_down        = {type = "key", scancode = "s"},
   move_left        = {type = "key", scancode = "a"},
   move_right       = {type = "key", scancode = "d"},
   interact         = {type = "mouse", button = 1},
   open_inventory   = {type = "key", scancode = "e"},
   close_inventory  = {type = "key", scancode = "q"},
   -- REFACTOR: we need to support multiple bindings for each action
   cancel_placement = {type = "mouse", button = 2},
   toolbar_use_0    = {type = "key", scancode = "0"},
   toolbar_use_1    = {type = "key", scancode = "1"},
   toolbar_use_2    = {type = "key", scancode = "2"},
   toolbar_use_3    = {type = "key", scancode = "3"},
   toolbar_use_4    = {type = "key", scancode = "4"},
   toolbar_use_5    = {type = "key", scancode = "5"},
   toolbar_use_6    = {type = "key", scancode = "6"},
   toolbar_use_7    = {type = "key", scancode = "7"},
   toolbar_use_8    = {type = "key", scancode = "8"},
   toolbar_use_9    = {type = "key", scancode = "9"},
}

return Bindings
