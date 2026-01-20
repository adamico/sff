local Inventory = require("src.evolved.fragments.inventory")

return {
   corpse = {
      hitbox = {
         shape = "rectangle",
         offsetX = 0,
         offsetY = 0,
         width = 16,
         height = 8,
      },
      interaction = {type = "storage", action = "loot"},
      -- Inventory will be populated dynamically from the creature's loot component
      inventory = Inventory.new({
         maxSlots = 8,
         accessMode = "io",
      }),
      name = "Corpse",
      tags = {"interactable", "physical", "animated"},
      -- Optional: decay timer in seconds (corpse despawns after this time)
      decayTime = 60,
   },
}
