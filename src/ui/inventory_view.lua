local DrawHelper = require("src.helpers.draw_helper")
local InventoryView = Class("InventoryView"):include(DrawHelper)
local get = Evolved.get
local BORDER_WIDTH = 2

--- @class InventoryView
--- @field x number
--- @field y number
--- @field width number
--- @field height number
--- @field inventory table

--- @param inventory table
--- @param options table
function InventoryView:initialize(inventory, options)
   self.inventory = inventory
   options = options or {}
   self.id = options.id or "inventory_view"
   self.x = options.x or 0
   self.y = options.y or 0
   self.columns = options.columns or 10
   self.rows = options.rows or 4
   self.slot_size = options.slot_size or 32
   self.padding = options.padding or 4
   self.border_width = BORDER_WIDTH
   self.entityId = options.entityId or nil
end

function InventoryView:draw()
   local boxX, boxY, boxWidth, boxHeight = self:calculateBoxDimensions()
   self:drawBox(boxX, boxY, boxWidth, boxHeight)

   -- Draw all existing slot types dynamically
   local existingSlots = self:getExistingSlots()
   for _, slotData in ipairs(existingSlots) do
      self:drawSlots(slotData.type)
   end

   -- Query current state from entity if available
   local state = self:getCurrentState()
   if state then self:drawState(state, boxX, boxY) end
end

function InventoryView:getCurrentState()
   if not self.entityId then return nil end

   local stateMachine = get(self.entityId, FRAGMENTS.StateMachine)
   if stateMachine then
      return stateMachine.current
   end

   return nil
end

function InventoryView:getExistingSlots()
   local slotData = {}
   for slotType in pairs(self.inventory) do
      if slotType:find("_slots") then
         local slots = self.inventory[slotType]
         local typeName = slotType:gsub("_slots", "")
         table.insert(slotData, {
            type = typeName,
            slots = slots
         })
      end
   end
   return slotData
end

function InventoryView:calculateBoxDimensions()
   local x, y = self.x, self.y
   local min_x, min_y = math.huge, math.huge
   local max_x, max_y = -math.huge, -math.huge

   -- Calculate bounds based on existing slots
   local existingSlots = self:getExistingSlots()
   for _, slotData in ipairs(existingSlots) do
      local slotType = slotData.type
      local slots = slotData.slots

      if slots and #slots > 0 then
         for slotIndex = 1, #slots do
            local slot_x, slot_y = self:getSlotPosition(slotIndex, slotType)
            -- Convert to relative coordinates
            local rel_x = slot_x - self.x
            local rel_y = slot_y - self.y

            min_x = math.min(min_x, rel_x)
            min_y = math.min(min_y, rel_y)
            max_x = math.max(max_x, rel_x + self.slot_size)
            max_y = math.max(max_y, rel_y + self.slot_size)
         end
      end
   end

   -- Fallback to default dimensions if no slots exist
   if min_x == math.huge then
      local width = self.columns * (self.slot_size - self.border_width) + self.padding * 2 + self.border_width
      local height = self.rows * (self.slot_size - self.border_width) + self.padding * 2 + self.border_width
      return x, y, width, height
   end

   local width = max_x - min_x + self.padding * 2
   local height = max_y - min_y + self.padding * 2

   return x, y, width, height
end

function InventoryView:getWidth()
   local _x, _y, width, _height = self:calculateBoxDimensions()
   return width
end

function InventoryView:drawSlots(slotType)
   local slots = self.inventory[slotType.."_slots"]
   if not slots or #slots == 0 then return end

   local slot_size = self.slot_size
   for slotIndex = 1, #slots do
      local slot_x, slot_y = self:getSlotPosition(slotIndex, slotType)
      local slot = slots[slotIndex]
      self:drawSlot(slot_x, slot_y, slot_size, slot_size, slot)
   end
end

function InventoryView:getSlotPosition(slot_index, slotType)
   local col = (slot_index - 1) % self.columns
   local row = math.floor((slot_index - 1) / self.columns)
   local x = self.x + self.padding + col * (self.slot_size - self.border_width)
   local y = self.y + self.padding + row * (self.slot_size - self.border_width)
   return x, y
end

function InventoryView:isPointInSlot(mx, my, slot_x, slot_y)
   return mx >= slot_x and mx <= slot_x + self.slot_size
      and my >= slot_y and my <= slot_y + self.slot_size
end

function InventoryView:getSlotUnderMouse(mx, my)
   local slots = self.inventory.input_slots
   if slots then
      for slotIndex = 1, #slots do
         local slot_x, slot_y = self:getSlotPosition(slotIndex, "input")
         if self:isPointInSlot(mx, my, slot_x, slot_y) then
            return {
               view = self,
               slotIndex = slotIndex,
               slot = slots[slotIndex],
               slotType = "input"
            }
         end
      end
   end

   return nil
end

--- Set the position of the inventory view when dragging the inventory window
--- @param x number
--- @param y number
function InventoryView:setPosition(x, y)
   self.x = x
   self.y = y
end

return InventoryView
