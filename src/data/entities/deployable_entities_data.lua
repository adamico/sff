local Inventory = require("src.evolved.fragments.inventory")
local InputQueue = require("src.evolved.fragments.input_queue")
local StateMachine = require("src.evolved.fragments.state_machine")
local Recipes = require("src.data.recipes_data")
local Sprite = require("src.evolved.fragments.sprite")

return {
   skeletonAssembler = {
      hitbox = {
         shape = "rectangle",
         offsetX = 0,
         offsetY = 0,
         width = 64,
         height = 64,
      },
      inputQueue = InputQueue.new(),
      inventory = Inventory.new({
         slotGroups = {
            input = {
               maxSlots = 2,
               displayOrder = 1,
               initialItems = {},
            },
            output = {
               maxSlots = 1,
               displayOrder = 2,
               initialItems = {},
            },
         }
      }),
      interaction = {type = "machine"},
      machineClass = "Assembler",
      mana = {
         current = 100,
         max = 100,
         regenRate = 0,
         consumeRate = 1,
      },
      name = "Skeleton Assembler",
      processingTimer = {current = 0, saved = 0, duration = 5},
      stateMachine = StateMachine.new({
         events = {
            {name = "set_recipe",        from = "blank",   to = "idle"},
            {name = "prepare",           from = "idle",    to = "ready"},
            {name = "removeIngredients", from = "ready",   to = "idle"},
            {name = "startRitual",       from = "ready",   to = "working"},
            {name = "stop_ritual",       from = "working", to = "idle"},
            {name = "complete",          from = "working", to = "idle"},
            {name = "stop",              from = "working", to = "idle"},
            {name = "block",             from = "working", to = "blocked"},
            {name = "unblock",           from = "blocked", to = "idle"},
            {name = "starve",            from = "working", to = "noMana"},
            {name = "refuel",            from = "noMana",  to = "working"},
         }
      }),
      tags = {"interactable", "physical", "processing", "static"},
      validRecipes = {Recipes.createSkeleton},
   },
   chest = {
      hitbox = {
         shape = "rectangle",
         offsetX = 0,
         offsetY = 4,
         width = 16,
         height = 12,
      },
      inventory = Inventory.new({
         slotGroups = {
            default = {
               initialItems = {},
               maxSlots = 32,
            },
         },
      }),
      interaction = {type = "storage"},
      name = "Chest",
      sprite = Sprite.new({
         texture = "chest_lever.png",
         offsetX = -16,
         offsetY = -16,
         x = 0,
         y = 80,
         width = 32,
         height = 32,
      }),
      tags = {"interactable", "physical", "static"},
   },
}
