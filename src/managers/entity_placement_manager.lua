local EntityRegistry = require("src.data.queries.entity_query")
local EntityDrawHelper = require("src.helpers.entity_draw_helper")
local CollisionHelper = require("src.helpers.collision_helper")
local InventoryHelper = require("src.helpers.inventory_helper")

local observe = Beholder.observe
local trigger = Beholder.trigger
local get = Evolved.get
local execute = Evolved.execute
local builder = Evolved.builder

local VALID_GHOST_COLOR = {0, 1, 0, 0.5}
local INVALID_GHOST_COLOR = {1, 0, 0, 0.5}

local EntityPlacementManager = {
   isPlacing = false,
   item = nil,
   sourceSlotIndex = nil,
   ghostPosition = nil,
   isValidPlacement = true,
}

-- Query for all physical entities (same as collision system)
local physicalQuery = builder()
   :name("QUERIES.PlacementPhysical")
   :include(TAGS.Physical)
   :build()

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

--- Build ghost hitbox bounds at current position
--- @param self table EntityPlacementManager
--- @return table|nil bounds World-space hitbox bounds or nil
local function getGhostBounds(self)
   if not self.item or not self.item.spawnsEntity then return nil end

   local entityData = EntityRegistry.getEntity(self.item.spawnsEntity)
   if not entityData then return nil end

   local hitbox = entityData.hitbox or {shape = "circle", offsetX = 0, offsetY = 0, radius = 16}

   if hitbox.shape == "circle" then
      return {
         shape = "circle",
         x = self.ghostPosition.x + hitbox.offsetX,
         y = self.ghostPosition.y + hitbox.offsetY,
         radius = hitbox.radius,
      }
   else
      return {
         shape = "rectangle",
         x = self.ghostPosition.x + hitbox.offsetX,
         y = self.ghostPosition.y + hitbox.offsetY,
         width = hitbox.width,
         height = hitbox.height,
      }
   end
end

--- Check if ghost bounds collide with any existing entity
--- @param ghostBounds table World-space hitbox bounds
--- @return boolean true if collision found (invalid placement)
local function checkCollisionWithExisting(ghostBounds)
   for chunk, entityIds, entityCount in execute(physicalQuery) do
      local positions, hitboxes = chunk:components(FRAGMENTS.Position, FRAGMENTS.Hitbox)

      for i = 1, entityCount do
         local entityBounds = CollisionHelper.getHitboxBounds(positions[i], hitboxes[i])

         if CollisionHelper.areColliding(ghostBounds, entityBounds) then
            return true -- Collision found
         end
      end
   end

   return false -- No collision
end

function EntityPlacementManager:update(dt)
   if not self.isPlacing then return end

   local mx, my = love.mouse.getPosition()
   self.ghostPosition = Vector(mx, my)

   -- Check for collisions with existing entities
   local ghostBounds = getGhostBounds(self)
   if ghostBounds then
      self.isValidPlacement = not checkCollisionWithExisting(ghostBounds)
   else
      self.isValidPlacement = false
   end
end

function EntityPlacementManager:draw()
   if not self.isPlacing or not self.ghostPosition then return end

   local ghostBounds = getGhostBounds(self)
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
