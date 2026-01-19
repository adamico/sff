-- ============================================================================
-- Global Library Imports
-- ============================================================================
Beholder = require("lib.beholder")
Class = require("lib.middleclass")
Colors = require("src.config.colors")
Flexlove = require("lib.flexlove.FlexLove")
Events = require("src.config.events")
Log = require("lib.log")
Vector = require("lib.brinevector")
Color = Flexlove.Color
shove = require("lib.shove")

-- ============================================================================
-- ECS Setup (Evolved)
-- ============================================================================
Evolved = require("lib.evolved")
Evolved.debug_mode(true)

-- Load evolved configuration (this must come first)
local evolvedConfig = require("src.evolved.evolved_config")

-- Load fragments (populates evolvedConfig.FRAGMENTS)
require("src.evolved.fragments")

-- Load tags (populates evolvedConfig.TAGS)
require("src.evolved.tags")

-- Export evolved config to global scope BEFORE loading systems
-- (systems need these globals during registration)
FRAGMENTS = evolvedConfig.FRAGMENTS
TAGS = evolvedConfig.TAGS
ENTITIES = evolvedConfig.ENTITIES
UNIFORMS = evolvedConfig.UNIFORMS
STAGES = evolvedConfig.STAGES

-- Load systems (uses FRAGMENTS, TAGS, STAGES, etc.; populates ENTITIES at runtime)
require("src.evolved.systems")

-- ============================================================================
-- Helpers
-- ============================================================================
require("src.helpers.text_helper")

-- ============================================================================
-- Managers
-- ============================================================================
local MachineStateManager = require("src.managers.machine_state_manager")
local InventoryStateManager = require("src.managers.inventory_state_manager")

-- ============================================================================
-- Local References
-- ============================================================================
local process = Evolved.process
local sti = require("lib.sti")
local map
-- ============================================================================
-- Love2D Callbacks
-- ============================================================================

function love.load()
   map = sti("src/data/maps/dungeon_big.lua")

   Flexlove.init({
      baseScale = {width = 400, height = 300}, -- Design at game resolution
      immediateMode = false,
      theme = "metal"
   })

   shove.setResolution(400, 300, {
      fitMethod = "pixel",
      renderMode = "layer"
   })
   shove.setWindowMode(800, 600, {resizable = true})

   shove.createLayer("background", {zIndex = 10})
   shove.createLayer("entities", {zIndex = 20})
   shove.createLayer("debug", {zIndex = 1000})

   process(STAGES.OnSetup)
end

function love.update(dt)
   map:update(dt)
   UNIFORMS.setDeltaTime(dt)
   Flexlove.update(dt)
   process(STAGES.OnUpdate)
end

function love.draw()
   shove.beginDraw()

   shove.beginLayer("background")
   map:draw()

   shove.endLayer()

   shove.beginLayer("entities")
   process(STAGES.OnRenderEntities)
   shove.endLayer()

   shove.beginLayer("debug")
   process(STAGES.OnRenderDebug)
   shove.endLayer()

   shove.endDraw()

   -- UI: rendered at native window resolution (no transform)
   Flexlove.draw(nil, function()
      if InventoryStateManager.isOpen then
         InventoryStateManager:drawHeldStack()
      elseif MachineStateManager.isOpen then
         MachineStateManager:drawHeldStack()
      end
   end)
end

function love.resize(w, h)
   shove.resize(w, h)
   Flexlove.resize()
end

function love.textinput(text)
   Flexlove.textinput(text)
end

function love.wheelmoved(dx, dy)
   Flexlove.wheelmoved(dx, dy)
end

-- ============================================================================
-- Debug Helpers (Unused but kept for reference)
-- ============================================================================
-- local function drawDebugLines()
--    love.graphics.setColor(1, 0, 0)
--    love.graphics.line(SCREEN_WIDTH / 2, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT)
--    love.graphics.line(0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, SCREEN_HEIGHT / 2)
-- end
