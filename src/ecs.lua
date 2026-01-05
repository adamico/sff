local nata = require("lib.nata")
local Player = require("src.entities.player")
local PLAYER_CONFIG = require("src.data.player_data")
local Storage = require("src.entities.storage")

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local ecs = {}
local pool

pool = nata.new({
   --[[
		define groups. each group contains the entities
		that have the specified components.
	]]
   groups = {
      interactable = {filter = {"position", "interactable"}},
      physics = {filter = {"position", "size", "velocity"}},
      controllable = {filter = {"controllable"}},
      render = {filter = {"position", "size", "visual"}},
   },
   --[[
		define the systems that should be used. systems receive
		events in the order they're listed.
	]]
   systems = {
      nata.oop(),
      require("src.systems.input_system")(pool),
      require("src.systems.interaction_system")(pool),
      require("src.systems.physics_system")(pool),
      require("src.systems.render_system")(pool),
   },
})

pool:on("addToGroup", function(group, entity)
   print("add", group, entity)
end)

pool:on("removeFromGroup", function(group, entity)
   print("remove", group, entity)
end)

local player = pool:queue(Player:new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, PLAYER_CONFIG))
local chest = pool:queue(Storage:new(100, 100, "creative_chest"))

local function shouldRemove(entity)
   return entity.dead
end

ecs.pool = pool
ecs.shouldRemove = shouldRemove

return ecs
