local nata = require("lib.nata")
local Player = require("src.entities.player")

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local ecs = {}
local pool

pool = nata.new({
   --[[
		define groups. each group contains the entities
		that have the specified components.
	]]
   groups = {
      physics = {filter = {"position", "velocity", "r"}},
      render = {filter = {"position", "r", "color"}},
   },
   --[[
		define the systems that should be used. systems receive
		events in the order they're listed.
	]]
   systems = {
      nata.oop(),
      require("src.systems.physics_system")(pool),
      require("src.systems.render_system")(pool),
   },
})

pool:on("addToGroup", function(group, entity)
   if entity.isPlayer then
      print("add", group, entity)
   end
end)

pool:on("removeFromGroup", function(group, entity)
   if entity.isPlayer then
      print("remove", group, entity)
   end
end)

local player = pool:queue(Player(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))

local function shouldRemove(entity)
   return entity.dead
end

ecs.pool = pool
ecs.player = player
ecs.shouldRemove = shouldRemove

return ecs
