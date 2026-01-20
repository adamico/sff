local InventoryHelper = require("src.helpers.inventory_helper")
local InventoryInputHandler = require("src.ui.inventory_input_handler")
local InventoryViewManager = require("src.managers.inventory_view_manager")
local MachineViewManager = require("src.managers.machine_view_manager")
local UI = require("src.config.ui_constants")

local trigger = Beholder.trigger

local InventoryView = Class("InventoryView")

local BACKGROUND_COLOR = Color.new(unpack(UI.BACKGROUND_COLOR))
local BORDER_COLOR = Color.new(unpack(UI.BORDER_COLOR))
local TEXT_COLOR = Color.new(unpack(UI.TEXT_COLOR))

--- @class InventoryView
--- @field x number
--- @field y number
--- @field width number
--- @field height number
--- @field inventory table
--- @field slotType string|nil The slot type to display (nil defaults to "default")
--- @field containerElement table FlexLove Element
--- @field slotElements table

--- @param inventory table
--- @param options table
function InventoryView:initialize(inventory, options)
   self.inventory = inventory
   options = options or {}
   self.id = options.id
   self.slotType = options.slotType or "default"
   self.x = math.floor(options.x or 0)
   self.y = math.floor(options.y or 0)
   self.columns = options.columns or UI.COLUMNS
   self.rows = options.rows or UI.INV_ROWS
   self.slotSize = options.slotSize or UI.SLOT_SIZE
   self.padding = options.padding or UI.PADDING
   self.borderWidth = UI.BORDER_WIDTH
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
      flexDirection = "horizontal",
      justifyContent = "center",
      alignItems = "center",
      padding = {
         top = self.padding,
         right = self.padding,
         bottom = self.padding,
         left = self.padding
      },
      positioning = "flex",
      userdata = {view = self}
   })

   local slotsWidth = self.columns * self.slotSize
   local slotsHeight = self.rows * self.slotSize -- Explicit height for proper centering
   self.slotsContainer = Flexlove.new({
      id = self.id.."_slots_container",
      width = slotsWidth,
      height = slotsHeight,
      positioning = "flex",
      flexDirection = "horizontal",
      flexWrap = "wrap",
      gap = 0,
      parent = self.containerElement
   })

   self:createSlots()
end

function InventoryView:createSlots()
   local slots = InventoryHelper.getSlots(self.inventory, self.slotType)
   if not slots then return end

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
         textSize = UI.HEADER_TEXT_SIZE,
         textAlign = "center",
         userdata = {
            slotIndex = slotIndex,
            slotType = self.slotType,
            view = self
         },
         onEvent = function(element, event)
            self:handleSlotClick(element, event)
         end,
         parent = self.slotsContainer
      })

      table.insert(self.slotElements, {
         element = slotElement,
         slotIndex = slotIndex,
      })
   end
end

function InventoryView:handleSlotClick(element, event)
   if event.type ~= "click" and event.type ~= "rightclick" then return end

   local mx, my = love.mouse.getPosition()
   local button = event.button or 1
   local slotIndex = element.userdata.slotIndex

   if self.id == "toolbar" and not InventoryViewManager.isOpen
      and not MachineViewManager.isOpen then
      trigger(Events.TOOLBAR_SLOT_ACTIVATED, slotIndex)
   else
      local modifiers = InventoryInputHandler.getModifiers()
      local action = InventoryInputHandler.getAction(button, modifiers)
      if not action then return end

      trigger(Events.INPUT_INVENTORY_CLICKED, mx, my, {
         action = action,
         slotIndex = slotIndex,
         slotType = self.slotType,
         view = self
      })
   end
end

function InventoryView:getInventory()
   return self.inventory
end

function InventoryView:getSlotType()
   return self.slotType
end

function InventoryView:draw()
   self:updateSlots()
end

function InventoryView:updateSlots()
   local slots = InventoryHelper.getSlots(self.inventory, self.slotType)
   if not slots then return end

   for _, slotData in ipairs(self.slotElements) do
      local slotIndex = slotData.slotIndex
      local element = slotData.element

      if slots[slotIndex] then
         local slot = slots[slotIndex]
         local itemText = slot.itemId and string.sub(slot.itemId, 1, 1) or ""
         element:setText(itemText)

         -- Clear existing quantity labels
         element:clearChildren()

         -- Add quantity label if needed
         if slot.quantity and slot.quantity > 1 then
            Flexlove.new({
               id = self.id.."_qty_"..slotIndex.."_update",
               x = UI.QUANTITY_OFFSET,
               y = UI.QUANTITY_OFFSET,
               text = tostring(slot.quantity),
               textColor = TEXT_COLOR,
               textSize = UI.TEXT_SIZE,
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
         local slots = InventoryHelper.getSlots(self.inventory, self.slotType)
         if slots and slots[slotIndex] then
            return {
               view = self,
               slotIndex = slotIndex,
               slotType = self.slotType,
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
