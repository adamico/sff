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
--- @param player_entity table
--- @param target_entity? table Optional target entity for side-by-side view
--- @param options? table
function InventoryRenderer:initialize(player_entity, target_entity, options)
   options = options or {}
   self.player_inventory = player_entity.inventory
   self.target_inventory = target_entity and target_entity.inventory or nil

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
   local height = rows * self.slot_size + padding * 2 + 4
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
      local slot = slots[i]
      lg.setColor(1, 1, 1)
      lg.rectangle("fill", slot_x, slot_y, slot_size, slot_size)
      lg.setColor(0.5, 0.45, 0.5)
      lg.rectangle("fill",
         slot_x + border_width, slot_y + border_width,
         slot_size - border_width * 2, slot_size - border_width * 2)
      if slot.item_id then
         lg.setColor(1, 1, 1)
         lg.print(string.sub(slot.item_id, 1, 1), slot_x + border_width + 2, slot_y + border_width + 2)
      end
   end
end

function InventoryRenderer:draw()
   local gap = 20
   local single_width = self.columns * self.slot_size

   if self.target_inventory then
      -- Side-by-side mode: player left, target right
      local total_width = single_width * 2 + gap
      local left_x = SCREEN_WIDTH / 2 - total_width / 2
      local right_x = left_x + single_width + gap

      self:drawBox(left_x, self.draw_y)
      self:drawSlots(left_x, self.draw_y, self.player_inventory.input_slots)

      self:drawBox(right_x, self.draw_y)
      self:drawSlots(right_x, self.draw_y, self.target_inventory.input_slots)
   else
      -- Single inventory mode: player only, centered
      local center_x = SCREEN_WIDTH / 2 - single_width / 2

      self:drawBox(center_x, self.draw_y)
      self:drawSlots(center_x, self.draw_y, self.player_inventory.input_slots)
   end
end

return InventoryRenderer
