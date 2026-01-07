local InventoryRenderer = require("src.ui.inventory_renderer")
local InventoryStateManager = require("src.ui.inventory_state_manager")

local UISystem = {}

function UISystem:init(player)
   self.toolbarRenderer = nil
   self.playerInventoryRenderer = nil
   self.storageInventoryRenderer = nil
   self.machineInventoryRenderer = nil

   self.pool:on(Events.ENTITY_INTERACTED, function(interaction)
      Log.trace("Interaction: ", interaction)
      if interaction.target_entity.interactable then
         self:openStorageInventory(interaction.player_entity, interaction.target_entity)
      end
   end)

   self.pool:on(Events.INPUT_OPEN_INVENTORY, function(player_entity)
      self:openPlayerInventory(player_entity)
   end)

   self.pool:on(Events.INPUT_CLOSE_INVENTORY, function()
      self:closeInventory()
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
   self.storageInventoryRenderer = InventoryRenderer:new(player_entity, target_entity)
   InventoryStateManager:open(player_entity.inventory, target_entity.inventory, layoutConfig)
end

function UISystem:openPlayerInventory(player_entity)
   self.playerInventoryRenderer = InventoryRenderer:new(player_entity)
   InventoryStateManager:open(player_entity.inventory, nil, layoutConfig)
end

function UISystem:closeInventory()
   self.playerInventoryRenderer = nil
   self.storageInventoryRenderer = nil
   self.machineInventoryRenderer = nil
   InventoryStateManager:close()
end

return UISystem
