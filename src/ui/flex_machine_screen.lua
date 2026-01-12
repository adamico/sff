local InventoryHelper = require("src.helpers.inventory_helper")
local FlexMachineScreen = Class("FlexMachineScreen")
local get = Evolved.get

local BACKGROUND_COLOR = Color.new(0.5, 0.45, 0.5)
local BORDER_COLOR = Color.new(1, 1, 1, 1)
local BORDER_WIDTH = 2
local BUTTON_BACKGROUND_COLOR = Color.new(0.2, 0.2, 0.2)
local HEADER_TEXT_SIZE = 14
local HEIGHT = 200
local MANA_BACKGROUND_COLOR = Color.new(0.2, 0.2, 0.3)
local MANA_FILL_COLOR = Color.new(0.3, 0.5, 0.9)
local PADDING = 8
local PROGRESS_BACKGROUND_COLOR = Color.new(0.2, 0.2, 0.2)
local PROGRESS_FILL_COLOR = Color.new(0.2, 0.8, 0.3)
local RITUAL_BUTTON_LABEL = "Start Ritual"
local SLOT_SIZE = 32
local TEXT_COLOR = Color.new(1, 1, 1, 1)
local TEXT_SIZE = 12
local WIDTH = 300

--- @class FlexMachineScreen
--- @field borderWidth number
--- @field containerElement table FlexLove Element
--- @field entityId number
--- @field headerElement table FlexLove Element
--- @field height number
--- @field manaBarContainer table FlexLove Element
--- @field manaBarFill table FlexLove Element
--- @field manaLabel table FlexLove Element
--- @field nameLabel table FlexLove Element
--- @field padding number
--- @field progressBarContainer table FlexLove Element
--- @field progressBarFill table FlexLove Element
--- @field slotElements table
--- @field slotSize number
--- @field startButton table FlexLove Element
--- @field stateLabel table FlexLove Element
--- @field width number
--- @field x number
--- @field y number

--- @param options table
function FlexMachineScreen:initialize(options)
   options = options or {}
   self.borderWidth = BORDER_WIDTH
   self.entityId = options.entityId or nil
   self.height = options.height or HEIGHT
   self.padding = options.padding or PADDING
   self.slotSize = options.slotSize or SLOT_SIZE
   self.width = options.width or WIDTH
   self.x = math.floor(options.x or 0)
   self.y = math.floor(options.y or 0)

   -- Slot layout configuration (can be provided or will be computed lazily)
   -- Format: {type = "input", positions = {{x = 10, y = 20}, ...}}
   self.customSlotLayout = options.slotLayout or nil
   self._cachedLayout = nil

   -- FlexLove element references
   self.containerElement = nil
   self.headerElement = nil
   self.nameLabel = nil
   self.stateLabel = nil
   self.slotsContainer = nil
   self.manaBarContainer = nil
   self.manaBarFill = nil
   self.manaLabel = nil
   self.progressBarContainer = nil
   self.progressBarFill = nil
   self.startButton = nil
   self.slotElements = {}

   -- Build the UI
   self:buildUI()
end

--- Get the slot layout (lazily computed if not provided)
--- @return table The slot layout
function FlexMachineScreen:getSlotLayout()
   -- If a custom layout was provided, use it
   if self.customSlotLayout then
      return self.customSlotLayout
   end

   -- Lazily create default layout if not cached
   if not self._cachedLayout then
      self._cachedLayout = self:createDefaultLayout()
   end

   return self._cachedLayout
end

