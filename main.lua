Vector = require("lib.brinevector")
Colors = require("src.config.colors")
Log = require("lib.log")
Evolved = require("lib.evolved")
local process = Evolved.process
local evolved_config = require("src.evolved.evolved_config")

require("src.evolved.fragments")
FRAGMENTS = evolved_config.FRAGMENTS
TAGS = evolved_config.TAGS
require("src.evolved.entities")

STAGES = evolved_config.STAGES
require("src.evolved.systems")

ENTITIES = evolved_config.ENTITIES
UNIFORMS = evolved_config.UNIFORMS

function love.load()
   process(STAGES.OnSetup)
end

function love.update(dt)
   UNIFORMS.DELTA_TIME = dt
   process(STAGES.OnUpdate)
end

function love.draw()
   process(STAGES.OnRender)
end

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
end
