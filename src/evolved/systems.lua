local InputHelper = require("src.helpers.input_helper")
local A = require("src.config.input_bindings").actions

local builder = Evolved.builder
local set = Evolved.set
local lg = love.graphics

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.OnSetup)
   :prologue(function()
      set(ENTITIES.Player, FRAGMENTS.Position, Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
   end):build()

builder()
   :name("SYSTEMS.PlayerInput")
   :group(STAGES.OnUpdate)
   :include(FRAGMENTS.Input)
   :execute(function(chunk, _, entityCount)
      local vector = Vector()
      if InputHelper.isActionPressed(A.MOVE_UP) then
         vector.y = -1
      elseif InputHelper.isActionPressed(A.MOVE_DOWN) then
         vector.y = 1
      end
      if InputHelper.isActionPressed(A.MOVE_LEFT) then
         vector.x = -1
      elseif InputHelper.isActionPressed(A.MOVE_RIGHT) then
         vector.x = 1
      end

      local inputVectors = chunk:components(FRAGMENTS.Input)

      for i = 1, entityCount do
         local inputVector = inputVectors[i]
         inputVector = Vector(vector.x, vector.y).normalized
         inputVectors[i] = inputVector
      end
   end):build()

builder()
   :name("SYSTEMS.Movement")
   :group(STAGES.OnUpdate)
   :include(TAGS.Physical, TAGS.Controllable)
   :execute(function(chunk, _, entityCount)
      local deltaTime = UNIFORMS.DeltaTime
      local positions, velocities = chunk:components(FRAGMENTS.Position, FRAGMENTS.Velocity)
      local maxSpeeds = chunk:components(FRAGMENTS.MaxSpeed)
      local inputVectors = chunk:components(FRAGMENTS.Input)

      for i = 1, entityCount do
         local position = positions[i]
         local velocity = velocities[i]
         local inputVector = inputVectors[i]
         local maxSpeed = maxSpeeds[i]
         velocity = inputVector * maxSpeed
         position = position + velocity * deltaTime
         positions[i] = position
      end
   end):build()

builder()
   :name("SYSTEMS.Rendering")
   :group(STAGES.OnRender)
   :include(TAGS.Visual, TAGS.Physical)
   :execute(function(chunk, _, entityCount)
      local positions, sizes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Size)
      local visuals = chunk:components(FRAGMENTS.Shape)
      local colors = chunk:components(FRAGMENTS.Color)

      for i = 1, entityCount do
         local px, py = positions[i]:split()
         local size = sizes[i]
         local visual = visuals[i]
         local color = colors[i]

         lg.setColor(color)
         if visual == "circle" then
            lg.circle("fill", px, py, size.x)
         elseif visual == "rectangle" then
            lg.rectangle("fill", px, py, size.x, size.y)
         end
      end
   end):build()

require("src.evolved.systems.ui_system")

builder()
   :name("SYSTEMS.Debugging")
   :group(STAGES.OnRender)
   :epilogue(function()
      local fps = love.timer.getFPS()
      local mem = collectgarbage("count")
      lg.print(string.format("FPS: %d", fps), 10, 10)
      lg.print(string.format("Memory: %d KB", mem), 10, 30)
   end):build()
