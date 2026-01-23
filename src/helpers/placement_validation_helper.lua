local EntityQuery = require("src.data.queries.entity_query")
local CollisionHelper = require("src.helpers.collision_helper")
local builder = Evolved.builder
local execute = Evolved.execute

local PlacementValidationHelper = {}

-- Query for all physical entities (same as collision system)
local physicalQuery = builder()
   :name("QUERIES.PlacementPhysical")
   :include(TAGS.Physical)
   :build()

--- Build ghost hitbox bounds at the given position for an item
--- @param item table The item being placed
--- @param position table The world position
--- @return table|nil bounds World-space hitbox bounds or nil
function PlacementValidationHelper.getGhostBounds(item, position)
   if not item or not item.spawnsEntity then return nil end
   if not position then return nil end

   local entityData = EntityQuery.findById(item.spawnsEntity)
   if not entityData then return nil end

   local hitbox = entityData.hitbox or {shape = "circle", offsetX = 0, offsetY = 0, radius = 16}

   if hitbox.shape == "circle" then
      return {
         shape = "circle",
         x = position.x + hitbox.offsetX,
         y = position.y + hitbox.offsetY,
         radius = hitbox.radius,
      }
   else
      return {
         shape = "rectangle",
         x = position.x + hitbox.offsetX,
         y = position.y + hitbox.offsetY,
         width = hitbox.width,
         height = hitbox.height,
      }
   end
end

--- Check if ghost bounds collide with any existing entity
--- @param ghostBounds table World-space hitbox bounds
--- @return boolean true if collision found (invalid placement)
local function checkCollisionWithExisting(ghostBounds)
   for chunk, entityIds, entityCount in execute(physicalQuery) do
      local positions, hitboxes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Hitbox)

      for i = 1, entityCount do
         local entityBounds = CollisionHelper.getHitboxBounds(positions[i], hitboxes[i])

         if CollisionHelper.areColliding(ghostBounds, entityBounds) then
            return true -- Collision found
         end
      end
   end

   return false -- No collision
end

--- Validate if placement is possible at position
--- @param item table The item to place
--- @param position table World position
--- @return boolean isValid
function PlacementValidationHelper.validatePlacement(item, position)
   local ghostBounds = PlacementValidationHelper.getGhostBounds(item, position)
   if not ghostBounds then return false end

   return not checkCollisionWithExisting(ghostBounds)
end

return PlacementValidationHelper
