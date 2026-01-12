local FlexInventoryView = Class("FlexInventoryView")
local get = Evolved.get
local Color = Flexlove.Color

local BORDER_WIDTH = 2
local BACKGROUND_COLOR = Color.new(0.5, 0.45, 0.5)
local BORDER_COLOR = Color.new(1, 1, 1)
local TEXT_COLOR = Color.new(1, 1, 1)

--- @class FlexInventoryView
--- @field x number
--- @field y number
--- @field width number
--- @field height number
--- @field inventory table
--- @field containerElement table FlexLove Element
--- @field slotElements table

--- @param inventory table
--- @param options table
function FlexInventoryView:initialize(inventory, options)
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

   -- Format: {{x = 200, y = 10}, {x = 300, y = 10}, ...}
   -- positions are relative to the inventory view's origin
   self.output_slot_positions = options.output_slot_positions or {}

   -- FlexLove elements
   self.containerElement = nil
   self.slotElements = {}
   self.stateLabel = nil

   -- Build the UI
   self:buildUI()
end

function FlexInventoryView:buildUI()
   local boxX, boxY, boxWidth, boxHeight = self:calculateBoxDimensions()

   -- Main container panel
   self.containerElement = Flexlove.new({
      id = self.id.."_container",
      x = boxX,
      y = boxY,
      width = boxWidth,
      height = boxHeight,
      backgroundColor = BACKGROUND_COLOR,
      border = {
         width = self.border_width,
         color = BORDER_COLOR
      },
      padding = {
         top = self.padding,
         right = self.padding,
         bottom = self.padding,
         left = self.padding
      },
      positioning = "absolute",
      userdata = {view = self}
   })

   -- Create slots for all existing slot types
   local existingSlots = self:getExistingSlots()
   for _, slotData in ipairs(existingSlots) do
      self:createSlots(slotData.type)
   end

   -- Create state label if entity has state machine
   if self.entityId then
      local state = self:getCurrentState()
      if state then
         self.stateLabel = Flexlove.new({
            id = self.id.."_state",
            x = boxX + self.padding,
            y = boxY - 20,
            text = state,
            textColor = TEXT_COLOR,
            textSize = 12,
            positioning = "absolute",
            parent = self.containerElement
         })
      end
   end
end

function FlexInventoryView:createSlots(slotType)
   local slots = self.inventory[slotType.."_slots"]
   if not slots or #slots == 0 then return end

   for slotIndex = 1, #slots do
      local slot = slots[slotIndex]
      local slot_x, slot_y = self:getSlotPosition(slotIndex, slotType)

      -- Create slot element
      local slotElement = Flexlove.new({
         id = self.id.."_slot_"..slotType.."_"..slotIndex,
         x = slot_x,
         y = slot_y,
         width = self.slot_size,
         height = self.slot_size,
         backgroundColor = BACKGROUND_COLOR,
         border = {
            width = self.border_width,
            color = BORDER_COLOR
         },
         text = slot.item_id and string.sub(slot.item_id, 1, 1) or "",
         textColor = TEXT_COLOR,
         textSize = 14,
         textAlign = "center",
         positioning = "absolute",
         userdata = {
            slotIndex = slotIndex,
            slotType = slotType,
            view = self
         },
         parent = self.containerElement
      })

      -- Store reference
      table.insert(self.slotElements, {
         element = slotElement,
         slotIndex = slotIndex,
         slotType = slotType
      })

      -- Add quantity label if needed
      if slot.quantity and slot.quantity > 1 then
         Flexlove.new({
            id = self.id.."_qty_"..slotType.."_"..slotIndex,
            x = slot_x + self.slot_size - 18,
            y = slot_y + self.slot_size - 16,
            text = tostring(slot.quantity),
            textColor = TEXT_COLOR,
            textSize = 12,
            positioning = "absolute",
            parent = slotElement
         })
      end
   end
end

function FlexInventoryView:draw()
   -- Update dynamic content
   self:updateSlots()

   -- Update state label if it exists
   if self.stateLabel and self.entityId then
      local state = self:getCurrentState()
      if state then
         self.stateLabel:setText(state)
      end
   end
end

function FlexInventoryView:updateSlots()
   -- Update slot appearances based on current inventory state
   for _, slotData in ipairs(self.slotElements) do
      local slotIndex = slotData.slotIndex
      local slotType = slotData.slotType
      local element = slotData.element
      local slots = self.inventory[slotType.."_slots"]

      if slots and slots[slotIndex] then
         local slot = slots[slotIndex]
         local itemText = slot.item_id and string.sub(slot.item_id, 1, 1) or ""
         element:setText(itemText)

         -- Update quantity label (simplified - could be improved)
         -- For now, we'll handle this in a more sophisticated way later
      end
   end
end

function FlexInventoryView:getCurrentState()
   if not self.entityId then return nil end

   local stateMachine = get(self.entityId, FRAGMENTS.StateMachine)
   if stateMachine then
      return stateMachine.current
   end

   return nil
end

function FlexInventoryView:getExistingSlots()
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

function FlexInventoryView:calculateBoxDimensions()
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

function FlexInventoryView:getWidth()
   local _x, _y, width, _height = self:calculateBoxDimensions()
   return width
end

function FlexInventoryView:getSlotPosition(slot_index, slotType)
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

function FlexInventoryView:isPointInSlot(mx, my, slot_x, slot_y)
   return mx >= slot_x and mx <= slot_x + self.slot_size
      and my >= slot_y and my <= slot_y + self.slot_size
end

function FlexInventoryView:getSlotUnderMouse(mx, my)
   -- Use FlexLove's built-in hit detection
   local element = Flexlove.getElementAtPosition(mx, my)

   if element and element.userdata and element.userdata.view == self then
      local slotIndex = element.userdata.slotIndex
      local slotType = element.userdata.slotType

      if slotIndex and slotType then
         local slots = self.inventory[slotType.."_slots"]
         if slots and slots[slotIndex] then
            return {
               view = self,
               slotIndex = slotIndex,
               slot = slots[slotIndex],
               slotType = slotType
            }
         end
      end
   end

   return nil
end

--- Set the position of the inventory view when dragging the inventory window
--- @param x number
--- @param y number
function FlexInventoryView:setPosition(x, y)
   self.x = x
   self.y = y

   -- Update container element position
   if self.containerElement then
      self.containerElement.x = x
      self.containerElement.y = y

      -- Recalculate and update all slot positions
      for _, slotData in ipairs(self.slotElements) do
         local slot_x, slot_y = self:getSlotPosition(slotData.slotIndex, slotData.slotType)
         slotData.element.x = slot_x
         slotData.element.y = slot_y
      end
   end
end

--- Destroy FlexLove elements when view is no longer needed
function FlexInventoryView:destroy()
   if self.containerElement then
      self.containerElement:destroy()
      self.containerElement = nil
   end
   self.slotElements = {}
   self.stateLabel = nil
end

return FlexInventoryView
