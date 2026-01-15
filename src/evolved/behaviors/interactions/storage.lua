local get = Evolved.get
local trigger = Beholder.trigger

--- Storage interaction handler - opens inventory UI
--- @param playerId number The player entity ID
--- @param entityId number The target entity ID
--- @param interaction table The interaction data
return function(playerId, entityId, interaction)
   local playerInventory = get(playerId, FRAGMENTS.Inventory)
   local playerToolbar = get(playerId, FRAGMENTS.Toolbar)
   local targetInventory = get(entityId, FRAGMENTS.Inventory)
   trigger(Events.ENTITY_INTERACTED, playerInventory, targetInventory, playerToolbar, entityId)
end
