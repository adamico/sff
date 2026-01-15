local trigger = Beholder.trigger

--- Creature interaction handler - triggers creature-specific interaction
--- @param playerId number The player entity ID
--- @param entityId number The target entity ID
--- @param interaction table The interaction data (includes action field)
return function(playerId, entityId, interaction)
   trigger(Events.CREATURE_INTERACTED, entityId, interaction.action)
end
