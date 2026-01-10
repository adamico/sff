local InventoryComponent = require("src.components.inventory_component")
local builder = Evolved.builder
local set = Evolved.set
local clone = Evolved.clone

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local DEPLOYABLE_ENTITIES_DATA = require("src.data.entities.deployable_entities_data")

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.OnSetup)
   :prologue(function()
      set(ENTITIES.Player, FRAGMENTS.Position, Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
      clone(PREFABS.Assembler, {
         [Evolved.NAME] = "SkeletonAssembler",
         [FRAGMENTS.Inventory] = InventoryComponent:new(DEPLOYABLE_ENTITIES_DATA.SkeletonAssembler.inventory),
         [FRAGMENTS.Position] = Vector(600, 100),
         [FRAGMENTS.Shape] = "rectangle",
         [FRAGMENTS.Size] = Vector(64, 64)
      })
      clone(PREFABS.Storage, {
         [Evolved.NAME] = "CreativeChest",
         [FRAGMENTS.Inventory] = InventoryComponent:new(DEPLOYABLE_ENTITIES_DATA.CreativeChest.inventory),
         [FRAGMENTS.Position] = Vector(100, 100),
         [FRAGMENTS.Shape] = "rectangle",
         [FRAGMENTS.Size] = Vector(32, 32)
      })
   end):build()
