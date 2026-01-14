local HeldStackView = Class("HeldStackView")

local SLOT_SIZE = 32
local BORDER_WIDTH = 2
local BACKGROUND_COLOR = {0.5, 0.45, 0.5, 0.8}
local BORDER_COLOR = {1, 1, 1, 0.8}
local TEXT_COLOR = {1, 1, 1, 1}
local HEADER_SIZE = 14
local TEXT_SIZE = 10

-- Quantity label offset from bottom-right corner of held stack
local QUANTITY_OFFSET_X = 18
local QUANTITY_OFFSET_Y = 18

--- @class HeldStackView
--- @field stack table The held stack data {itemId, quantity}
--- @field x number Current x position
--- @field y number Current y position
--- @field font love.Font Font for item letter
--- @field smallFont love.Font Font for quantity

--- @param stack table The held stack {itemId, quantity}
function HeldStackView:initialize(stack)
   self.stack = stack
   self.x = 0
   self.y = 0

   -- Cache fonts
   self.font = love.graphics.newFont(HEADER_SIZE)
   self.smallFont = love.graphics.newFont(TEXT_SIZE)

   -- Initialize position to mouse
   if stack then
      local mx, my = love.mouse.getPosition()
      local offset = SLOT_SIZE / 2
      self.x = mx - offset
      self.y = my - offset
   end
end

--- Update the held stack with new data
--- @param stack table The new stack data
function HeldStackView:updateStack(stack)
   self.stack = stack
end

--- Update the position to follow the cursor
--- @param dt number Delta time (unused but kept for consistency)
function HeldStackView:update(dt)
   local mx, my = love.mouse.getPosition()
   local offset = SLOT_SIZE / 2
   self.x = mx - offset
   self.y = my - offset
end

--- Draw the held stack using Love2D primitives
function HeldStackView:draw()
   if not self.stack then return end

   local x, y = self.x, self.y

   -- Store previous graphics state
   local prevFont = love.graphics.getFont()
   local pr, pg, pb, pa = love.graphics.getColor()

   -- Draw background
   love.graphics.setColor(BACKGROUND_COLOR)
   love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)

   -- Draw border
   love.graphics.setColor(BORDER_COLOR)
   love.graphics.setLineWidth(BORDER_WIDTH)
   love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE)
   love.graphics.setLineWidth(1)

   -- Draw item letter (centered)
   if self.stack.itemId then
      local itemText = string.sub(self.stack.itemId, 1, 1)
      love.graphics.setFont(self.font)
      love.graphics.setColor(TEXT_COLOR)

      local textWidth = self.font:getWidth(itemText)
      local textHeight = self.font:getHeight()
      local textX = x + (SLOT_SIZE - textWidth) / 2
      local textY = y + (SLOT_SIZE - textHeight) / 2

      love.graphics.print(itemText, textX, textY)
   end

   -- Draw quantity (bottom-right corner)
   if self.stack.quantity and self.stack.quantity > 1 then
      local quantityText = tostring(self.stack.quantity)
      love.graphics.setFont(self.smallFont)
      love.graphics.setColor(TEXT_COLOR)

      local quantityX = x + QUANTITY_OFFSET_X
      local quantityY = y + QUANTITY_OFFSET_Y

      love.graphics.print(quantityText, quantityX, quantityY)
   end

   -- Restore previous graphics state
   love.graphics.setFont(prevFont)
   love.graphics.setColor(pr, pg, pb, pa)
end

--- Destroy/cleanup (no FlexLove elements to destroy anymore)
function HeldStackView:destroy()
   self.stack = nil
   -- Fonts will be garbage collected
end

return HeldStackView
