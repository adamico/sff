local ManaComponent = Class("ManaComponent")

--- @class ManaComponent
--- @field current number
--- @field max number
--- @field regen_rate number
--- @method initialize
--- @method add
--- @method remove

--- Initialize the Mana Component
--- @param current number
--- @param max number
--- @param regen_rate number
--- @param consume_rate number
function ManaComponent:initialize(current, max, regen_rate, consume_rate)
   self.current = current
   self.max = max
   self.regen_rate = regen_rate
   self.consume_rate = consume_rate
end

--- Add mana to the component
--- @param amount number
function ManaComponent:add(amount)
   self.current = math.min(self.current + amount, self.max)
end

--- Remove mana from the component
--- @param amount number
function ManaComponent:remove(amount)
   self.current = math.max(self.current - amount, 0)
end

return ManaComponent
