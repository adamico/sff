local InventoryRenderer = require("src.ui.inventory_renderer")
local UISystem = {}

function UISystem:init(player)
   self.toolbarRenderer = nil
   self.playerInventoryRenderer = nil
   self.storageInventoryRenderer = nil
   self.machineInventoryRenderer = nil

   self.pool:on(Events.ENTITY_INTERACTED, function(entity)
      if entity.interactable then
         self:openStorageInventory(entity)
      end
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
end

function UISystem:openStorageInventory(storage)
   self.openStorage = storage
   self.storageInventoryRenderer = InventoryRenderer:new(storage)
end

return UISystem
