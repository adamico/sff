Class = require("lib.middleclass")
Colors = require("src.data.colors")
Vector = require("lib.brinevector")
Log = require("lib.log")
Events = require("src.config.events")
Entities = require("src.config.entities")
Bindings = require("src.config.input_bindings")

function love.load()
   ecs = require("src.ecs")
   pool = ecs.pool
end

local chest_opened = false
function love.update(dt)
   pool:flush()
   pool:emit("update", dt)
   pool:emit("remove", ecs.shouldRemove)
   pool:emit(Events.ENTITY_INTERACTED, ecs.creative_chest)
end

function love.draw()
   pool:emit("draw")
end

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
end
