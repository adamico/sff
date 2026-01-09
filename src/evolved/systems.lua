local evolved_config = require("src.evolved.evolved_config")
local evolved = require("lib.evolved")
local builder = evolved.builder
local set = evolved.set
local PREFABS = evolved_config.PREFABS
local FRAGMENTS = evolved_config.FRAGMENTS
local STAGES = evolved_config.STAGES
local UNIFORMS = evolved_config.UNIFORMS

local lg = love.graphics

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.ON_SETUP)
   :prologue(function()
   end):build()

builder()
   :name("SYSTEMS.Movement")
   :group(STAGES.ON_UPDATE)
   :include(FRAGMENTS.PositionX, FRAGMENTS.PositionY)
   :include(FRAGMENTS.VelocityX, FRAGMENTS.VelocityY)
   :execute(function(chunk, _, entityCount)
      local deltaTime = UNIFORMS.DeltaTime

      --- @type number[], number[]
      local positionXs, positionYs = chunk:components(FRAGMENTS.PositionX, FRAGMENTS.PositionY)

      --- @type number[], number[]
      local velocityXs, velocityYs = chunk:components(FRAGMENTS.VelocityX, FRAGMENTS.VelocityY)

      --- @type number[]
      local maxSpeeds = chunk:components(FRAGMENTS.MaxSpeed)

      for i = 1, entityCount do
         local px, py = positionXs[i], positionYs[i]
         local vx, vy = velocityXs[i], velocityYs[i]
         local maxSpeed = maxSpeeds[i]

         px = px + vx * maxSpeed * deltaTime
         py = py + vy * maxSpeed * deltaTime

         positionXs[i] = px
         positionYs[i] = py
      end
   end):build()

builder()
   :name("SYSTEMS.Rendering")
   :group(STAGES.OnRender)
   :include(FRAGMENTS.PositionX, FRAGMENTS.PositionY, FRAGMENTS.Size)
   :include(FRAGMENTS.Visual, FRAGMENTS.Color)
   :execute(function(chunk, _, entityCount)
      --- @type number[], number[]
      local positionXs, positionYs = chunk:components(FRAGMENTS.PositionX, FRAGMENTS.PositionY)

      --- @type number[], string[]
      local sizes, visuals = chunk:components(FRAGMENTS.Size, FRAGMENTS.Visual)

      --- @type table[]
      local colors = chunk:components(FRAGMENTS.Color)

      for i = 1, entityCount do
         local px, py = positionXs[i], positionYs[i]
         local size = sizes[i]
         local visual = visuals[i]
         local color = colors[i]

         lg.setColor(color)
         if visual == "circle" then
            lg.circle("fill", px, py, size)
         elseif visual == "rectangle" then
            lg.rectangle("fill", px, py2, size.x, size.y)
         end
      end
   end):build()

builder()
   :name("SYSTEMS.Debugging")
   :group(STAGES.OnRender)
   :epilogue(function()
      local fps = love.timer.getFPS()
      local mem = collectgarbage("count")
      lg.print(string.format("FPS: %d", fps), 10, 10)
      lg.print(string.format("Memory: %d KB", mem), 10, 30)
   end):build()
