local Inventory = require("src.evolved.fragments.inventory")

return {
   player = {
      color = Colors.BLUE,
      interactionRange = 128,
      inventory = Inventory.new({
         max_slots = 40,
      }),
      mana = {
         current = 100,
         max = 100,
         regen_rate = 1,
         consume_rate = 0,
      },
      maxSpeed = 300,
      name = "Player",
      shape = "circle",
      size = Vector(16, 16),
      tags = {"controllable", "physical", "player", "visual"},
      toolbar = Inventory.new({
         max_slots = 10,
         initial_items = {
            {item_id = "bone",          quantity = 10},
            {item_id = "skeleton",      quantity = 1},
            {item_id = "unlifeEssence", quantity = 10},
         },
      }),
   },
}
