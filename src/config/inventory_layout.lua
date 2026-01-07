local InventoryLayout = {
   slot_size = 32,
   padding = 4,
   border_width = 2,
   columns = 10,
   rows = 4,
   gap_between_inventories = 20,
}

--- Calculate the position of a slot in the grid
--- @param slot_index number The slot index (1-based)
--- @param base_x number The base x position of the inventory grid
--- @param base_y number The base y position of the inventory grid
--- @return number, number The x and y position of the slot
function InventoryLayout:getSlotPosition(slot_index, base_x, base_y)
   local col = (slot_index - 1) % self.columns
   local row = math.floor((slot_index - 1) / self.columns)
   local padding_offset = self.padding * 2 + 1

   local x = base_x + padding_offset + col * (self.slot_size - self.border_width)
   local y = base_y + padding_offset + row * (self.slot_size - self.border_width)

   return x, y
end

--- Calculate the base positions for player and target inventories
--- @param has_target boolean Whether a target inventory exists
--- @return table Positions {player = {x, y}, target = {x, y} or nil}
function InventoryLayout:getInventoryPositions(has_target)
   local SCREEN_WIDTH = love.graphics.getWidth()
   local SCREEN_HEIGHT = love.graphics.getHeight()
   local single_width = self.columns * self.slot_size
   local height = self.rows * self.slot_size + self.padding * 2 + 4

   local positions = {}

   if has_target then
      -- Side-by-side mode
      local total_width = single_width * 2 + self.gap_between_inventories
      local left_x = SCREEN_WIDTH / 2 - total_width / 2
      local right_x = left_x + single_width + self.gap_between_inventories
      local y = SCREEN_HEIGHT / 2 - height / 2

      positions.player = {x = left_x, y = y}
      positions.target = {x = right_x, y = y}
   else
      -- Single inventory mode (centered)
      local x = SCREEN_WIDTH / 2 - single_width / 2
      local y = SCREEN_HEIGHT / 2 - height / 2

      positions.player = {x = x, y = y}
      positions.target = nil
   end

   return positions
end

--- Check if a point is inside a slot
--- @param mouse_x number Mouse x position
--- @param mouse_y number Mouse y position
--- @param slot_x number Slot x position
--- @param slot_y number Slot y position
--- @return boolean Whether the point is inside the slot
function InventoryLayout:isPointInSlot(mouse_x, mouse_y, slot_x, slot_y)
   return mouse_x >= slot_x and mouse_x <= slot_x + self.slot_size
      and mouse_y >= slot_y and mouse_y <= slot_y + self.slot_size
end

--- Get the width of a single inventory panel
--- @return number The width in pixels
function InventoryLayout:getInventoryWidth()
   return self.columns * self.slot_size
end

--- Get the height of a single inventory panel
--- @return number The height in pixels
function InventoryLayout:getInventoryHeight()
   return self.rows * self.slot_size + self.padding * 2 + 4
end

return InventoryLayout
