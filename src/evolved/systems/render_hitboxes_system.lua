local lg = love.graphics
local builder = Evolved.builder
local EntityDrawHelper = require("src.helpers.entity_draw_helper")
local CollisionHelper = require("src.helpers.collision_helper")

builder()
   :name("SYSTEMS.RenderHitboxes")
   :group(STAGES.OnRender)
   :include(TAGS.Physical)
   :prologue(function()
      -- Skip hitbox rendering if disabled
      if not UNIFORMS.getShowHitboxes() then
         return true -- return true to skip system execution
      end
   end)
   :execute(function(chunk, entityIds, entityCount)
      local positions, hitboxes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Hitbox)
      local colors = chunk:components(FRAGMENTS.Color)
      local names = chunk:components(Evolved.NAME)

      for i = 1, entityCount do
         local id = entityIds[i]
         local name = names[i] or "Entity"
         local label = string.format("%s%d", name, id)

         -- Get world-space hitbox bounds
         local bounds = CollisionHelper.getHitboxBounds(positions[i], hitboxes[i])

         -- Use color if available, otherwise default to white
         local color = colors[i] or Colors.WHITE

         EntityDrawHelper.drawHitbox(bounds, color, label)
      end
   end):build()
