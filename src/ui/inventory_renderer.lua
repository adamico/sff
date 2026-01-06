local InventoryRenderer = Class("InventoryRenderer")
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local lg = love.graphics

--- Renders the inventory UI of an interactable entity
--- @class InventoryRenderer
--- @field draw_x number
--- @field draw_y number
--- @field slot_size number
--- @field padding number
--- @field columns number
--- @field selected_slot number

--- Initialize the inventory renderer with the given inventory and options.
--- @param entity table
--- @param options table
function InventoryRenderer:initialize(entity, options)
   options = options or {}
   self.entity = entity
   self.inventory = entity.inventory
   self.columns = options.columns or 10
   self.slot_size = options.slot_size or 32

   self.draw_x = options.draw_x or SCREEN_WIDTH / 2 - self.columns * self.slot_size / 2
   self.draw_y = options.draw_y or SCREEN_HEIGHT / 2 - 400 / 2
   self.padding = options.padding or 4
   self.selected_slot = nil
end

function InventoryRenderer:drawBox(x, y)
   local padding = self.padding
   local border_color = {1, 1, 1}
   local bg_color = {0.5, 0.45, 0.5}
   local width = self.columns * self.slot_size
   local rows = 4
   local height = rows * self.slot_size
   lg.setColor(unpack(border_color))
   lg.rectangle("fill", x, y, width, height)
   lg.setColor(unpack(bg_color))
   lg.rectangle("fill", x + padding, y + padding, width - padding * 2, height - padding * 2)
end

function InventoryRenderer:drawSlots(x, y, slots)
   local number_of_slots = #slots
   local slot_size = self.slot_size
   local border_width = 2
   local padding = self.padding * 2 + 1
   for i = 1, number_of_slots do
      local col = (i - 1) % self.columns
      local row = math.floor((i - 1) / self.columns)
      local slot_x = x + padding + col * (slot_size - border_width)
      local slot_y = y + padding + row * (slot_size - border_width)
      lg.setColor(1, 1, 1)
      lg.rectangle("fill", slot_x, slot_y, slot_size, slot_size)
      lg.setColor(0.5, 0.45, 0.5)
      lg.rectangle("fill",
         slot_x + border_width, slot_y + border_width, slot_size - border_width * 2,
         slot_size - border_width * 2)
   end
end

function InventoryRenderer:draw()
   local box_x, box_y = self.draw_x, self.draw_y
   self:drawBox(box_x, box_y)
   self:drawSlots(box_x, box_y, self.inventory.input_slots)
end

return InventoryRenderer
