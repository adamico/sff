local InventoryRenderer = require("src.ui.inventory_renderer")
local InventoryStateManager = require("src.ui.inventory_state_manager")

local UISystem = {}

function UISystem:init(player)
   local pool = self.pool
   self.toolbarRenderer = nil
   self.playerInventoryRenderer = nil
   self.storageInventoryRenderer = nil
   self.machineInventoryRenderer = nil

   pool:on(Events.ENTITY_INTERACTED, function(interaction)
      if interaction.target_entity.interactable then
         self:openStorageInventory(interaction.player_entity, interaction.target_entity)
      end
   end)

   pool:on(Events.INPUT_OPEN_INVENTORY, function(player_entity)
      self:openPlayerInventory(player_entity)
   end)

   pool:on(Events.INPUT_CLOSE_INVENTORY, function()
      self:closeInventory()
   end)

   pool:on(Events.INPUT_INVENTORY_CLICK, function(coords)
      self:handleInventoryClick(coords.mouse_x, coords.mouse_y)
   end)
end

function UISystem:update(dt)
   -- Update UI elements here
   -- animations can go here
end

function UISystem:draw()
   if self.storageInventoryRenderer then
      self.storageInventoryRenderer:draw()
   end

   if self.playerInventoryRenderer then
      self.playerInventoryRenderer:draw()
   end
end

function UISystem:openStorageInventory(player_entity, target_entity)
   InventoryStateManager:open(player_entity.inventory, target_entity.inventory)
   self.storageInventoryRenderer = InventoryRenderer:new(player_entity, target_entity)
end

function UISystem:openPlayerInventory(player_entity)
   InventoryStateManager:open(player_entity.inventory, nil)
   self.playerInventoryRenderer = InventoryRenderer:new(player_entity)
end

function UISystem:closeInventory()
   InventoryStateManager:close()
   self.playerInventoryRenderer = nil
   self.storageInventoryRenderer = nil
   self.machineInventoryRenderer = nil
end

function UISystem:handleInventoryClick(mouse_x, mouse_y)
   if not InventoryStateManager.isOpen then return end

   local slot_info = InventoryStateManager:getSlotAt(mouse_x, mouse_y)

   -- If no slot was clicked, do nothing
   if not slot_info then return end

   -- Delegate all click logic to the state manager
   InventoryStateManager:handleSlotClick(slot_info.slot_index, slot_info.inventory_type)
end

return UISystem
