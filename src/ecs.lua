local nata = require("lib.nata")
local Player = require("src.entities.player")
local Storage = require("src.entities.storage")
local StorageRegistry = require("src.registries.storage_registry")
local Assembler = require("src.entities.assembler")
local AssemblerRegistry = require("src.registries.assembler_registry")

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local ecs = {}
local pool

pool = nata.new({
   groups = {
      interactable = {filter = {"position", "interactable"}},
      physics = {filter = {"position", "size", "velocity"}},
      controllable = {filter = {"controllable"}},
      render = {filter = {"position", "size", "visual"}},
   },
   systems = {
      nata.oop(),
      require("src.systems.input_system"),
      require("src.systems.interaction_system"),
      require("src.systems.physics_system"),
      require("src.systems.render_entities_system"),
   },
})

local player = pool:queue(Player:new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
local creative_chest = pool:queue(Storage:new(100, 100, StorageRegistry.CREATIVE_CHEST))
local skeleton_assembler = pool:queue(Assembler:new(600, 100, AssemblerRegistry.SKELETON_ASSEMBLER))

local function shouldRemove(entity)
   return entity.dead
end

ecs.pool = pool
ecs.shouldRemove = shouldRemove

return ecs
