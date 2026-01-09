local Recipes = require("src.data.recipes_data")

return {
   skeleton_assembler = {
      class = "Assembler",
      color = Colors.PURPLE,
      interactable = true,
      inventory = {
         max_input_slots = 2,
         max_output_slots = 1,
      },
      mana = 10,
      mana_per_tick = 1,
      name = "Skeleton Assembler",
      recipes = {Recipes.create_skeleton},
      size = Vector(64, 64),
      timers = {
         processing = 5 -- seconds
      },
      visual = "rectangle",
   },
   creative_chest = {
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
