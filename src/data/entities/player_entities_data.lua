local Inventory = require("src.evolved.fragments.inventory")
local Visual = require("src.evolved.fragments.visual")

return {
   player = {
      damage = {
         min = 10,
         max = 10,
      },
      equipment = Inventory.new({
         slotGroups = {
            weapon = {
               maxSlots = 1,
               displayOrder = 2,
               acceptedCategories = {"weapon", "harvester"},
               initialItems = {
                  {itemId = "daggerBasic", quantity = 1},
               },
            },
            armor = {
               maxSlots = 1,
               displayOrder = 1,
               acceptedCategories = {"armor"},
               initialItems = {
                  {itemId = "armorBasic", quantity = 1},
               },
            },
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
         slotGroups = {
            default = {
               maxSlots = 40,
               initialItems = {
                  {itemId = "bone",          quantity = 32},
                  {itemId = "unlifeEssence", quantity = 63},
               },
            },
         }
      }),
      mana = {
         current = 95,
         max = 100,
         regenRate = 1,
         consumeRate = 0,
      },
      maxSpeed = 300,
      name = "Player",
      visual = Visual.new({
         spriteSheets = {
            sword = "player_sword.png",
         }
      }),
      tags = {"controllable", "physical", "player", "visual"},
      toolbar = Inventory.new({
         slotGroups = {
            default = {
               maxSlots = 10,
               initialItems = {
                  {itemId = "skeletonAssembler", quantity = 1},
                  {itemId = "creativeChest",     quantity = 1},
                  {itemId = "skeleton",          quantity = 1},
                  {itemId = "harvesterBasic",    quantity = 1},
               },
            },
         },
      }),
   },
}
