Beholder = require("lib.beholder")
Class = require("lib.middleclass")
Colors = require("src.config.colors")
Events = require("src.config.events")
Evolved = require("lib.evolved")
Flexlove = require("lib.flexlove.FlexLove")
Color = Flexlove.Color

Log = require("lib.log")
Vector = require("lib.brinevector")
require("src.helpers.text_helper")

-- Enable debug mode for development (catches incorrect API usage)
Evolved.debug_mode(true)

local process = Evolved.process
local evolved_config = require("src.evolved.evolved_config")

require("src.evolved.fragments")
FRAGMENTS = evolved_config.FRAGMENTS
TAGS = evolved_config.TAGS
require("src.evolved.entities")
ENTITIES = evolved_config.ENTITIES
PREFABS = evolved_config.PREFABS

UNIFORMS = evolved_config.UNIFORMS
STAGES = evolved_config.STAGES
require("src.evolved.systems")

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

function love.load()
   Flexlove.init({
      baseScale = {width = SCREEN_WIDTH, height = SCREEN_HEIGHT},
      immediateMode = false,
      theme = "metal"
   })
   process(STAGES.OnSetup)
end

function love.update(dt)
   UNIFORMS.setDeltaTime(dt)
   Flexlove.update(dt)
   process(STAGES.OnUpdate)
end

local function drawDebugLines()
   love.graphics.setColor(1, 0, 0)
   love.graphics.line(SCREEN_WIDTH / 2, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT)
   love.graphics.line(0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, SCREEN_HEIGHT / 2)
end

function love.draw()
   Flexlove.draw(function()
      -- Your game rendering here (entities, world, etc.)
      -- drawDebugLines()
      process(STAGES.OnRender)
   end)
end

function love.resize(w, h)
   Flexlove.resize()
end

function love.textinput(text)
   Flexlove.textinput(text)
end

function love.keypressed(key)
   Flexlove.keypressed(key, scancode, isrepeat)
   if key == "escape" then
      love.event.quit()
   end
end

function love.wheelmoved(dx, dy)
   Flexlove.wheelmoved(dx, dy)
end
