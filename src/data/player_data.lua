return {
   color = Colors.BLUE,
   interactionRange = 128,
   inventory = {
      max_slots = 40,

   },
   toolbar = {
      max_slots = 10,
      initial_items = {
         {item_id = "bone",     quantity = 10},
         {item_id = "skeleton", quantity = 1},
         {item_id = "essence",  quantity = 10},
      },
   },
   mana = {
      current = 100,
      max = 100,
      regen_rate = 1,
      consume_rate = 0,
   },
   maxSpeed = 300,
   name = "Player",
   size = 16,
   visual = "circle",
}
