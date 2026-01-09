local ManaSystem = {}

function ManaSystem:update(dt)
   for _entityIndex, entity in ipairs(self.pool.groups.mana.entities) do
      self:regenMana(entity, dt)
   end
end

function ManaSystem:regenMana(entity, dt)
   local mana = entity.mana
   local currentMana = mana.current

   currentMana = math.min(currentMana + entity.regenRate * dt, mana.maxMana)
   entity.mana.current = currentMana
end

return ManaSystem
