-- ============================================================================
-- UI Event System
-- ============================================================================
-- Handles all UI-related events and coordinates with state managers
-- Separates event handling from rendering logic
local SlotViewManager = require("src.managers.slot_view_manager")
local UICoordinator = require("src.managers.ui_coordinator")
local InventoryHelper = require("src.helpers.inventory_helper")
local ItemRegistry = require("src.data.queries.item_query")

local get = Evolved.get
local observe = Beholder.observe
local trigger = Beholder.trigger

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

observe(Events.INPUT_INVENTORY_CLICKED, function(userdata)
   if SlotViewManager.isOpen then
      SlotViewManager:handleAction(userdata)
   end
end)

observe(Events.TOOLBAR_MOVED_TO_SLOT, function(slotIndex)
   if SlotViewManager.isOpen then
      SlotViewManager:handleToolbarMove(slotIndex)
   end
end)


-- Toolbar slot activation (triggers placement mode for deployable items)
observe(Events.TOOLBAR_SLOT_ACTIVATED, function(slotIndex)
   local toolbar = get(ENTITIES.Player, FRAGMENTS.Toolbar)
   local slot = toolbar and InventoryHelper.getSlot(toolbar, slotIndex)
   if not slot or not slot.itemId then return end

   local item = ItemRegistry.getItem(slot.itemId)
   if item and item.deployable and item.spawnsEntity then
      trigger(Events.PLACEMENT_MODE_ENTERED, item, slotIndex)
   end
end)

-- ============================================================================
-- System Registration
-- ============================================================================
-- This system doesn't use the ECS builder pattern since it only observes events
-- Similar to health_system.lua and spawner_system.lua

Log.info("UI Event System: Registered event observers")
