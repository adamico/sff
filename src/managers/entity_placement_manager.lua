local InventoryHelper = require("src.helpers.inventory_helper")
local CameraHelper = require("src.helpers.camera_helper")
local EntityDrawHelper = require("src.helpers.entity_draw_helper")
local UICoordinator = require("src.managers.ui_coordinator")
local PlacementValidationHelper = require("src.helpers.placement_validation_helper")

local observe = Beholder.observe
local trigger = Beholder.trigger
local get = Evolved.get

local VALID_GHOST_COLOR = {0, 1, 0, 0.5}
local INVALID_GHOST_COLOR = {1, 0, 0, 0.5}

local EntityPlacementManager = {
   isPlacing = false,
   item = nil,
   sourceSlotIndex = nil,
   ghostPosition = nil,
   isValidPlacement = true,
}

observe(Events.PLACEMENT_CLICKED, function(button)
   EntityPlacementManager:handleClick(button)
end)

observe(Events.PLACEMENT_MODE_ENTERED, function(item, slotIndex)
   UICoordinator.enterPlacementMode() -- Transition state
   EntityPlacementManager.isPlacing = true
   EntityPlacementManager.item = item
   EntityPlacementManager.sourceSlotIndex = slotIndex

   local _, mx, my = shove.mouseToViewport()
   local worldX, worldY = CameraHelper.screenToWorld(mx, my)
   EntityPlacementManager.ghostPosition = Vector(worldX, worldY)
end)

observe(Events.INPUT_INVENTORY_OPENED, function()
   if EntityPlacementManager.isPlacing then
      EntityPlacementManager:cancelPlacement()
   end
end)

function EntityPlacementManager:update(dt)
   if not self.isPlacing then return end

   local _, mx, my = shove.mouseToViewport()
   local worldX, worldY = CameraHelper.screenToWorld(mx, my)
   self.ghostPosition = Vector(worldX, worldY)
   self.isValidPlacement = PlacementValidationHelper.validatePlacement(self.item, self.ghostPosition)
end

function EntityPlacementManager:draw()
   if not self.isPlacing or not self.ghostPosition then return end

   local ghostBounds = PlacementValidationHelper.getGhostBounds(self.item, self.ghostPosition)
   if not ghostBounds then return end

   local color = self.isValidPlacement and VALID_GHOST_COLOR or INVALID_GHOST_COLOR
   EntityDrawHelper.drawHitbox(ghostBounds, color)
   love.graphics.setColor(1, 1, 1, 1)
end

function EntityPlacementManager:handleClick(button)
   if not EntityPlacementManager.isPlacing then return false end

   if button == 1 then
      return self:deployEntity()
   elseif button == 2 then
      return self:cancelPlacement()
   end

   return false
end

function EntityPlacementManager:deployEntity()
   if not self.isPlacing or not self.isValidPlacement then return false end

   if not self.item or not self.item.spawnsEntity then
      Log.warn("EntityPlacementManager: No spawnsEntity defined for item")
      return false
   end

   local toolbar = get(ENTITIES.Player, FRAGMENTS.Toolbar)
   if not toolbar then return false end

   local slot = InventoryHelper.getSlot(toolbar, self.sourceSlotIndex)
   if not slot or not slot.itemId or slot.quantity <= 0 then return false end

   trigger(Events.ENTITY_SPAWN_REQUESTED, {
      entityId = self.item.spawnsEntity,
      position = self.ghostPosition,
      sourceSlotIndex = self.sourceSlotIndex,
   })

   slot.quantity = slot.quantity - 1
   if slot.quantity <= 0 then
      slot.itemId = nil
      slot.quantity = 0
      self:cancelPlacement()
   end

   return true
end

function EntityPlacementManager:cancelPlacement()
   self.isPlacing = false
   self.item = nil
   self.sourceSlotIndex = nil
   self.ghostPosition = nil

   UICoordinator.exitPlacementMode()
   trigger(Events.PLACEMENT_MODE_EXITED)
   return true
end

return EntityPlacementManager
