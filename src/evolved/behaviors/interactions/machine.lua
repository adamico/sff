local trigger = Beholder.trigger

--- Machine interaction handler - opens machine view UI
--- @param playerId number The player entity ID
--- @param entityId number The target entity ID
--- @param interaction table The interaction data
return function(playerId, entityId, interaction)
   trigger(Events.MACHINE_INTERACTED, entityId)
end
