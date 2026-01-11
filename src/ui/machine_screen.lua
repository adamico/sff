local DrawHelper = require("src.helpers.draw_helper")
local MachineScreen = Class("MachineScreen"):include(DrawHelper)
local get = Evolved.get
local BORDER_WIDTH = 2

--- @class MachineScreen
--- @field borderWidth number
--- @field entityId number
--- @field height number
--- @field padding number
--- @field slotSize number
--- @field width number
--- @field x number
--- @field y number

--- @param options table
function MachineScreen:initialize(options)
   options = options or {}
   self.borderWidth = BORDER_WIDTH
   self.entityId = options.entityId or nil
   self.height = options.height or 200
   self.padding = options.padding or 8
   self.slotSize = options.slotSize or 32
   self.width = options.width or 300
   self.x = options.x or 0
   self.y = options.y or 0

   -- Slot layout configuration (can be provided or will be computed lazily)
   -- Format: {type = "input", positions = {{x = 10, y = 20}, ...}}
   self.customSlotLayout = options.slotLayout or nil
   self._cachedLayout = nil
end

--- Get the slot layout (lazily computed if not provided)
--- @return table The slot layout
function MachineScreen:getSlotLayout()
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
function MachineScreen:createDefaultLayout()
   local inventory = self:getInventory()
   if not inventory then return {} end

   local layout = {}
   local startY = self.padding + 20 -- Leave room for state text

   -- Input slots on the left
   if inventory.input_slots and #inventory.input_slots > 0 then
      local inputPositions = {}
      for i = 1, #inventory.input_slots do
         local row = math.floor((i - 1) / 3)
         local col = (i - 1) % 3
         table.insert(inputPositions, {
            x = self.padding + col * (self.slotSize + 4),
            y = startY + row * (self.slotSize + 4)
         })
      end
      table.insert(layout, {type = "input", positions = inputPositions})
   end

   -- Output slots on the right
   if inventory.output_slots and #inventory.output_slots > 0 then
      local outputPositions = {}
      local outputStartX = self.width - self.padding - self.slotSize
      for i = 1, #inventory.output_slots do
         local row = math.floor((i - 1) / 2)
         local col = (i - 1) % 2
         table.insert(outputPositions, {
            x = outputStartX - col * (self.slotSize + 4),
            y = startY + row * (self.slotSize + 4)
         })
      end
      table.insert(layout, {type = "output", positions = outputPositions})
   end

   return layout
end

function MachineScreen:getInventory()
   if not self.entityId then return nil end
   return get(self.entityId, FRAGMENTS.Inventory)
end

function MachineScreen:draw()
   -- Draw the main box
   self:drawBox(self.x, self.y, self.width, self.height)

   -- Draw machine name
   self:drawMachineName()

   -- Draw machine state
   self:drawMachineState()

   -- Draw slots
   self:drawSlots()

   -- Draw mana bar if entity has mana
   self:drawManaBar()

   -- Draw progress bar if processing
   self:drawProgressBar()
end

function MachineScreen:drawMachineName()
   local name = self:getName()
   if name then
      local drawableName = love.graphics.newText(love.graphics.getFont(), name)
      self:drawLabel(drawableName, self.x + self.padding, self.y + 20)
   end
end

function MachineScreen:drawMachineState()
   local state = self:getCurrentState()
   if state then
      local drawableState = love.graphics.newText(love.graphics.getFont(), state)
      self:drawLabel(drawableState, self.x + self.width - drawableState:getWidth() - self.padding, self.y + 20)
   end
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

function MachineScreen:drawSlots()
   local inventory = self:getInventory()
   if not inventory then return end

   local slotLayout = self:getSlotLayout()
   if not slotLayout or #slotLayout == 0 then return end

   for _, layoutGroup in ipairs(slotLayout) do
      local slotType = layoutGroup.type
      local positions = layoutGroup.positions
      local slots = inventory[slotType.."_slots"]

      if slots and positions then
         for slotIndex = 1, #positions do
            local pos = positions[slotIndex]
            local slot = slots[slotIndex] or {}
            local slotX = self.x + pos.x
            local slotY = self.y + pos.y
            self:drawSlot(slotX, slotY, self.slotSize, self.slotSize, slot)
         end
      end
   end
end

function MachineScreen:drawManaBar()
   if not self.entityId then return end

   local mana = get(self.entityId, FRAGMENTS.Mana)
   if not mana then return end

   local barWidth = self.width - self.padding * 2
   local barHeight = 8
   local barX = self.x + self.padding
   local barY = self.y + self.height - self.padding - barHeight - 16

   -- Background
   love.graphics.setColor(0.2, 0.2, 0.3)
   love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

   -- Fill
   local fillRatio = mana.current / mana.max
   love.graphics.setColor(0.3, 0.5, 0.9)
   love.graphics.rectangle("fill", barX, barY, barWidth * fillRatio, barHeight)

   -- Border
   love.graphics.setColor(1, 1, 1)
   love.graphics.rectangle("line", barX, barY, barWidth, barHeight)

   -- Label
   love.graphics.setColor(1, 1, 1)
   love.graphics.print(string.format("Mana: %d/%d", mana.current, mana.max), barX, barY - 14)
end

function MachineScreen:drawProgressBar()
   if not self.entityId then return end

   local processingTimer = get(self.entityId, FRAGMENTS.ProcessingTimer)
   local recipe = get(self.entityId, FRAGMENTS.CurrentRecipe)

   if not processingTimer or not recipe or not recipe.processing_time then return end
   if recipe.processing_time <= 0 then return end

   local barWidth = self.width - self.padding * 2
   local barHeight = 8
   local barX = self.x + self.padding
   local barY = self.y + self.height - self.padding - barHeight

   -- Background
   love.graphics.setColor(0.2, 0.2, 0.2)
   love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

   -- Fill
   local fillRatio = processingTimer.current / recipe.processing_time
   love.graphics.setColor(0.2, 0.8, 0.3)
   love.graphics.rectangle("fill", barX, barY, barWidth * fillRatio, barHeight)

   -- Border
   love.graphics.setColor(1, 1, 1)
   love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
end

function MachineScreen:isPointInSlot(mouseX, mouseY, slotX, slotY)
   return mouseX >= slotX and mouseX <= slotX + self.slotSize
      and mouseY >= slotY and mouseY <= slotY + self.slotSize
end

function MachineScreen:getSlotUnderMouse(mouseX, mouseY)
   local inventory = self:getInventory()
   if not inventory then return nil end

   local slotLayout = self:getSlotLayout()
   if not slotLayout or #slotLayout == 0 then return nil end

   for _, layoutGroup in ipairs(slotLayout) do
      local slotType = layoutGroup.type
      local positions = layoutGroup.positions
      local slots = inventory[slotType.."_slots"]

      if slots and positions then
         for slotIndex = 1, #positions do
            local pos = positions[slotIndex]
            local slotX = self.x + pos.x
            local slotY = self.y + pos.y
            if self:isPointInSlot(mouseX, mouseY, slotX, slotY) then
               return {
                  screen = self,
                  slotIndex = slotIndex,
                  slotPosition = Vector(slotX, slotY),
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
function MachineScreen:setPosition(x, y)
   self.x = x
   self.y = y
end

--- Update slot layout (useful for custom machine layouts)
--- @param layout table The new slot layout
function MachineScreen:setSlotLayout(layout)
   self.customSlotLayout = layout
   self._cachedLayout = nil
end

--- Invalidate the cached layout (call when inventory changes)
function MachineScreen:invalidateLayout()
   self._cachedLayout = nil
end

return MachineScreen
