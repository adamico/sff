local evolved_config = require("src.evolved.evolved_config")

evolved_config.SYSTEMS = {
   SetupSystems = require("src.evolved.systems.setup_systems"),
   UpdateSystems = require("src.evolved.systems.update_systems"),
   RenderSystems = require("src.evolved.systems.render_systems")
}
