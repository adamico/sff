local Inventory = require("src.evolved.fragments.inventory")
local Animation = require("src.evolved.fragments.animation")

return {
   player = {
      damage = {
         min = 10,
         max = 10,
      },
      weaponSlot = Inventory.new({
         maxSlots = 1,
         acceptedCategories = {"weapon", "harvester"},
         accessMode = "io",
         initialItems = {
            {itemId = "daggerBasic", quantity = 1},
         },
      }),
      armorSlot = Inventory.new({
         maxSlots = 1,
         acceptedCategories = {"armor"},
         accessMode = "io",
         initialItems = {
            {itemId = "armorBasic", quantity = 1},
         },
      }),
      hitbox = {
         shape = "circle",
         offsetX = 0,
         offsetY = -4,
         radius = 4,
      },
      interactionRange = 128,
      inventory = Inventory.new({
         maxSlots = 40,
         accessMode = "io",
         initialItems = {
            {itemId = "bone",          quantity = 32},
            {itemId = "unlifeEssence", quantity = 63},
         },
      }),
      mana = {
         current = 95,
         max = 100,
         regenRate = 1,
         consumeRate = 0,
      },
      maxSpeed = 170,
      name = "Player",
      tags = {"controllable", "physical", "player", "animated"},
      toolbar = Inventory.new({
         maxSlots = 10,
         accessMode = "io",
         initialItems = {
            {itemId = "skeletonAssembler", quantity = 1},
            {itemId = "chest",             quantity = 1},
            {itemId = "skeleton",          quantity = 1},
            {itemId = "harvesterBasic",    quantity = 1},
         },
      }),
      animation = Animation.new({
         spriteSheets = {
            sword = "player_sword.png",
         }
      }),
   },
}
