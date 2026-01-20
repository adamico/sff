-- ============================================================================
-- UI Event System
-- ============================================================================
-- Handles all UI-related events and coordinates with state managers
-- Separates event handling from rendering logic

local SlotViewManager = require("src.managers.slot_view_manager")
local UICoordinator = require("src.managers.ui_coordinator")
local observe = Beholder.observe

-- Register event observers for entity/storage interaction (inventory view)
observe(Events.ENTITY_INTERACTED, function(entityId)
   UICoordinator.openTargetInventory(entityId)
end)

-- Register event observers for machine interaction (machine view)
observe(Events.MACHINE_INTERACTED, function(entityId)
   UICoordinator.openMachineView(entityId)
end)

observe(Events.INPUT_INVENTORY_OPENED, function(playerInventory, playerToolbar, weaponSlot, armorSlot)
   UICoordinator.openPlayerInventory(playerInventory, playerToolbar, weaponSlot, armorSlot)
end)

observe(Events.UI_MODAL_CLOSED, function()
   UICoordinator.closeModal()
end)

observe(Events.INPUT_INVENTORY_CLICKED, function(mouseX, mouseY, userdata)
   if SlotViewManager.isOpen then
      SlotViewManager:handleAction(mouseX, mouseY, userdata)
   end
end)

-- ============================================================================
-- System Registration
-- ============================================================================
-- This system doesn't use the ECS builder pattern since it only observes events
-- Similar to health_system.lua and spawner_system.lua

Log.info("UI Event System: Registered event observers")
