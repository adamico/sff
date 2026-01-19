--[[
   Sprite Fragment

   Simple static sprite rendering using Love2D quads.
   For non-animated entities that just need to display a portion of a texture.
]]

local Sprite = {}

--- Create a new Sprite component
--- @param data table|nil Configuration data
--- @return table Sprite component instance
function Sprite.new(data)
   data = data or {}
   return {
      texture = data.texture or nil, -- Love2D image
      offsetX = data.offsetX or 0,   -- Offset from entity position
      offsetY = data.offsetY or 0,   -- Offset from entity position
      x = data.x or 0,               -- Quad X position in texture
      y = data.y or 0,               -- Quad Y position in texture
      width = data.width or 16,      -- Quad width
      height = data.height or 16,    -- Quad height
      quad = nil,                    -- Created lazily when drawn
   }
end

--- Draw the sprite at the given position
--- @param sprite table Sprite component
--- @param posX number World X position
--- @param posY number World Y position
function Sprite.draw(sprite, posX, posY)
   if not sprite.texture then return end
   local texture = love.graphics.newImage("src/data/spritesheets/"..sprite.texture)
   -- Create quad lazily on first draw
   if not sprite.quad then
      sprite.quad = love.graphics.newQuad(
         sprite.x, sprite.y,
         sprite.width, sprite.height,
         texture
      )
   end

   love.graphics.draw(texture, sprite.quad, posX + sprite.offsetX, posY + sprite.offsetY)
end

--- Duplicate a Sprite component (for ECS cloning)
--- @param sprite table Sprite component to duplicate
--- @return table New Sprite component
function Sprite.duplicate(sprite)
   return {
      texture = sprite.texture,
      offsetX = sprite.offsetX,
      offsetY = sprite.offsetY,
      x = sprite.x,
      y = sprite.y,
      width = sprite.width,
      height = sprite.height,
      quad = nil, -- Recreate on draw
   }
end

return Sprite
