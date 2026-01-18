local InventoryHelper = require("src.helpers.inventory_helper")
local InventoryHandlers = require("src.config.inventory_action_handlers").Handlers

local BaseViewManager = require("src.managers.base_view_manager")
local InventoryStateManager = Class("InventoryStateManager", BaseViewManager)

function InventoryStateManager:initialize()
   BaseViewManager.initialize(self)
   self.isOpen = false
   self.views = {}
   self.heldStack = nil
   self.heldStackView = nil
end

function InventoryStateManager:open(views)
   self.isOpen = true
   self.views = views or {}
end

function InventoryStateManager:close()
   if self.heldStack then
      self:returnHeldStack()
      love.mouse.setVisible(true)
   end

   -- Destroy held stack view
   if self.heldStackView then
      self.heldStackView:destroy()
      self.heldStackView = nil
   end

   -- Destroy FlexLove elements (except toolbar and equipment views which are always visible)
   for _, view in ipairs(self.views) do
      if view and view.destroy then
         -- Don't destroy toolbar or equipment views (equipment views have id starting with "equipment_")
         local isToolbar = view.id == "toolbar"
         local isEquipment = view.id and string.find(view.id, "^equipment")
         if not isToolbar and not isEquipment then
            view:destroy()
         end
      end
   end

   self.heldStack = nil
   self.isOpen = false
   self.views = {}
end

--- Handle a click on an inventory slot (main entry point for click logic)
--- @param mouseX number The x position of the mouse
--- @param mouseY number The y position of the mouse
--- @param userdata table Userdata from clicked element
--- @return boolean Success
function InventoryStateManager:handleAction(mouseX, mouseY, userdata)
   local slotInfo = self:resolveSlotInfo(mouseX, mouseY, userdata)
   if not slotInfo then return false end

   local action = userdata and userdata.action
   local handler = InventoryHandlers[action]
   if handler then
      return handler(self, slotInfo)
   end

   return false
end

function InventoryStateManager:resolveSlotInfo(mouseX, mouseY, userdata)
   local slotInfo
   if userdata and userdata.slotIndex and userdata.view then
      local view = userdata.view
      local slotIndex = userdata.slotIndex
      local slotType = userdata.slotType or view:getSlotType()
      local slot = InventoryHelper.getSlot(view.inventory, slotIndex, slotType)
      if slot then
         slotInfo = {
            view = view,
            inventory = view.inventory,
            slotIndex = slotIndex,
            slot = slot,
            slotType = slotType,
         }
      end
   else
      slotInfo = self:getSlotUnderMouse(mouseX, mouseY)
   end

   return slotInfo
end

function InventoryStateManager:draw()
   for i = 1, #self.views do
      local view = self.views[i]
      if view then
         view:draw()
      end
   end
end

--- Draw the held stack (should be called AFTER FlexLove.draw())
function InventoryStateManager:drawHeldStack()
   if self.heldStackView then
      self.heldStackView:draw()
   end
end

function InventoryStateManager:update(dt)
   -- Update held stack view position to follow cursor
   if self.heldStackView then
      self.heldStackView:update(dt)
   end
end

return InventoryStateManager:new()
