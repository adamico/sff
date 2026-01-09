local evolved_config = require("src.evolved.evolved_config")
local builder = Evolved.builder

evolved_config.ENTITIES = {
   Player = builder()
      :name("ENTITIES.Player")
      :set(FRAGMENTS.Color, Colors.WHITE)
      :set(FRAGMENTS.MaxSpeed, 300)
      :set(TAGS.Controllable)
      :set(TAGS.Physical)
      :set(TAGS.Player)
      :set(TAGS.Visual)
      :build()
}
