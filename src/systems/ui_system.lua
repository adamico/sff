local Vector = require("lib.brinevector")
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
   self.toolbarView = nil -- Created lazily

   pool:on(Events.ENTITY_INTERACTED, function(interaction)
      if interaction.target_entity.interactable then
         self:openTargetInventory(interaction.player_entity, interaction.target_entity)
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

--- Get or create the persistent toolbar view
function UISystem:getToolbarView()
   if not self.toolbarView then
      local player = self.pool.groups.controllable.entities[1]
      if not player then return nil end

      self.toolbarView = InventoryView:new(player.toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = (SCREEN_WIDTH - WIDTH) / 2,
         y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
      })
   end
   return self.toolbarView
end

function UISystem:openPlayerInventory(player_entity)
   local views = {
      self:getToolbarView(),
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

function UISystem:openTargetInventory(player_entity, target_entity)
   local screen_center = Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

   local views = {
      self:getToolbarView(),
      InventoryView:new(player_entity.inventory, {
         id = "player_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = screen_center.x - WIDTH - INV_GAP / 2,
         y = screen_center.y - INV_HEIGHT / 2,
         draggable = true
      }),
      InventoryView:new(target_entity.inventory, {
         id = "target_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = screen_center.x + INV_GAP / 2,
         y = screen_center.y - INV_HEIGHT / 2,
         draggable = true
      })
   }

   InventoryStateManager:open(views)
end

function UISystem:draw()
   -- Toolbar is always visible
   local toolbarView = self:getToolbarView()
   if toolbarView then
      toolbarView:draw()
   end

   -- Draw inventory views + held item when open
   if InventoryStateManager.isOpen then
      InventoryStateManager:draw()
   end
end

return UISystem
