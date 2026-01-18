local EntityDrawHelper = require("src.helpers.entity_draw_helper")
local CollisionHelper = require("src.helpers.collision_helper")

local builder = Evolved.builder
local HITBOX_COLOR = {1, 0, 0, 0.5}

builder()
   :name("SYSTEMS.RenderHitboxes")
   :group(STAGES.OnRender)
   :include(TAGS.Physical)
   :execute(function(chunk, entityIds, entityCount)
      -- Skip hitbox rendering if disabled
      if not UNIFORMS.getShowHitboxes() then return end

      local positions, hitboxes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Hitbox)
      local names = chunk:components(Evolved.NAME)

      for i = 1, entityCount do
         local id = entityIds[i]
         local name = names[i] or "Entity"
         local label = string.format("%s%d", name, id)

         -- Get world-space hitbox bounds
         local bounds = CollisionHelper.getHitboxBounds(positions[i], hitboxes[i])

         EntityDrawHelper.drawHitbox(bounds, HITBOX_COLOR)
      end
   end):build()
