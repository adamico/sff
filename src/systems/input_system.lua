local lk = love.keyboard
local InputHelper = require("src.helpers.input_helper")

local InputSystem = {}

function InputSystem:init()
end

local function update_input_vector(pool)
   local vector = Vector()

   if InputHelper.isActionPressed("move_up") then
      vector.y = -1
   elseif InputHelper.isActionPressed("move_down") then
      vector.y = 1
   end

   if InputHelper.isActionPressed("move_left") then
      vector.x = -1
   elseif InputHelper.isActionPressed("move_right") then
      vector.x = 1
   end

   pool:emit("update_input_vector", vector.normalized)
end

function InputSystem:update()
   update_input_vector(self.pool)
end

return InputSystem
