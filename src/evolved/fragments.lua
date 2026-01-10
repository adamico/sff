local InventoryComponent = require("src.components.inventory_component")
local evolved_config = require("src.evolved.evolved_config")
local builder = Evolved.builder
local SCREEN_WIDTH, SCREEN_HEIGHT = love.graphics.getDimensions()

local function vector_duplicate(vector)
   return Vector(vector.x, vector.y)
end

local function inventory_duplicate(inventory)
   if not inventory then return nil end
   -- Create a new InventoryComponent with the same configuration
   local new_inventory = InventoryComponent:new({
      max_input_slots = #inventory.input_slots,
      max_output_slots = #inventory.output_slots,
   })
   -- Copy slot contents
   for i, slot in ipairs(inventory.input_slots) do
      if slot.item_id then
         new_inventory.input_slots[i] = {
            item_id = slot.item_id,
            quantity = slot.quantity
         }
      end
   end
   for i, slot in ipairs(inventory.output_slots) do
      if slot.item_id then
         new_inventory.output_slots[i] = {
            item_id = slot.item_id,
            quantity = slot.quantity
         }
      end
   end
   return new_inventory
end

evolved_config.FRAGMENTS = {
   Color = builder()
      :name("FRAGMENTS.Color")
      :default(Colors.WHITE)
      :build(),
   InteractionRange = builder()
      :name("FRAGMENTS.InteractionRange")
      :default(128)
      :build(),
   Input = builder()
      :name("FRAGMENTS.Input")
      :default(Vector(0, 0))
      :duplicate(vector_duplicate)
      :build(),
   Inventory = builder()
      :name("FRAGMENTS.Inventory")
      :default(nil)
      :duplicate(inventory_duplicate)
      :build(),
   MaxSpeed = builder()
      :name("FRAGMENTS.MaxSpeed")
      :default(300)
      :build(),
   Position = builder()
      :name("FRAGMENTS.Position")
      :default(Vector(0, 0))
      :duplicate(vector_duplicate)
      :build(),
   Shape = builder()
      :name("FRAGMENTS.Shape")
      :default("circle")
      :build(),
   Size = builder()
      :name("FRAGMENTS.Size")
      :default(Vector(16, 16))
      :duplicate(vector_duplicate)
      :build(),
   Toolbar = builder()
      :name("FRAGMENTS.Toolbar")
      :default(nil)
      :duplicate(inventory_duplicate)
      :build(),
   Velocity = builder()
      :name("FRAGMENTS.Velocity")
      :default(Vector(0, 0))
      :duplicate(vector_duplicate)
      :build(),
}

local FRAGMENTS = evolved_config.FRAGMENTS

evolved_config.TAGS = {
   Controllable = builder()
      :name("TAGS.Controllable")
      :tag()
      :require(FRAGMENTS.Input)
      :build(),
   Interactable = builder()
      :name("TAGS.Interactable")
      :tag()
      :build(),
   Player = builder()
      :name("TAGS.Player")
      :tag()
      :build(),
   Physical = builder()
      :name("TAGS.Physical")
      :tag()
      :require(FRAGMENTS.Position, FRAGMENTS.Velocity, FRAGMENTS.Size)
      :build(),
   Visual = builder()
      :name("TAGS.Visual")
      :tag()
      :require(FRAGMENTS.Shape, FRAGMENTS.Color)
      :build()
}
