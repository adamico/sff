local trigger = Beholder.trigger

--- Storage interaction handler - opens inventory UI
--- @param playerId number The player entity ID (unused)
--- @param targetEntityId number The target entity ID
--- @param interaction table The interaction data (unused)
return function(playerId, targetEntityId, interaction)
   trigger(Events.ENTITY_INTERACTED, targetEntityId)
end
