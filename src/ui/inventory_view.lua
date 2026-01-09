local DrawHelper = require("src.helpers.draw_helper")
local InventoryView = Class("InventoryView"):include(DrawHelper)
local BORDER_WIDTH = 2

--- @class InventoryView
--- @field x number
--- @field y number
--- @field width number
--- @field height number
--- @field inventory InventoryComponent

--- @param inventory InventoryComponent
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

   -- Format: {{x = 200, y = 10}, {x = 300, y = 10}, ...}
   -- positions are relative to the inventory view's origin
   self.output_slot_positions = options.output_slot_positions or {}
end

function InventoryView:draw()
   local box_x, box_y, box_width, box_height = self:calculateBoxDimensions()
   self:drawBox(box_x, box_y, box_width, box_height)

   -- Draw all existing slot types dynamically
   local existingSlots = self:getExistingSlots()
   for _, slotData in ipairs(existingSlots) do
      self:drawSlots(slotData.type)
   end
end

function InventoryView:getExistingSlots()
   local slotData = {}
   for slotType in pairs(self.inventory) do
      if slotType:find("_slots") then
         local typeName = slotType:gsub("_slots", "")
         table.insert(slotData, {
            type = typeName,
            slots = self.inventory[slotType]
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
   if slotType == "input" then
      local col = (slot_index - 1) % self.columns
      local row = math.floor((slot_index - 1) / self.columns)
      local x = self.x + self.padding + col * (self.slot_size - self.border_width)
      local y = self.y + self.padding + row * (self.slot_size - self.border_width)
      return x, y
   elseif slotType == "output" then
      if self.output_slot_positions and self.output_slot_positions[slot_index] then
         local position = self.output_slot_positions[slot_index]
         return self.x + position.x, self.y + position.y
      else
         local x = self.x + self.padding + (slot_index - 1) * (self.slot_size - self.border_width)
         local y = self.y + self.padding + self.rows * (self.slot_size - self.border_width)
         return x, y
      end
   end
end

function InventoryView:isPointInSlot(mx, my, slot_x, slot_y)
   return mx >= slot_x and mx <= slot_x + self.slot_size
      and my >= slot_y and my <= slot_y + self.slot_size
end

function InventoryView:getSlotUnderMouse(mx, my)
   local allSlots = {"input", "output"}
   for _, slotType in ipairs(allSlots) do
      local slots = self.inventory[slotType.."_slots"]
      if slots then
         for slotIndex = 1, #slots do
            local slot_x, slot_y = self:getSlotPosition(slotIndex, slotType)
            if self:isPointInSlot(mx, my, slot_x, slot_y) then
               return {
                  view = self,
                  slotIndex = slotIndex,
                  slot = slots[slotIndex],
                  slotType = slotType
               }
            end
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
