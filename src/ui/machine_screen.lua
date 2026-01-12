local InventoryHelper = require("src.helpers.inventory_helper")
local MachineScreen = Class("MachineScreen")
local get = Evolved.get

local BACKGROUND_COLOR = Color.new(0.5, 0.45, 0.5)
local BORDER_COLOR = Color.new(1, 1, 1, 1)
local BORDER_WIDTH = 2
local BUTTON_BACKGROUND_COLOR = Color.new(0.2, 0.2, 0.2)
local HEADER_TEXT_SIZE = 14
local MANA_BACKGROUND_COLOR = Color.new(0.2, 0.2, 0.3)
local MANA_FILL_COLOR = Color.new(0.3, 0.5, 0.9)
local PROGRESS_BACKGROUND_COLOR = Color.new(0.2, 0.2, 0.2)
local PROGRESS_FILL_COLOR = Color.new(0.2, 0.8, 0.9)
local QUANTITY_OFFSET = 18
local RITUAL_BUTTON_LABEL = "Start Ritual"
local SLOT_SIZE = 32
local TEXT_COLOR = Color.new(1, 1, 1, 1)
local TEXT_SIZE = 12

--- @class MachineScreen
--- @field borderWidth number
--- @field containerElement table FlexLove Element
--- @field entityId number
--- @field height number
--- @field manaBarFill table FlexLove Element
--- @field manaLabel table FlexLove Element
--- @field nameLabel table FlexLove Element
--- @field padding number
--- @field slotElements table
--- @field slotSize number
--- @field startButton table FlexLove Element
--- @field stateLabel table FlexLove Element
--- @field width number
--- @field x number
--- @field y number

--- @param options table
function MachineScreen:initialize(options)
   options = options or {}
   self.borderWidth = BORDER_WIDTH
   self.entityId = options.entityId or nil
   self.padding = options.padding or 8
   self.slotSize = options.slotSize or SLOT_SIZE
   self.width = options.width or WIDTH
   self.x = math.floor(options.x or 0)
   self.y = math.floor(options.y or 0)

   -- FlexLove element references
   self.containerElement = nil
   self.footerContainer = nil
   self.manaBarFill = nil
   self.manaLabel = nil
   self.nameLabel = nil
   self.progressBarFill = nil
   self.slotElements = {}
   self.slotsContainer = nil
   self.startButton = nil
   self.stateLabel = nil

   self:buildUI()
end

function MachineScreen:buildUI()
   self.containerElement = Flexlove.new({
      id = "machine_screen_container",
      x = self.x,
      y = self.y,
      width = self.width,
      backgroundColor = BACKGROUND_COLOR,
      border = self.borderWidth,
      borderColor = BORDER_COLOR,
      flexDirection = "vertical",
      padding = {
         top = self.padding,
         right = self.padding,
         bottom = self.padding,
         left = self.padding
      },
      gap = 10,
      positioning = "flex",
      userdata = {screen = self}
   })

   self:createHeader()
   self:createSlots()
   self:createManaBar()
   self:createProgressBar()
   self:createFooter()
end

function MachineScreen:createHeader()
   local name = self:getName()

   local header = Flexlove.new({
      flexDirection = "horizontal",
      parent = self.containerElement,
      positioning = "flex",
   })

   if name then
      self.nameLabel = Flexlove.new({
         id = "machine_name",
         parent = header,
         text = name,
         textColor = TEXT_COLOR,
         textSize = HEADER_TEXT_SIZE,
      })
   end
end

