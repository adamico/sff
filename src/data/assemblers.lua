return {
   skeleton_assembler = {
      class = "Assembler",
      color = Colors.PURPLE,
      interactable = true,
      mana_per_tick = 1,
      max_input_slots = 2,
      max_output_slots = 1,
      name = "Skeleton Assembler",
      recipes = {"create_skeleton"},
      size = Vector(64, 64),
      timers = {
         processing = 5 -- seconds
      },
      visual = "square",
   },
}
