local vudu = require("lib.vudu")

Class = require("lib.middleclass")
Colors = require("src.data.colors")
Vector = require("lib.brinevector")

local ecs, pool

function love.load()
   vudu.initialize()
   ecs = require("src.ecs")
   pool = ecs.pool
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
