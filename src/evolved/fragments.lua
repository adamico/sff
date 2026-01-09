local evolved_config = require("src.evolved.evolved_config")
local builder = Evolved.builder
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local function vector_duplicate(vector)
   return Vector(vector.x, vector.y)
end

evolved_config.FRAGMENTS = {
   Color = builder()
      :name("FRAGMENTS.Color")
      :default(Colors.WHITE)
      :build(),
   Input = builder()
      :name("FRAGMENTS.Input")
      :default(Vector(0, 0))
      :duplicate(vector_duplicate)
      :build(),
   Inventory = builder()
      :name("FRAGMENTS.Inventory")
      :default(nil)
      :build(),
   MaxSpeed = builder()
      :name("FRAGMENTS.MaxSpeed")
      :default(300)
      :build(),
   Position = builder()
      :name("FRAGMENTS.Position")
      :default(Vector(0, 0))
      :duplicate(vector_duplicate)
      :build(),
   Shape = builder()
      :name("FRAGMENTS.Shape")
      :default("circle")
      :build(),
   Size = builder()
      :name("FRAGMENTS.Size")
      :default(Vector(16, 16))
      :duplicate(vector_duplicate)
      :build(),
   Toolbar = builder()
      :name("FRAGMENTS.Toolbar")
      :default(nil)
      :build(),
   Velocity = builder()
      :name("FRAGMENTS.Velocity")
      :default(Vector(0, 0))
      :duplicate(vector_duplicate)
      :build(),
}

local FRAGMENTS = evolved_config.FRAGMENTS

evolved_config.TAGS = {
   Controllable = builder()
      :name("TAGS.Controllable")
      :tag()
      :require(FRAGMENTS.Input)
      :build(),
   Player = builder()
      :name("TAGS.Player")
      :tag()
      :build(),
   Physical = builder()
      :name("TAGS.Physical")
      :tag()
      :require(FRAGMENTS.Position, FRAGMENTS.Velocity, FRAGMENTS.Size)
      :build(),
   Visual = builder()
      :name("TAGS.Visual")
      :tag()
      :require(FRAGMENTS.Shape, FRAGMENTS.Color)
      :build()
}
