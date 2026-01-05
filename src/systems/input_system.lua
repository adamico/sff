local InputSystem = Class("InputSystem")

local lk = love.keyboard

local pool

function InputSystem:initialize(pool)
   self.pool = pool
end

function InputSystem:update(dt)
   local vector = Vector()

   if lk.isScancodeDown("w") then
      vector.y = -1
   elseif lk.isScancodeDown("s") then
      vector.y = 1
   end

   if lk.isScancodeDown("a") then
      vector.x = -1
   elseif lk.isScancodeDown("d") then
      vector.x = 1
   end

   self.pool:emit("player_input", vector)
end

return InputSystem
