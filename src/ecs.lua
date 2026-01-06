local nata = require("lib.nata")
local Player = require("src.entities.player")
local PLAYER_CONFIG = require("src.data.player_data")
local Storage = require("src.entities.storage")

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
      require("src.systems.render_system"),
   },
})

local player = pool:queue(Player:new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, PLAYER_CONFIG))
local chest = pool:queue(Storage:new(100, 100, "creative_chest"))

local function shouldRemove(entity)
   return entity.dead
end

ecs.pool = pool
ecs.shouldRemove = shouldRemove

return ecs