--- Create a default slot layout based on entity inventory
--- @return table The default slot layout
function FlexMachineScreen:createDefaultLayout()
   local inventory = self:getInventory()
   if not inventory then return {} end

   local layout = {}
   local startY = self.padding + 20 -- Leave room for state text

   -- Input slots on the left
   local maxInput = inventory.max_input_slots or 0
   if maxInput > 0 then
      local inputPositions = {}
      for i = 1, maxInput do
         local row = math.floor((i - 1) / 3)
         local col = (i - 1) % 3
         table.insert(inputPositions, {
            x = math.floor(self.padding + col * (self.slotSize + 4)),
            y = math.floor(startY + row * (self.slotSize + 4))
         })
      end
      table.insert(layout, {type = "input", positions = inputPositions})
   end

   -- Output slots on the right
   local maxOutput = inventory.max_output_slots or 0
   if maxOutput > 0 then
      local outputPositions = {}
      local outputStartX = self.width - self.padding - self.slotSize
      for i = 1, maxOutput do
         local row = math.floor((i - 1) / 2)
         local col = (i - 1) % 2
         table.insert(outputPositions, {
            x = math.floor(outputStartX - col * (self.slotSize + 4)),
            y = math.floor(startY + row * (self.slotSize + 4))
         })
      end
      table.insert(layout, {type = "output", positions = outputPositions})
   end

   return layout
end

function FlexMachineScreen:buildUI()
   -- Main container panel
   self.containerElement = Flexlove.new({
      id = "machine_screen_container",
      x = math.floor(self.x),
      y = math.floor(self.y),
      width = self.width,
      height = self.height,
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
      userdata = {screen = self}
   })

   -- Header area (machine name and state)
   self:createHeader()

   -- Slots area
   self:createSlots()

   -- Mana bar
   self:createManaBar()

   -- Progress bar
   self:createProgressBar()

   -- Start button
   self:createStartButton()
end

function FlexMachineScreen:createHeader()
   local name = self:getName()
   local state = self:getCurrentState()

   -- Machine name
   if name then
      self.nameLabel = Flexlove.new({
         id = "machine_name",
         x = math.floor(self.padding),
         y = math.floor(self.padding),
         text = name,
         textColor = TEXT_COLOR,
         textSize = HEADER_TEXT_SIZE,
         positioning = "absolute",
         parent = self.containerElement
      })
   end

   -- Machine state
   if state then
      self.stateLabel = Flexlove.new({
         id = "machine_state",
         x = math.floor(self.width - self.padding - 60), -- Approximate width
         y = math.floor(self.padding),
         text = state,
         textColor = TEXT_COLOR,
         textSize = HEADER_TEXT_SIZE,
         positioning = "absolute",
         parent = self.containerElement
      })
   end
end

