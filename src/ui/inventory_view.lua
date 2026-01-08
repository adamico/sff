local InventoryView = Class("InventoryView")

local lg = love.graphics
local BACKGROUND_COLOR = {1, 1, 1}
local BORDER_COLOR = {0.5, 0.45, 0.5}

--- @class InventoryView
--- @field x number
--- @field y number
--- @field width number
--- @field height number
--- @field inventory InventoryComponent

--- @param inventory InventoryComponent
--- @param options table
function InventoryView:initialize(inventory, options)
   self.inventory = inventory

   options = options or {}
   self.id = options.id or "inventory_view"
   self.x = options.x or 0
   self.y = options.y or 0
   self.columns = options.columns or 10
   self.rows = options.rows or 4
   self.slot_size = options.slot_size or 32
   self.padding = options.padding or 4
   self.border_width = options.border_width or 2
end

function InventoryView:draw()
   self:drawBox()
   self:drawSlots()
end

function InventoryView:drawBox()
   local padding = self.padding
   local x = self.x + padding
   local y = self.y + padding
   local width = self:getWidth()
   local height = self:getHeight()
   lg.setColor(unpack(BORDER_COLOR))
   lg.rectangle("fill", x, y, width, height)
   lg.setColor(unpack(BACKGROUND_COLOR))
   lg.rectangle("fill", x + padding, y + padding, width - padding * 2, height - padding * 2)
end

function InventoryView:drawSlots()
   local slots = self.inventory.input_slots
   local slot_size = self.slot_size
   local border_width = self.border_width
   for slotIndex = 1, #slots do
      local slot_x, slot_y = self:getSlotPosition(slotIndex)
      local slot = slots[slotIndex]

      -- Draw slot border
      lg.setColor(unpack(BORDER_COLOR))
      lg.rectangle("fill", slot_x, slot_y, slot_size, slot_size)

      -- Draw slot background
      lg.setColor(unpack(BACKGROUND_COLOR))
      lg.rectangle("fill",
         slot_x + border_width, slot_y + border_width,
         slot_size - border_width * 2, slot_size - border_width * 2)

      -- Draw item if slot has one
      if slot.item_id then
         lg.setColor(0.2, 0.2, 0.2)
         lg.print(string.sub(slot.item_id, 1, 1),
            slot_x + border_width + 2,
            slot_y + border_width + 2
         )
         if slot.quantity and slot.quantity > 1 then
            lg.print(tostring(slot.quantity), slot_x + slot_size - 18, slot_y + slot_size - 16)
         end
      end
   end
end

function InventoryView:getWidth()
   return self.columns * (self.slot_size - self.border_width) + self.padding * 2 + self.border_width
end

function InventoryView:getHeight()
   return self.rows * (self.slot_size - self.border_width) + self.padding * 2 + self.border_width
end

function InventoryView:getSlotPosition(slot_index)
   local col = (slot_index - 1) % self.columns
   local row = math.floor((slot_index - 1) / self.columns)
   local x = self.x + self.padding + col * (self.slot_size - self.border_width)
   local y = self.y + self.padding + row * (self.slot_size - self.border_width)
   return x, y
end

function InventoryView:isPointInSlot(mx, my, slot_x, slot_y)
   return mx >= slot_x and mx <= slot_x + self.slot_size
      and my >= slot_y and my <= slot_y + self.slot_size
end

function InventoryView:getSlotUnderMouse(mx, my)
   local slots = self.inventory.input_slots
   for slotIndex = 1, #slots do
      local slot_x, slot_y = self:getSlotPosition(slotIndex)
      if self:isPointInSlot(mx, my, slot_x, slot_y) then
         return {
            view = self,
            slotIndex = slotIndex,
            slot = slots[slotIndex]
         }
      end
   end

   return nil
end

--- Set the position of the inventory view when dragging the inventory window
--- @param x number
--- @param y number
function InventoryView:setPosition(x, y)
   self.x = x
   self.y = y
end

return InventoryView
