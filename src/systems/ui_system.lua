local InventoryView = require("src.ui.inventory_view")
local InventoryStateManager = require("src.ui.inventory_state_manager")

local UISystem = {}

local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()
local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local INV_GAP = 20
local TOOLBAR_ROWS = 1
local WIDTH = COLUMNS * SLOT_SIZE
local INV_HEIGHT = INV_ROWS * SLOT_SIZE
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * SLOT_SIZE + 8

function UISystem:init()
   local pool = self.pool

   pool:on(Events.ENTITY_INTERACTED, function(interaction)
      if interaction.target_entity.interactable then
         self:openStorageInventory(interaction.player_entity, interaction.target_entity)
      end
   end)

   pool:on(Events.INPUT_OPEN_INVENTORY, function(player_entity)
      self:openPlayerInventory(player_entity)
   end)

   pool:on(Events.INPUT_CLOSE_INVENTORY, function()
      InventoryStateManager:close()
   end)

   pool:on(Events.INPUT_INVENTORY_CLICK, function(coords)
      InventoryStateManager:handleSlotClick(coords.mouse_x, coords.mouse_y)
   end)
end

function UISystem:openPlayerInventory(player_entity)
   local views = {
      InventoryView:new(player_entity.toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = (SCREEN_WIDTH - WIDTH) / 2,
         y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
      }),
      InventoryView:new(player_entity.inventory, {
         id = "player_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = (SCREEN_WIDTH - WIDTH) / 2,
         y = (SCREEN_HEIGHT - INV_HEIGHT) / 2
      })
   }

   InventoryStateManager:open(views)
end

function UISystem:openStorageInventory(player_entity, target_entity)
   local total_width = WIDTH * 2 + INV_GAP

   local views = {
      InventoryView:new(player_entity.toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = (SCREEN_WIDTH - WIDTH) / 2,
         y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
      }),
      InventoryView:new(player_entity.inventory, {
         id = "player_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = (SCREEN_WIDTH - total_width) / 2,
         y = (SCREEN_HEIGHT - INV_HEIGHT) / 2
      }),
      InventoryView:new(target_entity.inventory, {
         id = "target_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = (SCREEN_WIDTH - total_width) / 2 + WIDTH + INV_GAP,
         y = (SCREEN_HEIGHT - INV_HEIGHT) / 2
      })
   }

   InventoryStateManager:open(views)
end

function UISystem:draw()
   if InventoryStateManager.isOpen then
      InventoryStateManager:draw()
   end
end

return UISystem
