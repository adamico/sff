-- ============================================================================
-- ECS Fragments
-- ============================================================================
-- Fragments are data components that can be attached to entities
-- They define the properties and state that entities can have

local InputQueue = require("src.evolved.fragments.input_queue")
local Inventory = require("src.evolved.fragments.inventory")
local StateMachine = require("src.evolved.fragments.state_machine")
local Recipe = require("src.evolved.fragments.recipe")
local duplication = require("src.evolved.utils.duplication")
local evolvedConfig = require("src.evolved.evolved_config")
local builder = Evolved.builder

local duplicateVector = duplication.duplicateVector
local deepClone = duplication.deepClone

evolvedConfig.FRAGMENTS = {
   -- =========================================================================
   -- Physics Components
   -- =========================================================================

   Position = builder()
      :name("FRAGMENTS.Position")
      :default(Vector(0, 0))
      :duplicate(duplicateVector)
      :build(),

   Velocity = builder()
      :name("FRAGMENTS.Velocity")
      :default(Vector(0, 0))
      :duplicate(duplicateVector)
      :build(),

   MaxSpeed = builder()
      :name("FRAGMENTS.MaxSpeed")
      :default(300)
      :build(),

   Hitbox = builder()
      :name("FRAGMENTS.Hitbox")
      :default({
         shape = "circle",
         offsetX = 0,
         offsetY = 0,
         radius = 8,
      })
      :duplicate(deepClone)
      :build(),

   -- =========================================================================
   -- Input & Control Components
   -- =========================================================================

   Input = builder()
      :name("FRAGMENTS.Input")
      :default(Vector(0, 0))
      :duplicate(duplicateVector)
      :build(),

   InputQueue = builder()
      :name("FRAGMENTS.InputQueue")
      :default(InputQueue.new())
      :duplicate(deepClone)
      :build(),

   -- =========================================================================
   -- Inventory & Storage Components
   -- =========================================================================

   Inventory = builder()
      :name("FRAGMENTS.Inventory")
      :default(nil)
      :duplicate(Inventory.duplicate)
      :build(),

   Toolbar = builder()
      :name("FRAGMENTS.Toolbar")
      :default(nil)
      :duplicate(deepClone)
      :build(),

   -- =========================================================================
   -- Machine & Processing Components
   -- =========================================================================

   MachineClass = builder()
      :name("FRAGMENTS.MachineClass")
      :default(nil)
      :build(),

   CurrentRecipe = builder()
      :name("FRAGMENTS.CurrentRecipe")
      :default(Recipe.new("empty"))
      :duplicate(deepClone)
      :build(),

   ValidRecipes = builder()
      :name("FRAGMENTS.ValidRecipes")
      :default({})
      :duplicate(deepClone)
      :build(),

   ProcessingTimer = builder()
      :name("FRAGMENTS.ProcessingTimer")
      :default({current = 0, saved = 0})
      :duplicate(deepClone)
      :build(),

   StateMachine = builder()
      :name("FRAGMENTS.State")
      :default(StateMachine.new())
      :duplicate(StateMachine.duplicate)
      :build(),

   -- =========================================================================
   -- Resource Components
   -- =========================================================================

   Mana = builder()
      :name("FRAGMENTS.Mana")
      :default({current = 0, max = 100, regenRate = 0})
      :duplicate(deepClone)
      :build(),

   -- =========================================================================
   -- Interaction Components
   -- =========================================================================

   InteractionRange = builder()
      :name("FRAGMENTS.InteractionRange")
      :default(128)
      :build(),

   Interaction = builder()
      :name("FRAGMENTS.Interaction")
      :default(nil)
      :duplicate(deepClone)
      :build(),
}
