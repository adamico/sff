local InventorySystem = {}
local InputHelper = require("src.helpers.input_helper")

function InventorySystem:init()
   self.keyDetector = InputHelper.createEdgeDetector({threshold = 0.2})
end

function InventorySystem:update()
   if self.keyDetector:check(InputHelper.isActionPressed("open_inventory")) then
      self.pool:emit("inventory:opened")
   end
end

return InventorySystem