function FlexMachineScreen:createSlots()
   local inventory = self:getInventory()
   if not inventory then return end

   local slotLayout = self:getSlotLayout()
   if not slotLayout or #slotLayout == 0 then return end

   for _, layoutGroup in ipairs(slotLayout) do
      local slotType = layoutGroup.type
      local positions = layoutGroup.positions
      local slots = InventoryHelper.getSlots(inventory, slotType)

      if slots and positions then
         for slotIndex = 1, #positions do
            local pos = positions[slotIndex]
            local slot = slots[slotIndex] or {}
            -- pos.x and pos.y are already relative to container
            local slotX = math.floor(pos.x)
            local slotY = math.floor(pos.y)

            -- Create slot element
            local slotElement = Flexlove.new({
               id = "machine_slot_"..slotType.."_"..slotIndex,
               x = slotX,
               y = slotY,
               width = self.slotSize,
               height = self.slotSize,
               backgroundColor = BACKGROUND_COLOR,
               border = self.borderWidth,
               borderColor = BORDER_COLOR,
               text = slot.item_id and string.sub(slot.item_id, 1, 1) or "",
               textColor = TEXT_COLOR,
               textSize = HEADER_TEXT_SIZE,
               textAlign = "center",
               positioning = "absolute",
               userdata = {
                  slotIndex = slotIndex,
                  slotType = slotType,
                  slotPosition = Vector(self.x + slotX, self.y + slotY),
                  screen = self
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
               slotType = slotType
            })

            -- Quantity label will be added by updateSlots()
         end
      end
   end
end

function FlexMachineScreen:createManaBar()
   if not self.entityId then return end

   local mana = get(self.entityId, FRAGMENTS.Mana)
   if not mana then return end

   local barWidth = self.width - self.padding * 2
   local barHeight = 8
   local barX = self.padding
   local barY = self.height - self.padding - barHeight - 48

   -- Mana label
   self.manaLabel = Flexlove.new({
      id = "mana_label",
      x = barX,
      y = barY - 16,
      text = string.format("Mana: %d/%d", mana.current, mana.max),
      textColor = TEXT_COLOR,
      textSize = TEXT_SIZE,
      positioning = "absolute",
      parent = self.containerElement
   })

   -- Mana bar background
   self.manaBarContainer = Flexlove.new({
      id = "mana_bar_bg",
      x = barX,
      y = barY,
      width = barWidth,
      height = barHeight,
      backgroundColor = MANA_BACKGROUND_COLOR,
      border = 1,
      borderColor = Color.new(1, 1, 1),
      positioning = "absolute",
      parent = self.containerElement
   })

   -- Mana bar fill
   local fillRatio = mana.current / mana.max
   self.manaBarFill = Flexlove.new({
      id = "mana_bar_fill",
      x = 0,
      y = 0,
      width = barWidth * fillRatio,
      height = barHeight,
      backgroundColor = MANA_FILL_COLOR,
      positioning = "absolute",
      parent = self.manaBarContainer
   })
end

function FlexMachineScreen:createProgressBar()
   if not self.entityId then return end

   local processingTimer = get(self.entityId, FRAGMENTS.ProcessingTimer)
   local recipe = get(self.entityId, FRAGMENTS.CurrentRecipe)

   if not processingTimer or not recipe or not recipe.processing_time then return end
   if recipe.processing_time <= 0 then return end

   local barWidth = self.width - self.padding * 2
   local barHeight = 8
   local barX = self.padding
   local barY = self.height - self.padding - barHeight - 32

   -- Progress bar background
   self.progressBarContainer = Flexlove.new({
      id = "progress_bar_bg",
      x = barX,
      y = barY,
      width = barWidth,
      height = barHeight,
      backgroundColor = PROGRESS_BACKGROUND_COLOR,
      border = 1,
      borderColor = Color.new(1, 1, 1),
      positioning = "absolute",
      parent = self.containerElement
   })

   -- Progress bar fill
   local fillRatio = processingTimer.current / recipe.processing_time
   self.progressBarFill = Flexlove.new({
      id = "progress_bar_fill",
      x = 0,
      y = 0,
      width = barWidth * fillRatio,
      height = barHeight,
      backgroundColor = PROGRESS_FILL_COLOR,
      positioning = "absolute",
      parent = self.progressBarContainer
   })
end

function FlexMachineScreen:createStartButton()
   local buttonWidth = 100
   local buttonHeight = 24
   local buttonX = self.width - buttonWidth - self.padding
   local buttonY = self.height - self.padding - buttonHeight

   self.startButton = Flexlove.new({
      id = "start_button",
      x = buttonX,
      y = buttonY,
      width = buttonWidth,
      height = buttonHeight,
      backgroundColor = BUTTON_BACKGROUND_COLOR,
      text = RITUAL_BUTTON_LABEL,
      textColor = TEXT_COLOR,
      textSize = TEXT_SIZE,
      textAlign = "center",
      positioning = "absolute",
      parent = self.containerElement,
      onEvent = function(element, event)
         if event.type == "click" then
            -- Handle button click
            -- This would trigger the machine start logic
         end
      end
   })
end

function FlexMachineScreen:getInventory()
   if not self.entityId then return nil end

   return get(self.entityId, FRAGMENTS.Inventory)
end

function FlexMachineScreen:draw()
   -- Update dynamic content
   self:updateMachineName()
   self:updateMachineState()
   self:updateSlots()
   self:updateManaBar()
   self:updateProgressBar()
end

function FlexMachineScreen:updateMachineName()
   if self.nameLabel then
      local name = self:getName()
      if name then
         self.nameLabel:setText(name)
      end
   end
end

function FlexMachineScreen:updateMachineState()
   if self.stateLabel then
      local state = self:getCurrentState()
      if state then
         self.stateLabel:setText(state)
      end
   end
end

function FlexMachineScreen:updateSlots()
   local inventory = self:getInventory()
   if not inventory then return end

   for _, slotData in ipairs(self.slotElements) do
      local slotIndex = slotData.slotIndex
      local slotType = slotData.slotType
      local element = slotData.element
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
               x = self.slotSize - 18,
               y = self.slotSize - 16,
               text = tostring(slot.quantity),
               textColor = TEXT_COLOR,
               textSize = 12,
               positioning = "absolute",
               parent = element
            })
         end
      end
   end
