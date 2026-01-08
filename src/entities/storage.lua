local InventoryComponent = require("src.components.inventory_component")
local EntityRegistry = require("src.registries.entity_registry")
local Storage = Class("Storage")

function Storage:initialize(x, y, id)
   local data = EntityRegistry.getEntity(id) or {}
   self.id = id
   self.position = Vector(x, y)
   self.slots = {}

   self.color = data.color or Colors.WHITE
   self.creative = data.creative or false
   self.interactable = data.interactable or false
   self.name = data.name or "storage"
   self.size = data.size or Vector(32, 32)
   self.visual = data.visual or "square"

   self.inventory = InventoryComponent:new(data.inventory)
end

return Storage
