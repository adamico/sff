return {
   skeleton = {
      harvestTime = 5,
      harvestYield = 25,
      hitbox = {
         shape = "circle",
         offsetX = 0,
         offsetY = 0,
         radius = 8,
      },
      interaction = {type = "creature", action = "inspect"},
      name = "Skeleton",
      recycleReturns = {
         bone = 1,
         unlifeEssence = 1,
      },
      tags = {"harvestable", "interactable", "physical", "visual"},
      tier = "basic",
   },
}
