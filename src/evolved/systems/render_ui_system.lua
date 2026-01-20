local EntityPlacementManager = require("src.managers.entity_placement_manager")
local SlotViewManager = require("src.managers.slot_view_manager")
local UICoordinator = require("src.managers.ui_coordinator")

require("src.managers.toolbar_activation_manager") -- Registers TOOLBAR_SLOT_ACTIVATED observer

local builder = Evolved.builder

-- Register the render system (runs every frame)
builder()
   :name("SYSTEMS.RenderUI")
   :group(STAGES.OnRenderEntities)
   :include(FRAGMENTS.Toolbar)
   :include(FRAGMENTS.WeaponSlot) -- Use WeaponSlot as indicator of player entity
   :execute(function(chunk, _, entityCount)
      -- Render persistent UI (toolbar, equipment) for each entity
      local toolbars = chunk:components(FRAGMENTS.Toolbar)
      local weaponSlots, armorSlots = chunk:components(FRAGMENTS.WeaponSlot, FRAGMENTS.ArmorSlot)

      for i = 1, entityCount do
         local toolbarView = UICoordinator.getToolbarView(toolbars[i])
         local equipmentViews = UICoordinator.getEquipmentViews(weaponSlots[i], armorSlots[i])

         if toolbarView then toolbarView:draw() end
         for _, equipmentView in ipairs(equipmentViews) do
            equipmentView:draw()
         end
      end
   end)
   :epilogue(function()
      local dt = UNIFORMS.getDeltaTime()

      if SlotViewManager.isOpen then
         SlotViewManager:update(dt)
         SlotViewManager:draw()
      end

      EntityPlacementManager:update(dt)
      EntityPlacementManager:draw()
   end)
   :build()
