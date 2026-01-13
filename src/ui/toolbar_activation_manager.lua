local ItemRegistry = require("src.registries.item_registry")

local observe = Beholder.observe
local trigger = Beholder.trigger
local get = Evolved.get


local ToolbarActivationManager = {
   toolbar = nil,
}

function ToolbarActivationManager:getToolbar()
   Log.debug("Getting toolbar")
   if not self.toolbar then
      self.toolbar = get(ENTITIES.Player, FRAGMENTS.Toolbar)
   end

   return self.toolbar
end

function ToolbarActivationManager:getSlot(slotIndex)
   local toolbar = self:getToolbar()
   if not toolbar or not toolbar.slots then return nil end

   return toolbar.slots[slotIndex]
end

observe(Events.TOOLBAR_SLOT_ACTIVATED, function(slotIndex)
   local slot = ToolbarActivationManager:getSlot(slotIndex)
   if not slot or not slot.item_id then return end

   local item = ItemRegistry.getItem(slot.item_id)
   if not item then
      Log.warn("Toolbar slot activated but item not found: "..slot.item_id)
      return
   end

   Log.debug("Toolbar slot activated: "..slotIndex)
   Log.debug("Item: "..item.name)
   if item.deployable and item.spawns_entity then
      trigger(Events.PLACEMENT_MODE_ENTERED, item, slotIndex)
   end
end)

return ToolbarActivationManager
