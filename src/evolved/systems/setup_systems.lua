local SpawnerSystem = require("src.evolved.systems.spawner_system")

local builder = Evolved.builder

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.OnSetup)
   :prologue(function()
      -- Spawn player and store ID for global access
      ENTITIES.Player = SpawnerSystem.spawnEntity("player", Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))

      -- Spawn other entities
      SpawnerSystem.spawnEntity("skeletonAssembler", Vector(600, 100))
      SpawnerSystem.spawnEntity("creativeChest", Vector(100, 100))
   end):build()
