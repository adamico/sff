local InventoryStateManager = {
   isOpen = false,
   playerInventory = nil,
   targetInventory = nil,
   layoutConfig = nil,
   heldStack = nil,
}

function InventoryStateManager:open(player_inventory, target_inventory, layout_config)
   self.isOpen = true
   self.playerInventory = player_inventory
   self.targetInventory = target_inventory or nil
   self.layoutConfig = layout_config
end

function InventoryStateManager:close()
   self.isOpen = false
   self.playerInventory = nil
   self.targetInventory = nil
   self.layoutConfig = nil
   self.heldStack = nil
end

return InventoryStateManager
