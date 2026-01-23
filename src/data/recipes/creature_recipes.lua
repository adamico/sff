return {
   createSkeleton = {
      name = "Create Skeleton",
      category = "creature_creation",
      inputs = {
         blackBile = 40,
         yellowBile = 10,
      },
      outputs = {
         skeleton = 1,
      },
      manaPerTick = 7,
      processingTime = 5,
      requiresRitual = true,
   },
   createGhost = {
      name = "Create Ghost",
      category = "creature_creation",
      inputs = {
         phlegm = 45,
         blood = 5,
      },
      outputs = {
         ghost = 1,
      },
      manaPerTick = 19,
      processingTime = 5,
      requiresRitual = true,
   },
}
