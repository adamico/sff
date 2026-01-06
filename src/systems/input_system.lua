local lk = love.keyboard

local InputSystem = {}

local function update_input_vector(pool)
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

   pool:emit("update_input_vector", vector.normalized)
end

function InputSystem:init()
   -- pool is automatically set by nata
end

function InputSystem:update()
   update_input_vector(self.pool)
end

return InputSystem
