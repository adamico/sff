local Inventory = require("src.evolved.fragments.inventory")
local StateMachine = require("src.evolved.fragments.state_machine")
local builder = Evolved.builder
local set = Evolved.set
local clone = Evolved.clone

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local DEPLOYABLE_ENTITIES_DATA = require("src.data.entities.deployable_entities_data")
local skeletonAssemblerData = DEPLOYABLE_ENTITIES_DATA.SkeletonAssembler
local creativeChestData = DEPLOYABLE_ENTITIES_DATA.CreativeChest

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.OnSetup)
   :prologue(function()
      set(ENTITIES.Player, FRAGMENTS.Position, Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
      clone(PREFABS.Assembler, {
         [Evolved.NAME] = "Skeleton Assembler",
         [FRAGMENTS.Inventory] = Inventory.new(skeletonAssemblerData.inventory),
         [FRAGMENTS.Mana] = {
            current = skeletonAssemblerData.mana.current,
            max = skeletonAssemblerData.mana.max,
            regen_rate = skeletonAssemblerData.mana.regen_rate or 1,
         },
         [FRAGMENTS.Position] = Vector(600, 100),
         [FRAGMENTS.ProcessingTimer] = {current = 0, saved = 0},
         [FRAGMENTS.Shape] = "rectangle",
         [FRAGMENTS.Size] = Vector(64, 64),
         [FRAGMENTS.StateMachine] = StateMachine.new({events = skeletonAssemblerData.events}),
         [FRAGMENTS.ValidRecipes] = skeletonAssemblerData.valid_recipes,
      })
      clone(PREFABS.Storage, {
         [Evolved.NAME] = "CreativeChest",
         [FRAGMENTS.Inventory] = Inventory.new(creativeChestData.inventory),
         [FRAGMENTS.Position] = Vector(100, 100),
         [FRAGMENTS.Shape] = "rectangle",
         [FRAGMENTS.Size] = Vector(32, 32),
      })
   end):build()
