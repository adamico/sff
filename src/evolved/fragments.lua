local evolved_config = require("src.evolved.evolved_config")
local Colors = require("src.config.colors")
local evolved = require("lib.evolved")
local builder = evolved.builder

evolved_config.FRAGMENTS = {
   PositionX = builder()
      :name("FRAGMENTS.PositionX")
      :default(0)
      :build(),
   PositionY = builder()
      :name("FRAGMENTS.PositionY")
      :default(0)
      :build(),
   VelocityX = builder()
      :name("FRAGMENTS.VelocityX")
      :default(0)
      :build(),
   VelocityY = builder()
      :name("FRAGMENTS.VelocityY")
      :default(0)
      :build(),
   Controllable = builder()
      :name("FRAGMENTS.Controllable")
      :default(false)
      :build(),
   Color = builder()
      :name("FRAGMENTS.Color")
      :default(Colors.WHITE)
      :build(),
   MaxSpeed = builder()
      :name("FRAGMENTS.MaxSpeed")
      :default(300)
      :build(),
   Size = builder()
      :name("FRAGMENTS.Size")
      :default(16)
      :build(),
   Visual = builder()
      :name("FRAGMENTS.Visual")
      :default("circle")
      :build()
}
