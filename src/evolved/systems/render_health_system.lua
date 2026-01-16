local lg = love.graphics
local builder = Evolved.builder

builder()
   :name("SYSTEMS.RenderHealth")
   :group(STAGES.OnRender)
   :include(TAGS.Damageable)
   :execute(function(chunk, entityIds, entityCount)
      local positions, healths = chunk:components(FRAGMENTS.Position, FRAGMENTS.Health)

      for i = 1, entityCount do
         local health = healths[i]
         local currentHealth = health.current
         local maxHealth = health.max
         local healthBarWidth = 50
         local healthBarHeight = 10
         local healthBarX = positions[i].x - healthBarWidth / 2
         local healthBarY = positions[i].y - healthBarHeight - 5

         lg.setColor(1, 0, 0)
         lg.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight)

         lg.setColor(0, 1, 0)
         lg.rectangle("fill", healthBarX, healthBarY, healthBarWidth * currentHealth / maxHealth, healthBarHeight)

         local borderGap = 1
         lg.setColor(1, 1, 1)
         lg.rectangle("line", healthBarX - borderGap, healthBarY - borderGap, healthBarWidth + borderGap * 2,
            healthBarHeight + borderGap * 2)
      end
   end):build()
