--[[
   Camera Helper

   Provides camera offset calculation and coordinate conversion utilities.
   The camera follows the player and is clamped to the map bounds.
]]

local CameraHelper = {}

--- Calculate the current camera offset (top-left corner of viewport in world coords)
--- @return number tx X offset
--- @return number ty Y offset
function CameraHelper.getOffset()
   local playerPos, playerHitbox = Evolved.get(ENTITIES.Player, FRAGMENTS.Position, FRAGMENTS.Hitbox)
   if not playerPos then return 0, 0 end

   local playerHitboxRadius = playerHitbox.radius
   local viewportW, viewportH = shove.getViewportWidth(), shove.getViewportHeight()

   -- Calculate camera position (centered on player)
   local tx = math.floor(playerPos.x - viewportW / 2)
   local ty = math.floor(playerPos.y - viewportH / 2 - playerHitboxRadius)

   -- Clamp camera to map bounds
   local mapPixelW = Map.width * Map.tilewidth
   local mapPixelH = Map.height * Map.tileheight
   tx = math.max(0, math.min(tx, mapPixelW - viewportW))
   ty = math.max(0, math.min(ty, mapPixelH - viewportH))

   return tx, ty
end

--- Convert screen (viewport) coordinates to world coordinates
--- @param screenX number X position in viewport
--- @param screenY number Y position in viewport
--- @return number worldX World X coordinate
--- @return number worldY World Y coordinate
function CameraHelper.screenToWorld(screenX, screenY)
   local tx, ty = CameraHelper.getOffset()
   return screenX + tx, screenY + ty
end

--- Convert world coordinates to screen (viewport) coordinates
--- @param worldX number World X coordinate
--- @param worldY number World Y coordinate
--- @return number screenX X position in viewport
--- @return number screenY Y position in viewport
function CameraHelper.worldToScreen(worldX, worldY)
   local tx, ty = CameraHelper.getOffset()
   return worldX - tx, worldY - ty
end

return CameraHelper
