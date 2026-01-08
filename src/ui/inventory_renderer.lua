local InventoryDrawHelpers = require("src.ui.inventory_draw_helpers")
local InventoryLayout = require("src.config.inventory_layout"):new()

local InventoryRenderer = Class("InventoryRenderer"):include(InventoryDrawHelpers)

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

--- Main draw function
function InventoryRenderer:draw()
   local player_inv_x = self.positions.player.x
   local player_inv_y = self.positions.player.y
   local layout_w = self.layout:getInventoryWidth()
   local layout_h = self.layout:getInventoryHeight()
   if self.target_inventory and self.target_inventory.input_slots then
      -- Side-by-side mode: player left, target right
      self:drawBox(player_inv_x, player_inv_y, layout_w, layout_h)
      self:drawSlots(player_inv_x, player_inv_y, self.player_inventory.input_slots)

      local target_inv_x = self.positions.target.x
      local target_inv_y = self.positions.target.y
      self:drawBox(target_inv_x, target_inv_y, layout_w, layout_h)
      self:drawSlots(target_inv_x, target_inv_y, self.target_inventory.input_slots)
   else
      -- Single inventory mode: player only, centered
      self:drawBox(player_inv_x, player_inv_y, layout_w, layout_h)
      self:drawSlots(player_inv_x, player_inv_y, self.player_inventory.input_slots)
   end

   -- Draw held item on top of everything
   self:drawHeldItem()
end

return InventoryRenderer
