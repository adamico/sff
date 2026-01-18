-- ============================================================================
-- ECS Tags
-- ============================================================================
-- Tags are markers that identify entities with specific behaviors or capabilities
-- They can require certain fragments to be present on tagged entities

local evolvedConfig = require("src.evolved.evolved_config")
local builder = Evolved.builder

-- FRAGMENTS must be loaded before tags since tags reference them
local FRAGMENTS = evolvedConfig.FRAGMENTS

evolvedConfig.TAGS = {
   -- Controllable entities can receive player input
   Controllable = builder()
      :name("TAGS.Controllable")
      :tag()
      :require(FRAGMENTS.Input)
      :build(),

   -- Damageable entities can be damaged by the player
   Damageable = builder()
      :name("TAGS.Damageable")
      :tag()
      :require(FRAGMENTS.Position, FRAGMENTS.Health)
      :build(),

   -- Harvestable entities can be harvested by the player
   Harvestable = builder()
      :name("TAGS.Harvestable")
      :tag()
      :require(FRAGMENTS.Position, FRAGMENTS.Mana)
      :build(),

   -- Interactable entities can be interacted with by the player
   Interactable = builder()
      :name("TAGS.Interactable")
      :tag()
      :build(),

   -- Player tag identifies the player-controlled entity
   Player = builder()
      :name("TAGS.Player")
      :tag()
      :build(),

   -- Physical entities have position, velocity, and collision
   Physical = builder()
      :name("TAGS.Physical")
      :tag()
      :require(
         FRAGMENTS.Position,
         FRAGMENTS.Velocity,
         FRAGMENTS.Hitbox
      )
      :build(),

   -- Visual entities can be rendered with animated sprites
   Visual = builder()
      :name("TAGS.Visual")
      :tag()
      :require(FRAGMENTS.Position, FRAGMENTS.Visual)
      :build(),

   -- Processing entities can process recipes (machines, crafters, etc.)
   Processing = builder()
      :name("TAGS.Processing")
      :tag()
      :require(
         FRAGMENTS.CurrentRecipe,
         FRAGMENTS.InputQueue,
         FRAGMENTS.Mana,
         FRAGMENTS.ProcessingTimer,
         FRAGMENTS.StateMachine,
         FRAGMENTS.ValidRecipes
      )
      :build(),

   -- Creature entities have AI behaviors controlled by their CreatureClass
   Creature = builder()
      :name("TAGS.Creature")
      :tag()
      :require(
         FRAGMENTS.CreatureClass,
         FRAGMENTS.Position,
         FRAGMENTS.StateMachine
      )
      :build(),
}
