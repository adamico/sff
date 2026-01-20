local InventoryHelper = require("src.helpers.inventory_helper")
local InventoryInputHandler = require("src.ui.inventory_input_handler")
local UI = require("src.config.ui_constants")

local MachineView = Class("MachineView")
local get = Evolved.get
local trigger = Beholder.trigger

local BACKGROUND_COLOR = Color.new(unpack(UI.BACKGROUND_COLOR))
local BORDER_COLOR = Color.new(unpack(UI.BORDER_COLOR))
local BORDER_WIDTH = UI.BORDER_WIDTH
local BUTTON_BACKGROUND_COLOR = Color.new(unpack(UI.BUTTON_BACKGROUND_COLOR))
local HEADER_TEXT_SIZE = UI.HEADER_TEXT_SIZE
local MANA_BACKGROUND_COLOR = Color.new(unpack(UI.MANA_BACKGROUND_COLOR))
local MANA_FILL_COLOR = Color.new(unpack(UI.MANA_FILL_COLOR))
local PROGRESS_BACKGROUND_COLOR = Color.new(unpack(UI.PROGRESS_BACKGROUND_COLOR))
local PROGRESS_FILL_COLOR = Color.new(unpack(UI.PROGRESS_FILL_COLOR))
local RITUAL_BUTTON_LABEL = "Start Ritual"
local SLOT_SIZE = UI.SLOT_SIZE
local TEXT_COLOR = Color.new(unpack(UI.TEXT_COLOR))
local TEXT_SIZE = UI.TEXT_SIZE
local QUANTITY_OFFSET = UI.QUANTITY_OFFSET

--- @class MachineView
--- @field entityId number
--- @field containerElement table FlexLove Element
--- @field inputInventory table The input inventory
--- @field outputInventory table The output inventory

--- @param options table
function MachineView:initialize(options)
   options = options or {}
   self.id = options.id
   self.borderWidth = BORDER_WIDTH
   self.entityId = options.entityId or nil
   self.padding = options.padding or 8
   self.slotSize = options.slotSize or SLOT_SIZE
   self.width = options.width or WIDTH
   self.x = math.floor(options.x or 0)
   self.y = math.floor(options.y or 0)

   -- Fetch inventories from entity
   self.inputInventory = get(self.entityId, FRAGMENTS.InputInventory)
   self.outputInventory = get(self.entityId, FRAGMENTS.OutputInventory)

   -- FlexLove element references
   self.containerElement = nil
   self.footerContainer = nil
   self.inputSlotElements = {}
   self.outputSlotElements = {}
   self.manaBarFill = nil
   self.manaLabel = nil
   self.nameLabel = nil
   self.progressBarFill = nil
   self.slotsContainer = nil
   self.startButton = nil
   self.stateLabel = nil

   self:buildUI()
end

function MachineView:buildUI()
   self.containerElement = Flexlove.new({
      id = self.id.."_container",
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
      userdata = {view = self}
   })

   self:createHeader()

   self.slotsContainer = Flexlove.new({
      flexDirection = "horizontal",
      justifyContent = "space-between",
      parent = self.containerElement,
      positioning = "flex",
   })

   self:createInputSlots()
   self:createOutputSlots()
   self:createManaBar()
   self:createProgressBar()
   self:createFooter()
end

function MachineView:createHeader()
   local header = Flexlove.new({
      flexDirection = "horizontal",
      parent = self.containerElement,
      justifyContent = "space-between",
      positioning = "flex",
   })

   self:createNameLabel(header)
   self:createRecipeLabel(header)
end

function MachineView:createRecipeLabel(parent)
   local recipe = self:getRecipe()
   if recipe then
      self.recipeLabel = Flexlove.new({
         id = "machine_recipe",
         parent = parent,
         text = recipe.name,
         textColor = TEXT_COLOR,
         textSize = HEADER_TEXT_SIZE,
      })
   end
end

function MachineView:createNameLabel(parent)
   local name = self:getName()
   if name then
      self.nameLabel = Flexlove.new({
         id = "machine_name",
         parent = parent,
         text = name,
         textColor = TEXT_COLOR,
         textSize = HEADER_TEXT_SIZE,
      })
   end
end

