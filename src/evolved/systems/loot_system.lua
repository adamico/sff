local Inventory = require("src.evolved.fragments.inventory")

local observe = Beholder.observe
local get = Evolved.get
local trigger = Beholder.trigger

--- Spawns a corpse entity at the creature's position with its loot inventory.
--- @param entityId number The entity that died
local function spawnCorpse(entityId)
   local position = get(entityId, FRAGMENTS.Position)
   local loot = get(entityId, FRAGMENTS.Loot)
   local name = get(entityId, Evolved.NAME)

   if not position then
      Log.warn("LootSystem: Entity", entityId, "has no position, cannot spawn corpse")
      return
   end

   if not loot then
      Log.debug("LootSystem: Entity", entityId, "has no loot component, skipping corpse")
      return
   end

   -- Request corpse spawn at creature's position
   trigger(Events.ENTITY_SPAWN_REQUESTED, {
      entityId = "corpse",
      position = Vector(position.x, position.y),
      -- Pass the loot inventory to be copied to the corpse
      overrides = {
         name = name and (name.." Corpse") or "Corpse",
         inventory = Inventory.duplicate(loot),
      },
   })

   Log.debug("LootSystem: Spawned corpse for", name or entityId, "at", position.x, position.y)
end

-- Listen for entity death events
observe(Events.ENTITY_DIED, function(entityId)
   -- Only spawn corpse for entities with loot
   local loot = get(entityId, FRAGMENTS.Loot)
   if loot then
      spawnCorpse(entityId)
   end
end)

Log.info("LootSystem: Registered ENTITY_DIED observer")
