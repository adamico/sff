Beholder.observe(Events.ENTITY_DAMAGED, function(entityId, damage)
   local health = Evolved.get(entityId, FRAGMENTS.Health)
   if health then
      Log.debug("Entity damaged:", entityId, "Health:", health.current, "Damage:", damage)
      health.current = health.current - damage
      if health.current <= 0 then
         Evolved.destroy(entityId)
      end
   end
end)
