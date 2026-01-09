local nata = require("lib.nata")
local Player = require("src.entities.player")
local Storage = require("src.entities.storage")
local Assembler = require("src.entities.assembler")
local DeployableRegistry = require("src.registries.deployable_registry")

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local ecs = {}
local pool

--- Filter function for processing group
--- Machines need fsm and inventory, but currentRecipe can be nil initially
local function isProcessingMachine(entity)
   return entity.fsm ~= nil and entity.inventory ~= nil and entity.processingTimer ~= nil
end

pool = nata.new({
   groups = {
      interactable = {filter = {"position", "interactable"}},
      mana = {filter = {"mana"}},
      physics = {filter = {"position", "size", "velocity"}},
      controllable = {filter = {"controllable"}},
      render = {filter = {"position", "size", "visual"}},
      processing = {filter = isProcessingMachine},
   },
   systems = {
      nata.oop(),
      require("src.systems.input_system"),
      require("src.systems.interaction_system"),
      require("src.systems.physics_system"),
      require("src.systems.mana_system"),
      require("src.systems.processing_system"),
      require("src.systems.render_entities_system"),
      require("src.systems.ui_system"),
   },
})

local creative_chest = pool:queue(Storage:new(100, 100, DeployableRegistry.CREATIVE_CHEST))
local skeleton_assembler = pool:queue(Assembler:new(600, 100, DeployableRegistry.SKELETON_ASSEMBLER))
local player = pool:queue(Player:new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))

local function shouldRemove(entity)
   return entity.dead
end

ecs.pool = pool
ecs.player = player
ecs.assembler = skeleton_assembler
ecs.creative_chest = creative_chest

ecs.shouldRemove = shouldRemove

return ecs
