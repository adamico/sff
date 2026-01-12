local DrawHelper = {}
local lg = love.graphics

local SLOT_SIZE = 32
local BORDER_COLOR = {1, 1, 1}
local BACKGROUND_COLOR = {0.5, 0.45, 0.5}
local STACK_BORDER_COLOR = {1, 1, 1, 0.8}
local STACK_BACKGROUND_COLOR = {0.5, 0.45, 0.5, 0.8}
local TEXT_COLOR = {1, 1, 1}
local BORDER_WIDTH = 2

function DrawHelper:drawBox(x, y, width, height)
   self:drawBorder(x, y, width, height, BORDER_COLOR)
   self:drawBackground(x, y, width, height, BACKGROUND_COLOR)
end

function DrawHelper:drawLabel(textDrawable, x, y)
   lg.setColor(TEXT_COLOR)
   lg.draw(textDrawable, x, y - 16)
end

function DrawHelper:drawSlot(x, y, width, height, slot)
   self:drawBorder(x, y, width, height, BORDER_COLOR)
   self:drawBackground(x, y, width, height, BACKGROUND_COLOR)

   -- Draw item if slot has one
   if slot.item_id then
      self:drawItem(x, y, width, height, slot, TEXT_COLOR)
   end
end

function DrawHelper:drawItem(x, y, width, height, slot, color)
   lg.setColor(color)
   lg.print(string.sub(slot.item_id, 1, 1), x + BORDER_WIDTH + 2, y + BORDER_WIDTH + 2)
   if slot.quantity and slot.quantity > 1 then
      lg.print(tostring(slot.quantity), x + width - 18, y + height - 16)
   end
end

function DrawHelper:drawBorder(x, y, width, height, color)
   lg.setColor(color)
   lg.rectangle("fill", x, y, width, height)
end

function DrawHelper:drawBackground(x, y, width, height, color)
   lg.setColor(color)
   lg.rectangle("fill", x + BORDER_WIDTH, y + BORDER_WIDTH, width - BORDER_WIDTH * 2, height - BORDER_WIDTH * 2)
end

return DrawHelper
