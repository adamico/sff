local Inventory = require "src.components.inventory"
local evolved_config = require("src.evolved.evolved_config")
local builder = Evolved.builder

local PLAYER_DATA = require "src.data.player_data"

evolved_config.ENTITIES = {
   Player = builder()
      :name("ENTITIES.Player")
      :set(FRAGMENTS.Color, Colors.BLUE)
      :set(FRAGMENTS.MaxSpeed, 300)
      :set(FRAGMENTS.Inventory, Inventory.new(PLAYER_DATA.inventory))
      :set(FRAGMENTS.Toolbar, Inventory.new(PLAYER_DATA.toolbar))
      :set(FRAGMENTS.InteractionRange, 128)
      :set(TAGS.Controllable)
      :set(TAGS.Physical)
      :set(TAGS.Player)
      :set(TAGS.Visual)
      :build(),
}

evolved_config.PREFABS = {
   Assembler = builder()
      :name("PREFABS.Assembler")
      :prefab()
      :set(FRAGMENTS.Color, Colors.PURPLE)
      :set(FRAGMENTS.Inventory, Inventory.new())
      :set(TAGS.Interactable)
      :set(TAGS.Physical)
      :set(TAGS.Visual)
      :set(TAGS.Processing)
      :build(),
   Storage = builder()
      :name("PREFABS.Storage")
      :prefab()
      :set(FRAGMENTS.Color, Colors.WHITE)
      :set(FRAGMENTS.Inventory, Inventory.new())
      :set(TAGS.Interactable)
      :set(TAGS.Physical)
      :set(TAGS.Visual)
      :build(),
}
