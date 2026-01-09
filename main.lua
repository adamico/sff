Class = require("lib.middleclass")
Colors = require("src.config.colors")
Evolved = require("lib.evolved")
Log = require("lib.log")
Vector = require("lib.brinevector")
local process = Evolved.process
local evolved_config = require("src.evolved.evolved_config")

require("src.evolved.fragments")
FRAGMENTS = evolved_config.FRAGMENTS
TAGS = evolved_config.TAGS
require("src.evolved.entities")
ENTITIES = evolved_config.ENTITIES

UNIFORMS = evolved_config.UNIFORMS
STAGES = evolved_config.STAGES
require("src.evolved.systems")

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
