local builder = Evolved.builder
local set = Evolved.set

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.OnSetup)
   :prologue(function()
      set(ENTITIES.Player, FRAGMENTS.Position, Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
   end):build()
