local InventoryHelper = require("src.helpers.inventory_helper")
local InventoryActions = require("src.config.inventory_action_handlers")
local SlotViewManager = require("src.managers.slot_view_manager")
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
--- @field containerElement table FlexLove Element
--- @field slotElements table

--- @param inventory table
--- @param options table
function InventoryView:initialize(inventory, options)
   self.inventory = inventory
   options = options or {}
   self.id = options.id
   self.inventoryType = options.inventoryType
   self.parentView = options.parentView
   self.parentElement = options.parentElement -- FlexLove element to parent to
   self.x = math.floor(options.x or 0)
   self.y = math.floor(options.y or 0)
   self.columns = options.columns or UI.COLUMNS
   self.rows = options.rows or UI.INV_ROWS
   self.slotSize = options.slotSize or UI.SLOT_SIZE
   self.padding = options.padding or UI.PADDING
   self.borderWidth = UI.BORDER_WIDTH
   self.entityId = options.entityId or nil

   -- Double-click detection state
   self.lastClickTime = 0
   self.lastClickSlot = nil
   self.DOUBLE_CLICK_THRESHOLD = 0.3 -- seconds

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
      themeComponent = "framev5",
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
      userdata = {view = self},
      parent = self.parentElement -- Will be nil for standalone views
   })

   local slotsWidth = self.columns * self.slotSize
   local slotsHeight = self.rows * self.slotSize
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
   local slots = InventoryHelper.getSlots(self.inventory)
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
            view = self
         },
         onEvent = function(element, event)
            self:handleSlotClick(element, event)
            self:handleSlotHover(element, event)
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

   local button = event.button or 1
   local slotIndex = element.userdata.slotIndex

   if self.id == "toolbar" and not SlotViewManager.isOpen then
      trigger(Events.TOOLBAR_SLOT_ACTIVATED, slotIndex)
   else
      local modifiers = InventoryActions.getModifiers()

      -- Detect double-click (left button only)
      local currentTime = love.timer.getTime()
      if button == 1 then
         local timeSinceLastClick = currentTime - self.lastClickTime
         local sameSlot = self.lastClickSlot == slotIndex
         modifiers.isDoubleClick = sameSlot and timeSinceLastClick < self.DOUBLE_CLICK_THRESHOLD
         self.lastClickTime = currentTime
         self.lastClickSlot = slotIndex
      end

      local action = InventoryActions.getMouseAction(button, modifiers)
      if not action then return end

      local userdata = element.userdata
      userdata.action = action
      userdata.inventoryType = self.inventoryType

      trigger(Events.INPUT_INVENTORY_CLICKED, userdata)
   end
end

function InventoryView:handleSlotHover(element, event)
   if event.type ~= "hover" then return end

   local userdata = element.userdata
   userdata.inventoryType = self.inventoryType
   SlotViewManager.hoveredSlotUserData = userdata
end

function InventoryView:getInventory()
   return self.inventory
end

function InventoryView:draw()
   self:updateSlots()
end

function InventoryView:updateSlots()
   local slots = InventoryHelper.getSlots(self.inventory)
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

function InventoryView:getSlotUnderMouse(mx, my)
   local element = Flexlove.getElementAtPosition(mx, my)

   if element and element.userdata and element.userdata.view == self then
      local slotIndex = element.userdata.slotIndex

      if slotIndex then
         local slots = InventoryHelper.getSlots(self.inventory)
         if slots and slots[slotIndex] then
            return {
               view = self,
               slotIndex = slotIndex,
               slot = slots[slotIndex],
               inventoryType = self.inventoryType,
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