function MachineScreen:createSlots()
   local inventory = self:getInventory()
   if not inventory then return end

   self.slotsContainer = Flexlove.new({
      flexDirection = "horizontal",
      justifyContent = "space-between",
      parent = self.containerElement,
      positioning = "flex",
   })

   local definedSlots = {
      {type = "input",  slots = inventory.input_slots},
      {type = "output", slots = inventory.output_slots}
   }

   for _, typeSlotPair in ipairs(definedSlots) do
      local slotType = typeSlotPair.type
      local slotTypeContainer = Flexlove.new({
         flexDirection = "horizontal",
         parent = self.slotsContainer,
         positioning = "flex",
      })

      for slotIndex, slot in ipairs(typeSlotPair.slots) do
         local slotElement = Flexlove.new({
            id = "machine_slot_"..slotType.."_"..slotIndex,
            width = self.slotSize,
            height = self.slotSize,
            backgroundColor = BACKGROUND_COLOR,
            border = self.borderWidth,
            borderColor = BORDER_COLOR,
            text = slot.item_id and string.sub(slot.item_id, 1, 1) or "",
            textColor = TEXT_COLOR,
            textSize = HEADER_TEXT_SIZE,
            textAlign = "center",
            userdata = {},
            onEvent = function(element, event)
               if event.type == "click" then
                  local mx, my = love.mouse.getPosition()
                  Beholder.trigger(Events.INPUT_INVENTORY_CLICKED, mx, my, element.userdata)
               end
            end,
            parent = slotTypeContainer
         })
         slotElement.userdata = {
            slotIndex = slotIndex,
            slotType = slotType,
            slotPosition = Vector(slotElement.x, slotElement.y),
            screen = self
         }
      end
   end
end

function MachineScreen:createManaBar()
   if not self.entityId then return end

   local mana = get(self.entityId, FRAGMENTS.Mana)
   if not mana then return end

   self.manaLabel = Flexlove.new({
      id = "mana_label",
      parent = self.containerElement,
      text = string.format("Mana: %d/%d", mana.current, mana.max),
      textColor = TEXT_COLOR,
      textSize = TEXT_SIZE,
   })

   self.manaBarContainer = Flexlove.new({
      backgroundColor = MANA_BACKGROUND_COLOR,
      height = "2vh",
      id = "mana_bar",
      parent = self.containerElement,
      positioning = "relative",
      width = "100%",
   })

   self.manaBarFill = Flexlove.new({
      id = "mana_bar_fill",
      backgroundColor = MANA_FILL_COLOR,
      parent = self.manaBarContainer,
   })

   self:setManaBarFill(mana)
end

function MachineScreen:setManaBarFill(mana)
   local fillRatio = mana.current / mana.max
   self.manaBarFill.width = self.manaBarContainer.width * fillRatio
   self.manaBarFill._borderBoxWidth = nil
end

function MachineScreen:createProgressBar()
   if not self.entityId then return end

   local processingTimer = get(self.entityId, FRAGMENTS.ProcessingTimer)
   local recipe = get(self.entityId, FRAGMENTS.CurrentRecipe)

   if not processingTimer or not recipe or not recipe.processing_time then return end
   if recipe.processing_time <= 0 then return end

   self.progressBarContainer = Flexlove.new({
      backgroundColor = PROGRESS_BACKGROUND_COLOR,
      height = "2vh",
      id = "progress_bar_bg",
      parent = self.containerElement,
      positioning = "relative",
      width = "100%",
   })

   self.progressBarFill = Flexlove.new({
      id = "progress_bar_fill",
      backgroundColor = PROGRESS_FILL_COLOR,
      parent = self.progressBarContainer
   })

   self:setProgressBarFill(recipe, processingTimer)
end

function MachineScreen:setProgressBarFill(recipe, processingTimer)
   local fillRatio = (recipe.processing_time - processingTimer.current) / recipe.processing_time
   self.progressBarFill.width = self.progressBarContainer.width * fillRatio
   self.progressBarFill._borderBoxWidth = nil
end

function MachineScreen:createFooter()
   self.footerContainer = Flexlove.new({
      id = "button_container",
      width = "100%",
      positioning = "flex",
      flexDirection = "horizontal",
      justifyContent = "space-between",
      parent = self.containerElement,
   })

   local state = self:getCurrentState()
   if not state then return end

   self.stateLabel = Flexlove.new({
      id = "state_label",
      parent = self.footerContainer,
      text = state,
      textColor = TEXT_COLOR,
      textSize = HEADER_TEXT_SIZE,
   })

   self.startButton = Flexlove.new({
      id = "start_button",
      backgroundColor = BUTTON_BACKGROUND_COLOR,
      text = RITUAL_BUTTON_LABEL,
      textColor = TEXT_COLOR,
      textSize = TEXT_SIZE,
      textAlign = "center",
      padding = 4,
      parent = self.footerContainer,
      onEvent = function(element, event)
         if event.type == "click" then
            -- Handle button click
            -- This would trigger the machine start logic
         end
      end
   })
