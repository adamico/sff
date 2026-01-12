local FlexDrawHelper = {}

local BACKGROUND_COLOR = Color.new(0.5, 0.45, 0.5, 0.8)
local SLOT_SIZE = 32
local BORDER_COLOR = Color.new(1, 1, 1, 0.8)
local TEXT_COLOR = Color.new(1, 1, 1)
local TEXT_SIZE = 12

-- This helper provides utility functions for rendering UI elements that don't fit
-- into the standard FlexLove element hierarchy, such as items being dragged by the cursor

--- Draw a held item stack following the mouse cursor
--- @param stack table The held stack {item_id, quantity}
--- @param mouse_x number Mouse X position
--- @param mouse_y number Mouse Y position
function FlexDrawHelper:drawHeldStack(stack, mouse_x, mouse_y)
   if not stack or not stack.item_id then return end

   local size = SLOT_SIZE
   local offset = size / 2
   local x, y = mouse_x - offset, mouse_y - offset

   -- Draw using immediate mode love.graphics calls since this follows the cursor
   -- and doesn't fit well into FlexLove's retained mode structure
   love.graphics.push()

   -- Border
   love.graphics.setColor(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b, BORDER_COLOR.a)
   love.graphics.rectangle("fill", x, y, size, size)

   -- Background
   love.graphics.setColor(BACKGROUND_COLOR.r, BACKGROUND_COLOR.g, BACKGROUND_COLOR.b, BACKGROUND_COLOR.a)
   love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4)

   -- Item text (first letter of item_id)
   love.graphics.setColor(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a)
   local itemText = string.sub(stack.item_id, 1, 1)
   love.graphics.print(itemText, x + 4, y + 4)

   -- Quantity
   if stack.quantity and stack.quantity > 1 then
      love.graphics.print(tostring(stack.quantity), x + size - 18, y + size - 16)
   end

   love.graphics.pop()
end

--- Alternative: Create a FlexLove element for held stack (retained mode approach)
--- This would be updated each frame with the cursor position
--- @param stack table The held stack {item_id, quantity}
--- @param mouse_x number Mouse X position
--- @param mouse_y number Mouse Y position
--- @return table|nil The FlexLove element for the held stack
function FlexDrawHelper:createHeldStackElement(stack, mouse_x, mouse_y)
   if not stack or not stack.item_id then return nil end

   local size = SLOT_SIZE
   local offset = size / 2

   local element = Flexlove.new({
      id = "held_stack",
      x = mouse_x - offset,
      y = mouse_y - offset,
      width = size,
      height = size,
      backgroundColor = BACKGROUND_COLOR,
      border = {
         width = 2,
         color = BORDER_COLOR
      },
      text = string.sub(stack.item_id, 1, 1),
      textColor = TEXT_COLOR,
      textSize = TEXT_SIZE,
      textAlign = "center",
      positioning = "absolute",
      z = 9999, -- Always on top
      userdata = {held_stack = true}
   })

   -- Add quantity label if needed
   if stack.quantity and stack.quantity > 1 then
      Flexlove.new({
         id = "held_stack_quantity",
         x = mouse_x - offset + size - 18,
         y = mouse_y - offset + size - 16,
         text = tostring(stack.quantity),
         textColor = TEXT_COLOR,
         textSize = TEXT_SIZE,
         positioning = "absolute",
         parent = element
      })
   end

   return element
end

--- Update held stack element position
--- @param element table The held stack element
--- @param mouse_x number New mouse X position
--- @param mouse_y number New mouse Y position
function FlexDrawHelper:updateHeldStackPosition(element, mouse_x, mouse_y)
   if not element then return end

   local size = SLOT_SIZE
   local offset = size / 2

   element.x = mouse_x - offset
   element.y = mouse_y - offset
end

return FlexDrawHelper
