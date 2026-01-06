local Player = Class("Player")

function Player:initialize(x, y, config)
   self.position = Vector(x, y)
   self.velocity = Vector()
   self.isPlayer = true
   self.controllable = true

   self.color = config.color or Colors.WHITE
   self.interactionRange = config.interactionRange or 48
   self.inventory = config.initial_inventory or {}
   self.maxSpeed = config.maxSpeed or 300
   self.name = config.name or "player"
   self.size = config.size or 16
   self.visual = config.visual or "circle"
end

function Player:update_input_vector(vector)
   self.velocity = vector * self.maxSpeed
end

function Player:open_inventory()
   print("Opening inventory...")
end

return Player
