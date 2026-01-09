local InventoryComponent = require "src.components.inventory_component"
local evolved_config = require("src.evolved.evolved_config")
local builder = Evolved.builder

local PLAYER_DATA = require "src.data.player_data"

evolved_config.ENTITIES = {
   Player = builder()
      :name("ENTITIES.Player")
      :set(FRAGMENTS.Color, Colors.WHITE)
      :set(FRAGMENTS.MaxSpeed, 300)
      :set(FRAGMENTS.Inventory, InventoryComponent:new(PLAYER_DATA.inventory))
      :set(FRAGMENTS.Toolbar, InventoryComponent:new(PLAYER_DATA.toolbar))
      :set(TAGS.Controllable)
      :set(TAGS.Physical)
      :set(TAGS.Player)
      :set(TAGS.Visual)
      :build()
}
