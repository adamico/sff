local builder = Evolved.builder
local lg = love.graphics

builder()
   :name("SYSTEMS.RenderDebug")
   :group(STAGES.OnRender)
   :epilogue(function()
      local fps = love.timer.getFPS()
      local mem = collectgarbage("count")
      lg.print(string.format("FPS: %d", fps), 10, 10)
      lg.print(string.format("Memory: %d KB", mem), 10, 30)
   end):build()
