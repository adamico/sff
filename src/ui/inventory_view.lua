local InventoryStateManager = require("src.managers.inventory_state_manager")
local MachineStateManager = require("src.managers.machine_state_manager")
local InventoryView = Class("InventoryView")

local BACKGROUND_COLOR = Color.new(0.5, 0.45, 0.5)
local BORDER_COLOR = Color.new(1, 1, 1)
local BORDER_WIDTH = 2
local COLUMNS = 10
local HEADER_SIZE = 14
local PADDING = 4
local QUANTITY_OFFSET = 18
local ROWS = 4
local SLOT_SIZE = 32
local TEXT_COLOR = Color.new(1, 1, 1)
local TEXT_SIZE = 10

--- @class InventoryView
--- @field x number
--- @field y number
--- @field width number
--- @field height number
--- @field inventory table
--- @field containerElement table FlexLove Element
--- @field slotElements table

--- @param inventory table
--- @param options table
function InventoryView:initialize(inventory, options)
   self.inventory = inventory
   options = options or {}
   self.id = options.id or "inventory_view"
   self.x = math.floor(options.x or 0)
   self.y = math.floor(options.y or 0)
   self.columns = options.columns or COLUMNS
   self.rows = options.rows or ROWS
   self.slotSize = options.slotSize or SLOT_SIZE
   self.padding = options.padding or PADDING
   self.borderWidth = BORDER_WIDTH
   self.entityId = options.entityId or nil

   -- FlexLove elements
   self.containerElement = nil
   self.slotsContainer = nil
   self.slotElements = {}

   -- Build the UI
   self:buildUI()
end

function InventoryView:buildUI()
   local width, height = self:calculateBoxDimensions()

   self.containerElement = Flexlove.new({
      id = self.id.."_container",
      x = self.x,
      y = self.y,
      width = width,
      height = height,
      backgroundColor = BACKGROUND_COLOR,
      border = self.borderWidth,
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

   local slotsWidth = self.columns * self.slotSize
   self.slotsContainer = Flexlove.new({
      id = self.id.."_slots_container",
      width = slotsWidth,
      positioning = "flex",
      flexDirection = "horizontal",
      flexWrap = "wrap",
      gap = 0,
      parent = self.containerElement
   })

   self:createSlots()
end

function InventoryView:createSlots()
   local slots = self.inventory.slots

   for slotIndex = 1, #slots do
      local slot = slots[slotIndex]
      local slotElement = Flexlove.new({
         id = self.id.."_slot_"..slotIndex,
         width = self.slotSize,
         height = self.slotSize,
         backgroundColor = BACKGROUND_COLOR,
         border = self.borderWidth,
         borderColor = BORDER_COLOR,
         text = slot.itemId and string.sub(slot.itemId, 1, 1) or "",
         textColor = TEXT_COLOR,
         textSize = HEADER_SIZE,
         textAlign = "center",
         userdata = {
            slotIndex = slotIndex,
            view = self
         },
         onEvent = function(element, event)
            if event.type == "click" then
               local mx, my = love.mouse.getPosition()

               if self.id == "toolbar" and not InventoryStateManager.isOpen and not MachineStateManager.isOpen then
                  Beholder.trigger(Events.TOOLBAR_SLOT_ACTIVATED, slotIndex)
               else
                  Beholder.trigger(Events.INPUT_INVENTORY_CLICKED, mx, my, element.userdata)
               end
            end
         end,
         parent = self.slotsContainer
      })

      table.insert(self.slotElements, {
         element = slotElement,
         slotIndex = slotIndex,
      })
   end
end

function InventoryView:getInventory()
   return self.inventory
end

function InventoryView:draw()
   self:updateSlots()
end

function InventoryView:updateSlots()
   for _, slotData in ipairs(self.slotElements) do
      local slotIndex = slotData.slotIndex
      local element = slotData.element
      local slots = self.inventory.slots

      if slots and slots[slotIndex] then
         local slot = slots[slotIndex]
         local itemText = slot.itemId and string.sub(slot.itemId, 1, 1) or ""
         element:setText(itemText)

         -- Clear existing quantity labels
         element:clearChildren()

         -- Add quantity label if needed
         if slot.quantity and slot.quantity > 1 then
            Flexlove.new({
               id = self.id.."_qty_"..slotIndex.."_update",
               x = QUANTITY_OFFSET,
               y = QUANTITY_OFFSET,
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

function InventoryView:calculateBoxDimensions()
   return self.columns * self.slotSize + self.padding * 2, self.rows * self.slotSize + self.padding * 2
end

function InventoryView:getSlotPosition(slotIndex)
   local col = (slotIndex - 1) % self.columns
   local row = math.floor((slotIndex - 1) / self.columns)
   local x = math.floor(self.x + self.padding + col * self.slotSize)
   local y = math.floor(self.y + self.padding + row * self.slotSize)
   return x, y
end

function InventoryView:isPointInSlot(mx, my, slotX, slotY)
   return mx >= slotX and mx <= slotX + self.slotSize
      and my >= slotY and my <= slotY + self.slotSize
end

function InventoryView:getSlotUnderMouse(mx, my)
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

--- Destroy FlexLove elements when view is no longer needed
function InventoryView:destroy()
   if self.containerElement then
      self.containerElement:destroy()
      self.containerElement = nil
   end
   self.slotsContainer = nil
   self.slotElements = {}
end

return InventoryView
