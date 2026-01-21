local InventoryView = require("src.ui.inventory_view")
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
      themeComponent = "framev1",
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

   self.inputView = InventoryView:new(self.inputInventory, {
      id = self.id.."_input",
      inventoryType = "input",
      parentView = self,
      parentElement = self.slotsContainer,
      columns = #self.inputInventory.slots,
      rows = 1,
   })

   self.outputView = InventoryView:new(self.outputInventory, {
      id = self.id.."_output",
      inventoryType = "output",
      parentView = self,
      parentElement = self.slotsContainer,
      columns = #self.outputInventory.slots,
      rows = 1,
   })

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
      themeComponent = "buttonv1",
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
end

function MachineView:draw()
   self:updateMachineName()
   self:updateMachineState()
   self.inputView:draw()
   self.outputView:draw()
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

function MachineView:getSlotUnderMouse(mouseX, mouseY)
   -- Delegate to child inventory views
   local inputSlot = self.inputView:getSlotUnderMouse(mouseX, mouseY)
   if inputSlot then return inputSlot end

   local outputSlot = self.outputView:getSlotUnderMouse(mouseX, mouseY)
   if outputSlot then return outputSlot end

   return nil
end

function MachineView:destroy()
   if self.containerElement then
      self.containerElement:destroy()
   end
end

return MachineView
