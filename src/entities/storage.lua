local Storage = Class("Storage")

function Storage:initialize(x, y, config)
   self.position = Vector(x, y)
   self.slots = {}

   self.color = config.color or Colors.WHITE
   self.creative = config.creative or false
   self.interactable = config.interactable or false
   self.max_slots = config.max_slots or 0
   self.name = config.name or "storage"
   self.size = config.size or Vector(32, 32)
   self.visual = config.visual or "square"
end

return Storage
