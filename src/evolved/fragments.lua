local Inventory = require("src.evolved.fragments.inventory")
local StateMachine = require("src.evolved.fragments.state_machine")
local Recipe = require("src.evolved.fragments.recipe")
local evolved_config = require("src.evolved.evolved_config")
local builder = Evolved.builder

local function duplicateVector(vector)
   return Vector(vector.x, vector.y)
end

local function clone(original)
   return {table.unpack(original)}
end

local function deepClone(original)
   local originalType = type(original)
   local copy
   if originalType == "table" then
      copy = {}
      for originalKey, originalValue in next, original, nil do
         copy[deepClone(originalKey)] = deepClone(originalValue)
      end
      setmetatable(copy, deepClone(getmetatable(original)))
   else -- number, string, boolean, etc
      copy = original
   end
   return copy
end

evolved_config.FRAGMENTS = {
   Color = builder()
      :name("FRAGMENTS.Color")
      :default(Colors.WHITE)
      :build(),
   CurrentRecipe = builder()
      :name("FRAGMENTS.CurrentRecipe")
      :default(Recipe.new("empty"))
      :duplicate(deepClone)
      :build(),
   InteractionRange = builder()
      :name("FRAGMENTS.InteractionRange")
      :default(128)
      :build(),
   Input = builder()
      :name("FRAGMENTS.Input")
      :default(Vector(0, 0))
      :duplicate(duplicateVector)
      :build(),
   Inventory = builder()
      :name("FRAGMENTS.Inventory")
      :default(nil)
      :duplicate(deepClone)
      :build(),
   MaxSpeed = builder()
      :name("FRAGMENTS.MaxSpeed")
      :default(300)
      :build(),
   Position = builder()
      :name("FRAGMENTS.Position")
      :default(Vector(0, 0))
      :duplicate(duplicateVector)
      :build(),
   Shape = builder()
      :name("FRAGMENTS.Shape")
      :default("circle")
      :build(),
   Size = builder()
      :name("FRAGMENTS.Size")
      :default(Vector(16, 16))
      :duplicate(duplicateVector)
      :build(),
   StateMachine = builder()
      :name("FRAGMENTS.State")
      :default(StateMachine.new())
      :duplicate(StateMachine.duplicate)
      :build(),
   Toolbar = builder()
      :name("FRAGMENTS.Toolbar")
      :default(nil)
      :duplicate(deepClone)
      :build(),
   ValidRecipes = builder()
      :name("FRAGMENTS.ValidRecipes")
      :default({})
      :duplicate(deepClone)
      :build(),
   Velocity = builder()
      :name("FRAGMENTS.Velocity")
      :default(Vector(0, 0))
      :duplicate(duplicateVector)
      :build(),
}

local FRAGMENTS = evolved_config.FRAGMENTS

evolved_config.TAGS = {
   Controllable = builder()
      :name("TAGS.Controllable")
      :tag()
      :require(FRAGMENTS.Input)
      :build(),
   Interactable = builder()
      :name("TAGS.Interactable")
      :tag()
      :build(),
   Inventory = builder()
      :name("FRAGMENTS.Inventory")
      :default(nil)
      :duplicate(Inventory.duplicate)
      :build(),
   Player = builder()
      :name("TAGS.Player")
      :tag()
      :build(),
   Physical = builder()
      :name("TAGS.Physical")
      :tag()
      :require(
         FRAGMENTS.Position,
         FRAGMENTS.Velocity,
         FRAGMENTS.Size
      )
      :build(),
   Visual = builder()
      :name("TAGS.Visual")
      :tag()
      :require(FRAGMENTS.Color, FRAGMENTS.Shape)
      :build(),
   Processing = builder()
      :name("TAGS.Processing")
      :require(
         FRAGMENTS.CurrentRecipe,
         FRAGMENTS.StateMachine,
         FRAGMENTS.ValidRecipes
      )
      :tag()
      :build(),
}
