local InventoryActions = {
   QUICK_TRANSFER = "quick_transfer",
   PICK_OR_PLACE  = "pick_or_place",
   PICK_ONE       = "pick_one",
   PICK_HALF      = "pick_half",
}

local ActionHandlers = {
   [InventoryActions.PICK_OR_PLACE] = function(self, slotInfo)
      return self:pickOrPlace(slotInfo)
   end,
   [InventoryActions.PICK_HALF] = function(self, slotInfo)
      return self:pickHalf(slotInfo)
   end,
   [InventoryActions.PICK_ONE] = function(self, slotInfo)
      return self:pickOne(slotInfo)
   end,
   [InventoryActions.QUICK_TRANSFER] = function(self, slotInfo)
      return self:quickTransfer(slotInfo)
   end,
}

return {
   Actions = InventoryActions,
   Handlers = ActionHandlers,
}
