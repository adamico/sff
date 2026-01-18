local SpawnerSystem = require("src.evolved.systems.spawner_system")

local builder = Evolved.builder

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.OnSetup)
   :prologue(function()
      -- Spawn player and store ID for global access
      local px, py = shove.getViewportWidth() / 2, shove.getViewportHeight() / 2
      ENTITIES.Player = SpawnerSystem.spawnEntity("player", Vector(px, py))
   end):build()
