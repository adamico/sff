local InventoryView = require("src.ui.inventory_view")
local InventoryStateManager = require("src.ui.inventory_state_manager")

local builder = Evolved.builder
local observe = Beholder.observe
local group = Beholder.group

local RenderUISystem = {}

local SLOT_SIZE = 32
local COLUMNS = 10
local INV_ROWS = 4
local INV_GAP = 20
local TOOLBAR_ROWS = 1
local WIDTH = COLUMNS * SLOT_SIZE
local INV_HEIGHT = INV_ROWS * SLOT_SIZE
local TOOLBAR_HEIGHT = TOOLBAR_ROWS * SLOT_SIZE + 8
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

function RenderUISystem:init()
   self.uiObservers = {}
   self.observersRegistered = false
   self.toolbarView = nil
   self:registerObservers()

   return self
end

function RenderUISystem:getToolbarView(toolbar)
   if not self.toolbarView then
      if not toolbar then return nil end

      self.toolbarView = InventoryView:new(toolbar, {
         id = "toolbar",
         columns = COLUMNS,
         rows = TOOLBAR_ROWS,
         x = (SCREEN_WIDTH - WIDTH) / 2,
         y = SCREEN_HEIGHT - TOOLBAR_HEIGHT - 4
      })
   end

   return self.toolbarView
end

function RenderUISystem:registerObservers()
   if self.observersRegistered then return end
   self.observersRegistered = true

   group(UI_OBSERVERS, function()
      observe(Events.ENTITY_INTERACTED, function(playerInventory, targetInventory)
         Log.trace("Entity interacted")
         self:openTargetInventory(playerInventory, targetInventory)
      end)
      observe(Events.INPUT_INVENTORY_OPENED, function(playerInventory)
         Log.trace("Inventory "..tostring(playerInventory).." opened")
         self:openPlayerInventory(playerInventory)
      end)
      observe(Events.INPUT_INVENTORY_CLOSED, function()
         Log.trace("Inventory closed")
         InventoryStateManager:close()
      end)
      observe(Events.INPUT_INVENTORY_CLICKED, function(mouseX, mouseY)
         Log.trace("Inventory clicked")
         InventoryStateManager:handleSlotClick(mouseX, mouseY)
      end)
   end)
end

function RenderUISystem:openPlayerInventory(playerInventory)
   InventoryStateManager:open({
      self:getToolbarView(playerInventory),
      InventoryView:new(playerInventory, {
         id = "player_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = (SCREEN_WIDTH - WIDTH) / 2,
         y = (SCREEN_HEIGHT - INV_HEIGHT) / 2
      })
   })
end

function RenderUISystem:openTargetInventory(playerInventory, targetInventory)
   local screen_center = Vector(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

   InventoryStateManager:open({
      self:getToolbarView(),
      InventoryView:new(playerInventory, {
         id = "player_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = screen_center.x - WIDTH - INV_GAP / 2,
         y = screen_center.y - INV_HEIGHT / 2,
         draggable = true
      }),
      InventoryView:new(targetInventory, {
         id = "target_inventory",
         columns = COLUMNS,
         rows = INV_ROWS,
         x = screen_center.x + INV_GAP / 2,
         y = screen_center.y - INV_HEIGHT / 2,
         draggable = true
      })
   })
end

function RenderUISystem:renderToolbar(chunk, entityCount)
   local toolbars = chunk:components(FRAGMENTS.Toolbar)

   for i = 1, entityCount do
      local toolbar = toolbars[i]
      toolbarView = self:getToolbarView(toolbar)
      if toolbarView then
         toolbarView:draw()
      end
   end
end

function RenderUISystem:execute()
   builder()
      :name("SYSTEMS.RenderUI")
      :group(STAGES.OnRender)
      :include(FRAGMENTS.Toolbar)
      :execute(function(chunk, _, entityCount)
         self:renderToolbar(chunk, entityCount)
         if InventoryStateManager.isOpen then
            InventoryStateManager:draw()
         end
      end):build()
end

RenderUISystem:init():execute()
