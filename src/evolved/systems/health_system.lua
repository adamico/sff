local observe = Beholder.observe
local trigger = Beholder.trigger

observe(Events.ENTITY_DAMAGED, function(entityId, damage)
   local health = Evolved.get(entityId, FRAGMENTS.Health)
   if health then
      Log.debug("Entity damaged:", entityId, "Health:", health.current, "Damage:", damage)
      health.current = health.current - damage
      if health.current <= 0 then
         trigger(Events.ENTITY_DIED, entityId)
         Evolved.destroy(entityId)
      else
         trigger(Events.ENTITY_HEALTH_CHANGED, entityId, health.current)
      end
   end
end)
