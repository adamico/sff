local Inventory = require("src.evolved.fragments.inventory")
local StateMachine = require("src.evolved.fragments.state_machine")
local Animation = require("src.evolved.fragments.animation")

return {
   skeleton = {
      creatureClass = "DamageDealer",
      health = {
         current = 20,
         max = 20,
      },
      hitbox = {
         shape = "circle",
         offsetX = 0,
         offsetY = 0,
         radius = 8,
      },
      interaction = {type = "creature", action = "inspect"},
      loot = Inventory.new({
         slotGroups = {
            default = {
               maxSlots = 2,
               initialItems = {
                  {itemId = "bone",          quantity = 1},
                  {itemId = "unlifeEssence", quantity = 1},
               },
            }
         }
      }),
      mana = {
         current = 25,
         max = 25,
      },
      maxSpeed = 120,
      name = "Skeleton",
      stateMachine = StateMachine.new({
         events = {
            {name = "spawn",  from = "blank",   to = "idle"},
            {name = "alert",  from = "idle",    to = "alert"},
            {name = "chase",  from = "alert",   to = "chasing"},
            {name = "attack", from = "chasing", to = "attacking"},
            {name = "reset",  from = "*",       to = "idle"},
         }
      }),
      tags = {"creature", "damageable", "harvestable", "interactable", "physical", "animated"},
      tier = "basic",
      animation = Animation.new({
         spriteSheets = {
            sword = "skeleton_sword.png",
         }
      }),
   },
}
