local InventoryComponent = require "src.components.inventory_component"
local ManaComponent = require "src.components.mana_component"
local PLAYER_DATA = require "src.data.player_data"

local Player = Class("Player")

--- @class Player
--- @field position Vector
--- @field velocity Vector
--- @field isPlayer boolean
--- @field controllable boolean
--- @field color Color
--- @field interactionRange number
--- @field maxSpeed number
--- @field name string
--- @field size number
--- @field visual string
--- @field mana ManaComponent
--- @field inventory InventoryComponent
--- @field toolbar InventoryComponent

--- Player constructor
function Player:initialize(x, y)
   data = PLAYER_DATA or {}
   self.position = Vector(x, y)
   self.velocity = Vector()
   self.isPlayer = true
   self.controllable = true

   self.color = data.color or Colors.WHITE
   self.interactionRange = data.interactionRange or 48
   self.maxSpeed = data.maxSpeed or 300
   self.name = data.name or "player"
   self.size = data.size or 16
   self.visual = data.visual or "circle"

   self.mana = ManaComponent:new(data.mana)
   self.inventory = InventoryComponent:new(data.inventory)
   self.toolbar = InventoryComponent:new(data.toolbar)
end

return Player
