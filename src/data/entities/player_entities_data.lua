local Inventory = require("src.evolved.fragments.inventory")

return {
   player = {
      color = Colors.BLUE,
      hitbox = {
         shape = "circle",
         offsetX = 0,
         offsetY = 0,
         radius = 8,
      },
      interactionRange = 128,
      inventory = Inventory.new({
         maxSlots = 40,
      }),
      mana = {
         current = 100,
         max = 100,
         regenRate = 1,
         consumeRate = 0,
      },
      maxSpeed = 300,
      name = "Player",
      shape = "circle",
      size = Vector(16, 16),
      tags = {"controllable", "physical", "player", "visual"},
      toolbar = Inventory.new({
         maxSlots = 10,
         initialItems = {
            {itemId = "skeletonAssembler", quantity = 1},
            {itemId = "creativeChest",     quantity = 1},
            {itemId = "skeleton",          quantity = 1},
         },
      }),
   },
}