end

function MachineScreen:getInventory()
   if not self.entityId then return nil end

   return get(self.entityId, FRAGMENTS.Inventory)
end

function MachineScreen:draw()
   self:updateMachineName()
   self:updateMachineState()
   self:updateSlots()
   self:updateManaBar()
   self:updateProgressBar()
end

function MachineScreen:updateMachineName()
   if self.nameLabel then
      local name = self:getName()
      if name then
         self.nameLabel:setText(name)
      end
   end
end

function MachineScreen:updateMachineState()
   if self.stateLabel then
      local state = self:getCurrentState()
      if state then
         self.stateLabel:setText(state)
      end
   end
end

function MachineScreen:updateSlots()
   local inventory = self:getInventory()
   if not inventory then return end

   for _, slotTypeContainer in ipairs(self.slotsContainer.children) do
      for _, slotElement in ipairs(slotTypeContainer.children) do
         local slotData = slotElement.userdata
         local slotIndex = slotData.slotIndex
         local slotType = slotData.slotType
         local element = slotElement
         local slot = InventoryHelper.getSlot(inventory, slotIndex, slotType)

         if slot then
            local itemText = slot.item_id and string.sub(slot.item_id, 1, 1) or ""
            element:setText(itemText)

            -- Clear existing quantity labels
            element:clearChildren()

            -- Add quantity label if needed
            if slot.quantity and slot.quantity > 1 then
               Flexlove.new({
                  id = "machine_qty_"..slotType.."_"..slotIndex.."_update",
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
end

function MachineScreen:updateManaBar()
   if not self.entityId or not self.manaBarFill or not self.manaLabel then return end

   local mana = get(self.entityId, FRAGMENTS.Mana)
   if not mana then return end

   self:setManaBarFill(mana)
   self.manaLabel:setText(string.format("Mana: %d/%d", mana.current, mana.max))
end

function MachineScreen:updateProgressBar()
   if not self.entityId or not self.progressBarFill then return end

   local processingTimer = get(self.entityId, FRAGMENTS.ProcessingTimer)
   local recipe = get(self.entityId, FRAGMENTS.CurrentRecipe)

   if not processingTimer or not recipe or not recipe.processing_time then return end
   if recipe.processing_time <= 0 then return end

   self:setProgressBarFill(recipe, processingTimer)
end

function MachineScreen:getName()
   return self.entityId and get(self.entityId, Evolved.NAME) or nil
end

function MachineScreen:getCurrentState()
   if not self.entityId then return nil end

   local stateMachine = get(self.entityId, FRAGMENTS.StateMachine)
   if stateMachine then
      return stateMachine.current
   end

   return nil
end

function MachineScreen:isPointInSlot(mouseX, mouseY, slotX, slotY)
   return mouseX >= slotX and mouseX <= slotX + self.slotSize
      and mouseY >= slotY and mouseY <= slotY + self.slotSize
end

function MachineScreen:getSlotUnderMouse(mouseX, mouseY)
   local element = Flexlove.getElementAtPosition(mouseX, mouseY)

   if element and element.userdata and element.userdata.screen == self then
      local slotIndex = element.userdata.slotIndex
      local slotType = element.userdata.slotType

      if slotIndex and slotType then
         local inventory = self:getInventory()
         if inventory then
            local slots = inventory[slotType.."_slots"]
            if slots and slots[slotIndex] then
               return {
                  screen = self,
                  slotIndex = slotIndex,
                  slotPosition = element.userdata.slotPosition,
                  slot = slots[slotIndex],
                  slotType = slotType
               }
            end
         end
      end
   end

   return nil
end

function MachineScreen:destroy()
   if self.containerElement then
      self.containerElement:destroy()
   end
end

return MachineScreen
