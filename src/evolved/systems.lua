local evolved_config = require("src.evolved.evolved_config")

evolved_config.SYSTEMS = {
   SetupSystems = require("src.evolved.systems.setup_systems"),
   InputSystem = require("src.evolved.systems.input_system"),
   PhysicsSystem = require("src.evolved.systems.physics_system"),
   RenderEntitiesSystems = require("src.evolved.systems.render_entities_systems"),
   RenderDebugSystem = require("src.evolved.systems.render_debug_system"),
   RenderUISystem = require("src.evolved.systems.render_ui_system"),
}
