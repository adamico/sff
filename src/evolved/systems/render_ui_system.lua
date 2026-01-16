local EntityPlacementManager = require("src.managers.entity_placement_manager")
local InventoryStateManager = require("src.managers.inventory_state_manager")
local MachineStateManager = require("src.managers.machine_state_manager")
local UICoordinator = require("src.managers.ui_coordinator")

require("src.managers.toolbar_activation_manager") -- Registers TOOLBAR_SLOT_ACTIVATED observer

local builder = Evolved.builder

-- Register the render system (runs every frame)
builder()
   :name("SYSTEMS.RenderUI")
   :group(STAGES.OnRender)
   :include(FRAGMENTS.Toolbar)
   :include(FRAGMENTS.Equipment)
   :execute(function(chunk, _, entityCount)
      -- Render persistent UI (toolbar, equipment) for each entity
      local toolbars = chunk:components(FRAGMENTS.Toolbar)
      local equipments = chunk:components(FRAGMENTS.Equipment)

      for i = 1, entityCount do
         local toolbarView = UICoordinator.getToolbarView(toolbars[i])
         local equipmentViews = UICoordinator.getEquipmentViews(equipments[i])

         if toolbarView then toolbarView:draw() end
         for _, equipmentView in ipairs(equipmentViews) do
            equipmentView:draw()
         end
      end
   end)
   :epilogue(function()
      local dt = UNIFORMS.getDeltaTime()

      if InventoryStateManager.isOpen then
         InventoryStateManager:update(dt)
         InventoryStateManager:draw()
      end
      if MachineStateManager.isOpen then
         MachineStateManager:update(dt)
         MachineStateManager:draw()
      end

      EntityPlacementManager:update(dt)
      EntityPlacementManager:draw()
   end)
   :build()
