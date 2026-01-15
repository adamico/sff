local Inventory = require("src.evolved.fragments.inventory")

return {
   player = {
      damage = {
         min = 10,
         max = 10,
      },
      equipment = Inventory.new({
         maxSlots = 2,
         initialItems = {
            {itemId = "harvesterBasic", quantity = 1},
            {itemId = "armorBasic",     quantity = 1},
         },
      }),
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