end

function FlexMachineScreen:updateManaBar()
   if not self.entityId or not self.manaBarFill or not self.manaLabel then return end

   local mana = get(self.entityId, FRAGMENTS.Mana)
   if not mana then return end

   local barWidth = self.width - self.padding * 2
   local fillRatio = mana.current / mana.max

   self.manaBarFill.width = barWidth * fillRatio
   self.manaLabel:setText(string.format("Mana: %d/%d", mana.current, mana.max))
end

function FlexMachineScreen:updateProgressBar()
   if not self.entityId or not self.progressBarFill then return end

   local processingTimer = get(self.entityId, FRAGMENTS.ProcessingTimer)
   local recipe = get(self.entityId, FRAGMENTS.CurrentRecipe)

   if not processingTimer or not recipe or not recipe.processing_time then return end
   if recipe.processing_time <= 0 then return end

   local barWidth = self.width - self.padding * 2
   local fillRatio = processingTimer.current / recipe.processing_time

   self.progressBarFill.width = barWidth * fillRatio
end

function FlexMachineScreen:getName()
   return self.entityId and get(self.entityId, Evolved.NAME) or nil
end

function FlexMachineScreen:getCurrentState()
   if not self.entityId then return nil end

   local stateMachine = get(self.entityId, FRAGMENTS.StateMachine)
   if stateMachine then
      return stateMachine.current
   end

   return nil
end

function FlexMachineScreen:isPointInSlot(mouseX, mouseY, slotX, slotY)
   return mouseX >= slotX and mouseX <= slotX + self.slotSize
      and mouseY >= slotY and mouseY <= slotY + self.slotSize
end

function FlexMachineScreen:getSlotUnderMouse(mouseX, mouseY)
   -- Use FlexLove's built-in hit detection
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

--- Set the position of the machine screen
--- @param x number
--- @param y number
function FlexMachineScreen:setPosition(x, y)
   self.x = x
   self.y = y

   -- Update container element position
   if self.containerElement then
      self.containerElement.x = x
      self.containerElement.y = y

      -- Update all child element positions relative to new container position
      -- This is handled automatically by FlexLove's parent-child system
      -- But we need to recalculate absolute positions for our manually positioned elements
      self:rebuildUI()
   end
end

--- Rebuild UI elements (useful after position change or layout update)
function FlexMachineScreen:rebuildUI()
   self:destroy()
   self:buildUI()
end

--- Update slot layout (useful for custom machine layouts)
--- @param layout table The new slot layout
function FlexMachineScreen:setSlotLayout(layout)
   self.customSlotLayout = layout
   self._cachedLayout = nil
end

--- Invalidate the cached layout (call when inventory changes)
function FlexMachineScreen:invalidateLayout()
   self._cachedLayout = nil
end

--- Destroy FlexLove elements when screen is no longer needed
function FlexMachineScreen:destroy()
   if self.containerElement then
      self.containerElement:destroy()
      self.containerElement = nil
   end

   self.nameLabel = nil
   self.stateLabel = nil
   self.manaBarContainer = nil
   self.manaBarFill = nil
   self.manaLabel = nil
   self.progressBarContainer = nil
   self.progressBarFill = nil
   self.startButton = nil
   self.slotElements = {}
end

return FlexMachineScreen
