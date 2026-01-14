local evolvedConfig = require("src.evolved.evolved_config")

-- ENTITIES table stores entity IDs that need global access (e.g., player)
-- Populated by setup_systems at runtime
evolvedConfig.ENTITIES = {}

-- PREFABS are no longer used - entities are created directly from data files
-- via SpawnerSystem
