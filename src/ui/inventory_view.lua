local DrawHelper = require("src.helpers.draw_helper")
local InventoryView = Class("InventoryView"):include(DrawHelper)
local BORDER_WIDTH = 2

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
   self.border_width = BORDER_WIDTH
end

function InventoryView:draw()
   self:drawBox(self.x, self.y,
      self.columns * (self.slot_size - self.border_width) + self.padding * 2 + self.border_width,
      self.rows * (self.slot_size - self.border_width) + self.padding * 2 + self.border_width
   )
   self:drawSlots()
end

function InventoryView:drawSlots()
   local slots = self.inventory.input_slots
   local slot_size = self.slot_size
   for slotIndex = 1, #slots do
      local slot_x, slot_y = self:getSlotPosition(slotIndex)
      local slot = slots[slotIndex]
      self:drawSlot(slot_x, slot_y, slot_size, slot_size, slot)
   end
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
