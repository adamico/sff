return {
   skeleton_assembler = {
      class = "Assembler",
      color = Colors.PURPLE,
      interactable = true,
      mana_per_tick = 1,
      inventory = {
         max_input_slots = 2,
         max_output_slots = 1,
      },
      name = "Skeleton Assembler",
      recipes = {"create_skeleton"},
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
         max_input_slots = 32,
         max_output_slots = 0,
         initial_items = {
            bone = 1
         }
      },
      name = "Creative Chest",
      size = Vector(32, 32),
      visual = "rectangle",
   },
}
