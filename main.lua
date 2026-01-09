local evolved_config = require("src.evolved.evolved_config")
require("src.evolved.fragments")
require("src.evolved.prefabs")
require("src.evolved.systems")
local UNIFORMS = evolved_config.UNIFORMS

local evolved = require("lib.evolved")
local process = evolved.process

function love.load()
   process(evolved_config.STAGES.OnSetup)
end

function love.update(dt)
   UNIFORMS.DELTA_TIME = dt
   process(evolved_config.STAGES.OnUpdate)
end

function love.draw()
   process(evolved_config.STAGES.OnRender)
end

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
end