function MachineView:createInputSlots()
   local inventory = self.inputInventory
   if not inventory then return end

   local slots = InventoryHelper.getSlots(inventory)
   if not slots then return end

   local inputContainer = Flexlove.new({
      id = self.id.."_input_container",
      flexDirection = "horizontal",
      parent = self.slotsContainer,
      positioning = "flex",
   })

   for slotIndex, slot in ipairs(slots) do
      local slotElement = Flexlove.new({
         id = self.id.."_input_slot_"..slotIndex,
         width = self.slotSize,
         height = self.slotSize,
         backgroundColor = BACKGROUND_COLOR,
         border = self.borderWidth,
         borderColor = BORDER_COLOR,
         text = slot.itemId and string.sub(slot.itemId, 1, 1) or "",
         textColor = TEXT_COLOR,
         textSize = HEADER_TEXT_SIZE,
         textAlign = "center",
         userdata = {
            slotIndex = slotIndex,
            inventoryType = "input",
            slotPosition = Vector(slotElement and slotElement.x or 0, slotElement and slotElement.y or 0),
            view = self
         },
         onEvent = function(element, event)
            self:handleSlotClick(element, event)
         end,
         parent = inputContainer
      })

      table.insert(self.inputSlotElements, {
         element = slotElement,
         slotIndex = slotIndex,
      })
   end
end

function MachineView:createOutputSlots()
   local inventory = self.outputInventory
   if not inventory then return end

   local slots = InventoryHelper.getSlots(inventory)
   if not slots then return end

   local outputContainer = Flexlove.new({
      id = self.id.."_output_container",
      flexDirection = "horizontal",
      parent = self.slotsContainer,
      positioning = "flex",
   })

   for slotIndex, slot in ipairs(slots) do
      local slotElement = Flexlove.new({
         id = self.id.."_output_slot_"..slotIndex,
         width = self.slotSize,
         height = self.slotSize,
         backgroundColor = BACKGROUND_COLOR,
         border = self.borderWidth,
         borderColor = BORDER_COLOR,
         text = slot.itemId and string.sub(slot.itemId, 1, 1) or "",
         textColor = TEXT_COLOR,
         textSize = HEADER_TEXT_SIZE,
         textAlign = "center",
         userdata = {
            slotIndex = slotIndex,
            inventoryType = "output",
            view = self
         },
         onEvent = function(element, event)
            self:handleSlotClick(element, event)
         end,
         parent = outputContainer
      })

      table.insert(self.outputSlotElements, {
         element = slotElement,
         slotIndex = slotIndex,
      })
   end
end

function MachineView:handleSlotClick(element, event)
   if event.type ~= "click" and event.type ~= "rightclick" then return end

   local mx, my = love.mouse.getPosition()
   local button = event.button or 1
   local slotIndex = element.userdata.slotIndex
   local inventoryType = element.userdata.inventoryType
   local modifiers = InventoryInputHandler.getModifiers()
   local action = InventoryInputHandler.getAction(button, modifiers)
   if not action then return end

   trigger(Events.INPUT_INVENTORY_CLICKED, mx, my, {
      action = action,
      slotIndex = slotIndex,
      inventoryType = inventoryType,
      view = self
   })
end

function MachineView:createManaBar()
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

function MachineView:setManaBarFill(mana)
   local fillRatio = mana.current / mana.max
   self.manaBarFill.width = self.manaBarContainer.width * fillRatio
   self.manaBarFill._borderBoxWidth = nil
end

function MachineView:createProgressBar()
   if not self.entityId then return end

   local processingTimer = get(self.entityId, FRAGMENTS.ProcessingTimer)
   local recipe = get(self.entityId, FRAGMENTS.CurrentRecipe)

   if not processingTimer or not recipe or not recipe.processingTime then return end
   if recipe.processingTime <= 0 then return end

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

function MachineView:setProgressBarFill(recipe, processingTimer)
   local fillRatio = (recipe.processingTime - processingTimer.current) / recipe.processingTime
   self.progressBarFill.width = self.progressBarContainer.width * fillRatio
   self.progressBarFill._borderBoxWidth = nil
end

function MachineView:createFooter()
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
         local name, fsm, recipe, processingTimer = get(self.entityId,
            Evolved.NAME,
            FRAGMENTS.StateMachine,
            FRAGMENTS.CurrentRecipe,
            FRAGMENTS.ProcessingTimer
         )
         if event.type == "click" then
            trigger(Events.RITUAL_STARTED, {
               entityId = self.entityId,
               machineName = (name or "Machine")..self.entityId,
               fsm = fsm,
               recipe = recipe,
               processingTimer = processingTimer,
            })
         end
      end
   })
end

function MachineView:getInventory(inventoryType)
   if inventoryType == "input" then
      return self.inputInventory
   elseif inventoryType == "output" then
      return self.outputInventory
   end
   return nil
