local Recipes = require("src.data.recipes_data")

return {
   SkeletonAssembler = {
      class = "Assembler",
      color = Colors.PURPLE,
      events = {
         {name = "set_recipe",   from = "blank",   to = "idle"},
         {name = "prepare",      from = "idle",    to = "ready"},
         {name = "start_ritual", from = "ready",   to = "working"},
         {name = "complete",     from = "working", to = "idle"},
         {name = "stop",         from = "working", to = "idle"},
         {name = "block",        from = "working", to = "blocked"},
         {name = "unblock",      from = "blocked", to = "idle"},
         {name = "starve",       from = "working", to = "no_mana"},
         {name = "refuel",       from = "no_mana", to = "working"},
      },
      interactable = true,
      inventory = {
         max_input_slots = 2,
         max_output_slots = 1,
         initial_items = {
            {item_id = "bone", quantity = 1},
         }
      },
      mana = {
         current = 10,
         max = 100,
         consume_rate = 1,
      },
      name = "Skeleton Assembler",
      valid_recipes = {Recipes.create_skeleton},
      size = Vector(64, 64),
      timers = {
         processing = 5 -- seconds
      },
      visual = "rectangle",
   },
   CreativeChest = {
      class = "Storage",
      color = Colors.GOLD,
      creative = true,
      interactable = true,
      inventory = {
         max_input_slots = 2,
         initial_items = {
            {item_id = "bone",    quantity = 63},
            {item_id = "essence", quantity = 15}
         }
      },
      name = "Creative Chest",
      size = Vector(32, 32),
      visual = "rectangle",
   },
}
