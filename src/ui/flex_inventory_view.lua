local FlexInventoryView = Class("FlexInventoryView")
local get = Evolved.get

local BORDER_WIDTH = 2
local BACKGROUND_COLOR = Color.new(0.5, 0.45, 0.5)
local BORDER_COLOR = Color.new(1, 1, 1)
local TEXT_COLOR = Color.new(1, 1, 1)
local HEADER_SIZE = 14
local TEXT_SIZE = 12

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
   self.x = math.floor(options.x or 0)
   self.y = math.floor(options.y or 0)
   self.columns = options.columns or 10
   self.rows = options.rows or 4
   self.slot_size = options.slot_size or 32
   self.padding = options.padding or 4
   self.border_width = BORDER_WIDTH
   self.entityId = options.entityId or nil

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
      x = math.floor(boxX),
      y = math.floor(boxY),
      width = boxWidth,
      height = boxHeight,
      backgroundColor = BACKGROUND_COLOR,
      border = self.border_width,
      borderColor = BORDER_COLOR,
      padding = {
         top = self.padding,
         right = self.padding,
         bottom = self.padding,
         left = self.padding
      },
      positioning = "absolute",
      userdata = {view = self}
   })

   self:createSlots()

   -- Create state label if entity has state machine
   if self.entityId then
      local state = self:getCurrentState()
      if state then
         self.stateLabel = Flexlove.new({
            id = self.id.."_state",
            x = math.floor(self.padding),
            y = -20,
            text = state,
            textColor = TEXT_COLOR,
            textSize = TEXT_SIZE,
            positioning = "absolute",
            parent = self.containerElement
         })
      end
   end
end

function FlexInventoryView:createSlots()
   local slots = self.inventory.slots

   for slotIndex = 1, #slots do
      local slot = slots[slotIndex]
      local slot_x, slot_y = self:getSlotPosition(slotIndex)

      -- Convert to relative coordinates (relative to container)
      local relative_x = math.floor(slot_x - self.x)
      local relative_y = math.floor(slot_y - self.y)

      -- Create slot element
      local slotElement = Flexlove.new({
         id = self.id.."_slot_"..slotIndex,
         x = relative_x,
         y = relative_y,
         width = self.slot_size,
         height = self.slot_size,
         backgroundColor = BACKGROUND_COLOR,
         border = self.border_width,
         borderColor = BORDER_COLOR,
         text = slot.item_id and string.sub(slot.item_id, 1, 1) or "",
         textColor = TEXT_COLOR,
         textSize = HEADER_SIZE,
         textAlign = "center",
         positioning = "absolute",
         userdata = {
            slotIndex = slotIndex,
            view = self
         },
         onEvent = function(element, event)
            if event.type == "click" then
               local mx, my = love.mouse.getPosition()
               -- Pass element userdata to avoid redundant hit detection
               Beholder.trigger(Events.INPUT_INVENTORY_CLICKED, mx, my, element.userdata)
            end
         end,
         parent = self.containerElement
      })

      -- Store reference
      table.insert(self.slotElements, {
         element = slotElement,
         slotIndex = slotIndex,
      })
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
      local element = slotData.element
      local slots = self.inventory.slots

      if slots and slots[slotIndex] then
         local slot = slots[slotIndex]
         local itemText = slot.item_id and string.sub(slot.item_id, 1, 1) or ""
         element:setText(itemText)

         -- Clear existing quantity labels
         element:clearChildren()

         -- Add quantity label if needed
         if slot.quantity and slot.quantity > 1 then
            Flexlove.new({
               id = self.id.."_qty_"..slotIndex.."_update",
               x = math.floor(self.slot_size - 18),
               y = math.floor(self.slot_size - 16),
               text = tostring(slot.quantity),
               textColor = TEXT_COLOR,
               textSize = TEXT_SIZE,
               positioning = "absolute",
               parent = element
            })
         end
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
   local slots = self.inventory.slots
   table.insert(slotData, {
      slots = slots
   })
   return slotData
end

function FlexInventoryView:calculateBoxDimensions()
   local x, y = self.x, self.y
   local min_x, min_y = math.huge, math.huge
   local max_x, max_y = -math.huge, -math.huge

   -- Calculate bounds based on existing slots
   local existingSlots = self:getExistingSlots()
   for _, slotData in ipairs(existingSlots) do
      local slots = slotData.slots

      if slots and #slots > 0 then
         for slotIndex = 1, #slots do
            local slot_x, slot_y = self:getSlotPosition(slotIndex)
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
      local width = self.columns * self.slot_size + self.padding * 2
      local height = self.rows * self.slot_size + self.padding * 2
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

function FlexInventoryView:getSlotPosition(slot_index)
   local col = (slot_index - 1) % self.columns
   local row = math.floor((slot_index - 1) / self.columns)
   local x = math.floor(self.x + self.padding / 8 + col * self.slot_size)
   local y = math.floor(self.y + self.padding / 8 + row * self.slot_size)
   return x, y
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

      if slotIndex then
         local slots = self.inventory.slots
         if slots and slots[slotIndex] then
            return {
               view = self,
               slotIndex = slotIndex,
               slot = slots[slotIndex],
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
   self.x = math.floor(x)
   self.y = math.floor(y)

   -- Update container element position
   if self.containerElement then
      self.containerElement.x = self.x
      self.containerElement.y = self.y

      -- Recalculate and update all slot positions (relative to container)
      for _, slotData in ipairs(self.slotElements) do
         local slot_x, slot_y = self:getSlotPosition(slotData.slotIndex)
         -- Convert to relative coordinates
         local relative_x = math.floor(slot_x - self.x)
         local relative_y = math.floor(slot_y - self.y)
         slotData.element.x = relative_x
         slotData.element.y = relative_y
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
