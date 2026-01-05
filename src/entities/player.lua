local Class = require("lib.middleclass")
local Vector = require("lib.brinevector")

local Player = Class("Player")
local lk = love.keyboard

function Player:initialize(x, y)
   self.position = Vector(x, y)
   self.r = 16
   self.velocity = Vector()
   self.isPlayer = true
   self.maxSpeed = 300
end

function Player:update(dt)
   local inputVector = Vector()

   if lk.isScancodeDown("w") then
      inputVector.y = -1
   elseif lk.isScancodeDown("s") then
      inputVector.y = 1
   end

   if lk.isScancodeDown("a") then
      inputVector.x = -1
   elseif lk.isScancodeDown("d") then
      inputVector.x = 1
   end

   self.velocity = inputVector.normalized * self.maxSpeed
end

function Player:draw()
end

return Player
