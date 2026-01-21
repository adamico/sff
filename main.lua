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
local CameraHelper = require("src.helpers.camera_helper")

-- ============================================================================
-- Managers
-- ============================================================================
local SlotViewManager = require("src.managers.slot_view_manager")

-- ============================================================================
-- Local References
-- ============================================================================
local process = Evolved.process
local sti = require("lib.sti")
local lg = love.graphics

-- ============================================================================
-- Love2D Callbacks
-- ============================================================================

function love.load()
   -- Global map for systems to access dimensions, tiles, objects
   Map = sti("src/data/maps/dungeon_big.lua")

   Flexlove.init({
      baseScale = {width = 400, height = 300}, -- Design at game resolution
      theme = "dungeon",
      immediateMode = false
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
   Map:update(dt)
   UNIFORMS.setDeltaTime(dt)
   Flexlove.update(dt)
   process(STAGES.OnUpdate)
end

function love.draw()
   local tx, ty = CameraHelper.getOffset()

   shove.beginDraw()

   shove.beginLayer("background")
   Map:draw(-tx, -ty)
   shove.endLayer()

   shove.beginLayer("entities")
   lg.push()
   lg.translate(-tx, -ty)
   process(STAGES.OnRenderEntities)
   shove.endLayer()

   shove.beginLayer("debug")
   process(STAGES.OnRenderDebug)
   lg.pop()
   shove.endLayer()

   shove.endDraw()

   -- UI: rendered at native window resolution (no transform)
   Flexlove.draw(nil, function()
      if SlotViewManager.isOpen then
         SlotViewManager:drawHeldStack()
      end
   end)

   local fps = love.timer.getFPS()
   local mem = collectgarbage("count")
   lg.print(string.format("FPS: %d", fps), 10, 10)
   lg.print(string.format("Memory: %d KB", mem), 10, 30)
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
