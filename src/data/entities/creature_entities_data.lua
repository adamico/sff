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
      void = 35,
      hitbox = {
         shape = "circle",
         offsetX = 0,
         offsetY = -4,
         radius = 4,
      },
      interaction = {type = "creature", action = "inspect"},
      loot = Inventory.new({
         maxSlots = 2,
         accessMode = "io",
         initialItems = {
            {itemId = "blackBile",  quantity = 80},
            {itemId = "yellowBile", quantity = 20},
         },
      }),
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
         spriteSheet = "Skeleton1.png",
      }),
   },
   ghost = {
      creatureClass = "DamageDealer",
      health = {
         current = 5,
         max = 5,
      },
      void = 95,
      hitbox = {
         shape = "circle",
         offsetX = 0,
         offsetY = -4,
         radius = 4,
      },
      interaction = {type = "creature", action = "inspect"},
      loot = Inventory.new({
         maxSlots = 2,
         accessMode = "io",
         initialItems = {
            {itemId = "phlegm", quantity = 90},
            {itemId = "blood",  quantity = 10},
         },
      }),
      maxSpeed = 240,
      name = "Ghost",
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
         spriteSheet = "Ghost1.png",
      }),
   },
}
