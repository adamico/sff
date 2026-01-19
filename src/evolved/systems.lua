-- ============================================================================
-- ECS Systems
-- ============================================================================
-- Systems process entities and their fragments each frame
-- This file loads all system modules in the correct order
--
-- Systems are automatically registered when their modules are loaded via
-- the Evolved builder pattern

-- ============================================================================
-- Setup Stage (STAGES.OnSetup)
-- ============================================================================
-- These systems run once during initialization

require("src.evolved.systems.setup_systems")  -- Initialize entities and world state
require("src.evolved.systems.spawner_system") -- Create entities from data files

-- ============================================================================
-- Update Stage (STAGES.OnUpdate)
-- ============================================================================
-- These systems run every frame during the update loop

-- Input & Control
require("src.evolved.systems.input_system") -- Process player input

-- Interaction
require("src.evolved.systems.combat_system")      -- Handle entity combat
require("src.evolved.systems.interaction_system") -- Handle entity interactions
require("src.evolved.systems.ui_event_system")    -- Handle UI events

-- Stats & Processing
require("src.evolved.systems.health_system")     -- Handle entity health
require("src.evolved.systems.loot_system")       -- Handle loot drops on entity death
require("src.evolved.systems.mana_system")       -- Update mana regeneration
require("src.evolved.systems.processing_system") -- Process recipes in machines
require("src.evolved.systems.creature_system")   -- Process creature AI behaviors

-- Physics & Movement
require("src.evolved.systems.physics_system")   -- Update positions and velocities
require("src.evolved.systems.collision_system") -- Handle collision detection/response

-- ============================================================================
-- Render Stage (STAGES.OnRenderEntities)
-- ============================================================================
-- These systems run during the draw loop

require("src.evolved.systems.render_entities_system") -- Render entity sprites
require("src.evolved.systems.render_ui_system")       -- Render UI elements
require("src.evolved.systems.render_health_system")   -- Render entity health bars
require("src.evolved.systems.render_mana_system")     -- Render entity mana bars
require("src.evolved.systems.render_hitboxes_system") -- Render collision hitboxes
