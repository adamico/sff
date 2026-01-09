local builder = Evolved.builder
local set = Evolved.set
local lg = love.graphics

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

builder()
   :name("SYSTEMS.Startup")
   :group(STAGES.ON_SETUP)
   :prologue(function()
      set(ENTITIES.Player,
         FRAGMENTS.Position,
         Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2))
   end):build()

builder()
   :name("SYSTEMS.PlayerInput")
   :group(STAGES.ON_UPDATE)
   :include()

builder()
   :name("SYSTEMS.Movement")
   :group(STAGES.ON_UPDATE)
   :include(TAGS.Physical)
   :execute(function(chunk, _, entityCount)
      local deltaTime = UNIFORMS.DeltaTime

      --- @type table[], table[]
      local positions, velocities = chunk:components(FRAGMENTS.Position, FRAGMENTS.Velocity)

      --- @type number[]
      local maxSpeeds = chunk:components(FRAGMENTS.MaxSpeed)

      for i = 1, entityCount do
         local px, py = positions[i]:split()
         local vx, vy = velocities[i]:split()
         local maxSpeed = maxSpeeds[i]

         px = px + vx * maxSpeed * deltaTime
         py = py + vy * maxSpeed * deltaTime

         positions[i].set(px, py)
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