end

function MachineView:draw()
   self:updateMachineName()
   self:updateMachineState()
   self:updateInputSlots()
   self:updateOutputSlots()
   self:updateManaBar()
   self:updateProgressBar()
   self:updateStartButton()
end

function MachineView:updateMachineName()
   if self.nameLabel then
      local name = self:getName()
      if name then
         self.nameLabel:setText(name)
      end
   end
end

function MachineView:updateMachineState()
   if self.stateLabel then
      local state = self:getCurrentState()
      if state then
         self.stateLabel:setText(state)
      end
   end
end

function MachineView:updateStartButton()
   if not self.startButton or not self.entityId then return end

   local state = self:getCurrentState()
   local shouldDisable = state == "working" or state == "noMana" or state == "blocked"
   self.startButton.disabled = shouldDisable
end

function MachineView:updateInputSlots()
   local inventory = self.inputInventory
   if not inventory then return end

   local slots = InventoryHelper.getSlots(inventory)
   if not slots then return end

   for _, slotData in ipairs(self.inputSlotElements) do
      local slotIndex = slotData.slotIndex
      local element = slotData.element
      local slot = slots[slotIndex]

      if slot then
         local itemText = slot.itemId and string.sub(slot.itemId, 1, 1) or ""
         element:setText(itemText)
         element:clearChildren()

         if slot.quantity and slot.quantity > 1 then
            Flexlove.new({
               id = "machine_input_qty_"..slotIndex.."_update",
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

function MachineView:updateOutputSlots()
   local inventory = self.outputInventory
   if not inventory then return end

   local slots = InventoryHelper.getSlots(inventory)
   if not slots then return end

   for _, slotData in ipairs(self.outputSlotElements) do
      local slotIndex = slotData.slotIndex
      local element = slotData.element
      local slot = slots[slotIndex]

      if slot then
         local itemText = slot.itemId and string.sub(slot.itemId, 1, 1) or ""
         element:setText(itemText)
         element:clearChildren()

         if slot.quantity and slot.quantity > 1 then
            Flexlove.new({
               id = "machine_output_qty_"..slotIndex.."_update",
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

function MachineView:updateManaBar()
   if not self.entityId or not self.manaBarFill or not self.manaLabel then return end

   local mana = get(self.entityId, FRAGMENTS.Mana)
   if not mana then return end

   self:setManaBarFill(mana)
   self.manaLabel:setText(string.format("Mana: %d/%d", mana.current, mana.max))
end

function MachineView:updateProgressBar()
   if not self.entityId or not self.progressBarFill then return end

   local processingTimer = get(self.entityId, FRAGMENTS.ProcessingTimer)
   local recipe = get(self.entityId, FRAGMENTS.CurrentRecipe)

   if not processingTimer or not recipe or not recipe.processingTime then return end
   if recipe.processingTime <= 0 then return end

   self:setProgressBarFill(recipe, processingTimer)
end

function MachineView:getName()
   return self.entityId and get(self.entityId, Evolved.NAME) or nil
end

function MachineView:getRecipe()
   return self.entityId and get(self.entityId, FRAGMENTS.CurrentRecipe) or nil
end

function MachineView:getCurrentState()
   if not self.entityId then return nil end

   local stateMachine = get(self.entityId, FRAGMENTS.StateMachine)
   if stateMachine then
      return stateMachine.current
   end

   return nil
end

function MachineView:isPointInSlot(mouseX, mouseY, slotX, slotY)
   return mouseX >= slotX and mouseX <= slotX + self.slotSize
      and mouseY >= slotY and mouseY <= slotY + self.slotSize
end

function MachineView:getSlotUnderMouse(mouseX, mouseY)
   local element = Flexlove.getElementAtPosition(mouseX, mouseY)

   if element and element.userdata and element.userdata.view == self then
      local slotIndex = element.userdata.slotIndex
      local inventoryType = element.userdata.inventoryType

      if slotIndex and inventoryType then
         local inventory = self:getInventory(inventoryType)
         if inventory then
            local slots = InventoryHelper.getSlots(inventory)
            if slots and slots[slotIndex] then
               return {
                  view = self,
                  slotIndex = slotIndex,
                  slot = slots[slotIndex],
                  inventoryType = inventoryType
               }
            end
         end
      end
   end

   return nil
end

function MachineView:destroy()
   if self.containerElement then
      self.containerElement:destroy()
   end
end

return MachineView
