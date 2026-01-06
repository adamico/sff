local InventoryComponent = require("src.components.inventory_component")
local Storage = Class("Storage")
local STORAGES_DATA = require("src.data.storages_data")

function Storage:initialize(x, y, id)
   local data = STORAGES_DATA[id] or {}
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
