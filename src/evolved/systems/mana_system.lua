local builder = Evolved.builder

local observe = Beholder.observe
local trigger = Beholder.trigger

observe(Events.ENTITY_HARVESTED, function(attackerId, entityId, damage)
   local attackerMana = Evolved.get(attackerId, FRAGMENTS.Mana)
   local entityMana = Evolved.get(entityId, FRAGMENTS.Mana)
   if entityMana then
      if entityMana.current <= 0 then
         Log.debug(string.format("Can't harvest entity %d because it has no mana", entityId))
         return
      end

      Log.debug(string.format("Entity %d harvested %d mana from %d", attackerId, damage, entityId))
      entityMana.current = entityMana.current - damage
      trigger(Events.ENTITY_MANA_CHANGED, entityId, entityMana.current)
   end

   if not attackerMana then
      Log.debug(string.format("Attacker %d can't harvest mana", attackerId))
   end

   if attackerMana.current + damage <= attackerMana.max then
      attackerMana.current = attackerMana.current + damage
      trigger(Events.ENTITY_MANA_CHANGED, attackerId, attackerMana.current)
   else
      Log.debug(string.format("Attacker %d can't harvest more mana, current mana: %d", attackerId, attackerMana.current))
   end
end)

builder()
   :name("SYSTEMS.Mana")
   :group(STAGES.OnUpdate)
   :include(FRAGMENTS.Mana)
   :execute(function(chunk, _, entityCount)
      local manas = chunk:components(FRAGMENTS.Mana)
      local dt = UNIFORMS.getDeltaTime()

      for i = 1, entityCount do
         local mana = manas[i]
         local regenRate = mana.regenRate or 0

         if regenRate > 0 and mana.current < mana.max then
            mana.current = math.min(mana.current + regenRate * dt, mana.max)
         end
      end
   end):build()
