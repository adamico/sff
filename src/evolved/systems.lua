-- Systems are registered at module load time via builder():build()
-- This file just ensures all system modules are loaded

require("src.evolved.systems.setup_systems")
require("src.evolved.systems.interaction_system")
require("src.evolved.systems.input_system")
require("src.evolved.systems.mana_system")
require("src.evolved.systems.physics_system")
require("src.evolved.systems.processing_system")
require("src.evolved.systems.spawner_system")
require("src.evolved.systems.render_hitboxes_system")
require("src.evolved.systems.render_debug_system")
require("src.evolved.systems.render_ui_system")
