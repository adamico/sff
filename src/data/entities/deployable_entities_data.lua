local Inventory = require("src.evolved.fragments.inventory")
local InputQueue = require("src.evolved.fragments.input_queue")
local StateMachine = require("src.evolved.fragments.state_machine")
local Recipes = require("src.data.recipes_data")

return {
   skeletonAssembler = {
      color = Colors.PURPLE,
      inputQueue = InputQueue.new(),
      inventory = Inventory.new({
         max_input_slots = 2,
         max_output_slots = 1,
         initial_items = {
            {item_id = "bone", quantity = 1},
         }
      }),
      machineClass = "Assembler",
      mana = {
         current = 100,
         max = 100,
         regen_rate = 0,
         consume_rate = 1,
      },
      name = "Skeleton Assembler",
      processingTimer = {current = 0, saved = 0, duration = 5},
      shape = "rectangle",
      size = Vector(64, 64),
      stateMachine = StateMachine.new({
         events = {
            {name = "set_recipe",         from = "blank",   to = "idle"},
            {name = "prepare",            from = "idle",    to = "ready"},
            {name = "remove_ingredients", from = "ready",   to = "idle"},
            {name = "start_ritual",       from = "ready",   to = "working"},
            {name = "stop_ritual",        from = "working", to = "idle"},
            {name = "complete",           from = "working", to = "idle"},
            {name = "stop",               from = "working", to = "idle"},
            {name = "block",              from = "working", to = "blocked"},
            {name = "unblock",            from = "blocked", to = "idle"},
            {name = "starve",             from = "working", to = "no_mana"},
            {name = "refuel",             from = "no_mana", to = "working"},
         }
      }),
      tags = {"interactable", "physical", "processing", "visual"},
      validRecipes = {Recipes.createSkeleton},
   },
   creativeChest = {
      color = Colors.GOLD,
      inventory = Inventory.new({
         max_slots = 32,
         initial_items = {
            {item_id = "bone",          quantity = 63},
            {item_id = "unlifeEssence", quantity = 15}
         }
      }),
      name = "Creative Chest",
      shape = "rectangle",
      size = Vector(32, 32),
      tags = {"interactable", "physical", "visual"},
   },
}
