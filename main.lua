Class = require("lib.middleclass")
Colors = require("src.data.colors")
Vector = require("lib.brinevector")
Log = require("lib.log")

local ecs, pool

function love.load()
   ecs = require("src.ecs")
   pool = ecs.pool

   pool:on("player:interacted", function(entity)
      -- Handle player interaction with entity
      Log.trace("Player interacted")
   end)

   pool:on("inventory:opened", function()
      -- Handle inventory opened event
      Log.trace("Inventory opened")
   end)
end

function love.update(dt)
   pool:flush()
   pool:emit("update", dt)
   pool:emit("remove", ecs.shouldRemove)
end

function love.draw()
   pool:emit("draw")
end

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
end
