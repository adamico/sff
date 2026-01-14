local EntityRegistry = require("src.registries.entity_registry")
local EntityDrawHelper = require("src.helpers.entity_draw_helper")

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

observe(Events.PLACEMENT_MODE_ENTERED, function(item, slotIndex)
   EntityPlacementManager.isPlacing = true
   EntityPlacementManager.item = item
   EntityPlacementManager.sourceSlotIndex = slotIndex

   local mx, my = love.mouse.getPosition()
   EntityPlacementManager.ghostPosition = Vector(mx, my)
end)

observe(Events.INPUT_INVENTORY_OPENED, function()
   if EntityPlacementManager.isPlacing then
      EntityPlacementManager:cancelPlacement()
   end
end)

function EntityPlacementManager:update(dt)
   if not self.isPlacing then return end

   local mx, my = love.mouse.getPosition()
   self.ghostPosition = Vector(mx, my)
end

function EntityPlacementManager:draw()
   if not self.isPlacing or not self.ghostPosition then return end

   local entityData = EntityRegistry.getEntity(self.item.spawnsEntity)
   if not entityData then return end

   local size = entityData.size or Vector(32, 32)
   local shape = entityData.shape or "rectangle"
   local color = self.isValidPlacement and VALID_GHOST_COLOR or INVALID_GHOST_COLOR

   -- Convert mouse position (center) to draw position:
   -- Rectangles use top-left origin, circles use center
   local drawPos = self.ghostPosition
   if shape ~= "circle" then
      drawPos = Vector(
         self.ghostPosition.x - size.x / 2,
         self.ghostPosition.y - size.y / 2
      )
   end

   EntityDrawHelper.drawShape(shape, drawPos, size, color)

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
   if not toolbar or not toolbar.slots then return false end

   local slot = toolbar.slots[self.sourceSlotIndex]
   if not slot or not slot.itemId or slot.quantity <= 0 then return false end

   -- Request entity spawn via event (spawner_system handles creation)
   trigger(Events.ENTITY_SPAWN_REQUESTED, {
      entityId = self.item.spawnsEntity,
      position = self.ghostPosition,
      sourceSlotIndex = self.sourceSlotIndex,
   })

   -- Consume 1 item from toolbar slot
   slot.quantity = slot.quantity - 1
   if slot.quantity <= 0 then
      slot.itemId = nil
      slot.quantity = 0
      -- Exit placement mode if no more items
      self:cancelPlacement()
   end

   return true
end

function EntityPlacementManager:cancelPlacement()
   self.isPlacing = false
   self.item = nil
   self.sourceSlotIndex = nil
   self.ghostPosition = nil

   trigger(Events.PLACEMENT_MODE_EXITED, "cancelled")
   return true
end

return EntityPlacementManager
