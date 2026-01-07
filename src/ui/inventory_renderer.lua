local InventoryLayout = require("src.config.inventory_layout")
local InventoryStateManager = require("src.ui.inventory_state_manager")

local InventoryRenderer = Class("InventoryRenderer")
local lg = love.graphics

--- Renders the inventory UI of an interactable entity
--- @class InventoryRenderer
--- @field player_inventory table
--- @field target_inventory table|nil
--- @field layout table
--- @field positions table

--- Initialize the inventory renderer with the given inventory and options.
--- @param player_entity table
--- @param target_entity? table Optional target entity for side-by-side view
function InventoryRenderer:initialize(player_entity, target_entity)
   self.player_inventory = player_entity.inventory
   self.target_inventory = target_entity and target_entity.inventory or nil
   self.layout = InventoryLayout
   self.positions = self.layout:getInventoryPositions(target_entity ~= nil)
end

--- Draw a box background for an inventory
--- @param x number X position
--- @param y number Y position
function InventoryRenderer:drawBox(x, y)
   local padding = self.layout.padding
   local border_color = {1, 1, 1}
   local bg_color = {0.5, 0.45, 0.5}
   local width = self.layout:getInventoryWidth()
   local height = self.layout:getInventoryHeight()

   lg.setColor(unpack(border_color))
   lg.rectangle("fill", x, y, width, height)
   lg.setColor(unpack(bg_color))
   lg.rectangle("fill", x + padding, y + padding, width - padding * 2, height - padding * 2)
end

--- Draw an item icon with quantity
--- @param item_id string The item ID
--- @param quantity number The item quantity
--- @param x number X position to draw at
--- @param y number Y position to draw at
--- @param alpha number Optional alpha transparency (default 1.0)
function InventoryRenderer:drawItemIcon(item_id, quantity, x, y, alpha)
   alpha = alpha or 1.0
   local slot_size = self.layout.slot_size

   -- Draw item icon
   lg.setColor(1, 1, 1, alpha)
   lg.print(string.sub(item_id, 1, 1), x, y)

   -- Draw quantity if more than 1
   if quantity and quantity > 1 then
      lg.print(tostring(quantity), x + slot_size - 24, y + slot_size - 22)
   end
end

--- Draw inventory slots
--- @param base_x number Base X position of inventory
--- @param base_y number Base Y position of inventory
--- @param slots table Array of slots to draw
function InventoryRenderer:drawSlots(base_x, base_y, slots)
   local slot_size = self.layout.slot_size
   local border_width = self.layout.border_width

   for i = 1, #slots do
      local slot_x, slot_y = self.layout:getSlotPosition(i, base_x, base_y)
      local slot = slots[i]

      -- Draw slot border
      lg.setColor(1, 1, 1)
      lg.rectangle("fill", slot_x, slot_y, slot_size, slot_size)

      -- Draw slot background
      lg.setColor(0.5, 0.45, 0.5)
      lg.rectangle("fill",
         slot_x + border_width, slot_y + border_width,
         slot_size - border_width * 2, slot_size - border_width * 2)

      -- Draw item if slot has one
      if slot.item_id then
         self:drawItemIcon(slot.item_id, slot.quantity, slot_x + border_width + 2, slot_y + border_width + 2, 1.0)
      end
   end
end

--- Draw the held item following the cursor
function InventoryRenderer:drawHeldItem()
   if not InventoryStateManager.heldStack then return end

   local mouse_x, mouse_y = love.mouse.getPosition()
   local slot_size = self.layout.slot_size
   local border_width = self.layout.border_width
   local offset = slot_size / 2

   -- Draw semi-transparent slot background
   lg.setColor(1, 1, 1, 0.8)
   lg.rectangle("fill", mouse_x - offset, mouse_y - offset, slot_size, slot_size)

   lg.setColor(0.5, 0.45, 0.5, 0.8)
   lg.rectangle("fill",
      mouse_x - offset + border_width,
      mouse_y - offset + border_width,
      slot_size - border_width * 2,
      slot_size - border_width * 2)

   -- Draw the item
   local held = InventoryStateManager.heldStack
   if not held or not held.item_id then return end

   self:drawItemIcon(held.item_id, held.quantity,
      mouse_x - offset + border_width + 2,
      mouse_y - offset + border_width + 2,
      0.9)
end

--- Main draw function
function InventoryRenderer:draw()
   if self.target_inventory and self.target_inventory.input_slots then
      -- Side-by-side mode: player left, target right
      self:drawBox(self.positions.player.x, self.positions.player.y)
      self:drawSlots(self.positions.player.x, self.positions.player.y, self.player_inventory.input_slots)

      self:drawBox(self.positions.target.x, self.positions.target.y)
      self:drawSlots(self.positions.target.x, self.positions.target.y, self.target_inventory.input_slots)
   else
      -- Single inventory mode: player only, centered
      self:drawBox(self.positions.player.x, self.positions.player.y)
      self:drawSlots(self.positions.player.x, self.positions.player.y, self.player_inventory.input_slots)
   end

   -- Draw held item on top of everything
   self:drawHeldItem()
end

return InventoryRenderer
