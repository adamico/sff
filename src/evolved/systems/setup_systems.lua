local SpawnerSystem = require("src.evolved.systems.spawner_system")

local builder = Evolved.builder

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.OnSetup)
   :prologue(function()
      -- Spawn player at center of the map (world coordinates)
      local px = (Map.width * Map.tilewidth) / 2
      local py = (Map.height * Map.tileheight) / 2
      ENTITIES.Player = SpawnerSystem.spawnEntity("player", Vector(px, py))
   end):build()
