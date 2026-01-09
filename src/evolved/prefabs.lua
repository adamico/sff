local evolved_config = require("src.evolved.evolved_config")
local Colors = require("src.config.colors")
local evolved = require("lib.evolved")
local builder = evolved.builder
local FRAGMENTS = evolved_config.FRAGMENTS
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

evolved_config.PREFABS = {
   Player = builder()
      :name("PREFABS.Player")
      :set(FRAGMENTS.PositionX, SCREEN_WIDTH / 2)
      :set(FRAGMENTS.PositionY, SCREEN_HEIGHT / 2)
      :set(FRAGMENTS.VelocityX)
      :set(FRAGMENTS.VelocityY)
      :set(FRAGMENTS.Controllable, true)
      :set(FRAGMENTS.Size, 16)
      :set(FRAGMENTS.Visual, "circle")
      :set(FRAGMENTS.Color, Colors.WHITE)
      :set(FRAGMENTS.MaxSpeed, 300)
      :build()
}
