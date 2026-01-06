local InventoryComponent = require "src.components.inventory_component"
local Player = Class("Player")
local PLAYER_DATA = require "src.data.player_data"

function Player:initialize(x, y)
   data = PLAYER_DATA or {}
   self.position = Vector(x, y)
   self.velocity = Vector()
   self.isPlayer = true
   self.controllable = true

   self.color = data.color or Colors.WHITE
   self.interactionRange = data.interactionRange or 48
   self.mana = data.max_mana or 100
   self.mana_regen_rate = data.mana_regen_rate or 1
   self.max_mana = data.max_mana or 100
   self.maxSpeed = data.maxSpeed or 300
   self.name = data.name or "player"
   self.size = data.size or 16
   self.visual = data.visual or "circle"

   self.inventory = InventoryComponent:new(data.inventory)
end

return Player
