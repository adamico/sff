--[[
   Visual Fragment

   Manages animated sprites using peachy for entities.
   Supports multiple spritesheets (e.g., "sword", "unarmed") with automatic
   animation tag generation based on direction and state.

   Animation tags follow the pattern: {Direction}{Weapon}{State}
   e.g., "FrontSwordIdle", "BackSwordWalk", "RightSwordAttack"

   Directions: Front, Back, Left, Right
   States: Death, Hurt, Attack, Idle, Walk, WalkAttack, Run, RunAttack
]]

local peachy = require("lib.peachy")

local Visual = {}

local SPRITESHEETS_PATH = "src/data/spritesheets/"

-- Default values
local DEFAULT_DIRECTION = "Front"
local DEFAULT_STATE = "Idle"

--- Capitalize first letter of a string
--- @param str string
--- @return string
local function capitalize(str)
   return str:sub(1, 1):upper()..str:sub(2)
end

--- Get JSON path from image filename
--- @param imageFilename string e.g. "player_sword.png"
--- @return string e.g. "src/data/spritesheets/player_sword.json"
local function getJsonPath(imageFilename)
   local baseName = imageFilename:gsub("%.png$", "")
   return SPRITESHEETS_PATH..baseName..".json"
end

--- Build an animation tag name from components
--- @param direction string "Front" "Back" "Left" or "Right"
--- @param weapon string Weapon/spritesheet type e.g. "Sword"
--- @param state string Animation state e.g. "Idle" "Walk", "Attack"
--- @return string The animation tag e.g. "FrontSwordIdle"
local function buildAnimationTag(direction, weapon, state)
   return direction..capitalize(weapon)..state
end

--- Create a new Visual component
--- @param data table|nil Configuration data
--- @return table Visual component instance
function Visual.new(data)
   data = data or {}

   local visual = {
      -- Table of peachy animation objects, keyed by spritesheet name
      spritesheets = {},

      -- Current active spritesheet name
      activeSheet = nil,

      -- Current animation state
      direction = DEFAULT_DIRECTION,
      state = DEFAULT_STATE,

      -- Sprite rendering offsets (for centering)
      offsetX = data.offsetX or 32,
      offsetY = data.offsetY or 48,

      -- Scale
      scaleX = data.scaleX or 1,
      scaleY = data.scaleY or 1,
   }

   -- Load spritesheets from data
   local spriteSheets = data.spriteSheets or {}
   local firstSheet = nil

   for name, imageFilename in pairs(spriteSheets) do
      local imagePath = SPRITESHEETS_PATH..imageFilename
      local jsonPath = getJsonPath(imageFilename)

      -- Load the image
      local image = love.graphics.newImage(imagePath)

      -- Create peachy animation object
      -- We don't set an initial tag yet - we'll set it after we know the weapon name
      local anim = peachy.new(jsonPath, image)

      visual.spritesheets[name] = anim

      -- Track first sheet for default
      if not firstSheet then
         firstSheet = name
      end
   end

   -- Set the first loaded sheet as active
   if firstSheet then
      visual.activeSheet = firstSheet
      -- Set initial animation tag
      local initialTag = buildAnimationTag(visual.direction, firstSheet, visual.state)
      visual.spritesheets[firstSheet]:setTag(initialTag)
      visual.spritesheets[firstSheet]:play()
   end

   return visual
end

--- Get the currently active peachy animation object
--- @param visual table Visual component
--- @return table|nil Peachy animation object or nil
function Visual.getActiveAnimation(visual)
   if visual.activeSheet and visual.spritesheets[visual.activeSheet] then
      return visual.spritesheets[visual.activeSheet]
   end
   return nil
end

--- Set the active spritesheet
--- @param visual table Visual component
--- @param sheetName string Name of the spritesheet to activate
function Visual.setActiveSheet(visual, sheetName)
   if visual.spritesheets[sheetName] then
      visual.activeSheet = sheetName
      -- Apply current direction and state to new sheet
      Visual.setAnimation(visual, visual.direction, visual.state)
   end
end

--- Set the animation state and/or direction
--- @param visual table Visual component
--- @param direction string|nil Direction ("Front" "Back" "Left" "Right")
--- @param state string|nil Animation state ("Idle" "Walk" "Attack" etc.)
function Visual.setAnimation(visual, direction, state)
   direction = direction or visual.direction
   state = state or visual.state

   -- Only update if something changed
   if direction == visual.direction and state == visual.state then
      return
   end

   visual.direction = direction
   visual.state = state

   local anim = Visual.getActiveAnimation(visual)
   if anim then
      local tag = buildAnimationTag(direction, visual.activeSheet, state)
      -- Check if the tag exists before setting
      if anim.frameTags and anim.frameTags[tag] then
         anim:setTag(tag)
         anim:play()
      end
   end
end

--- Set animation direction based on velocity vector
--- @param visual table Visual component
--- @param velocityX number X velocity
--- @param velocityY number Y velocity
function Visual.setDirectionFromVelocity(visual, velocityX, velocityY)
   -- Only update direction if there's significant movement
   local threshold = 0.1
   if math.abs(velocityX) < threshold and math.abs(velocityY) < threshold then
      return
   end

   local direction

   -- Determine primary direction based on larger velocity component
   if math.abs(velocityX) > math.abs(velocityY) then
      -- Horizontal movement is dominant
      direction = velocityX > 0 and "Right" or "Left"
   else
      -- Vertical movement is dominant
      direction = velocityY > 0 and "Front" or "Back"
   end

   Visual.setAnimation(visual, direction, nil)
end

--- Set animation state based on movement state
--- @param visual table Visual component
--- @param isMoving boolean Whether the entity is moving
--- @param isRunning boolean Whether the entity is running (vs walking)
--- @param isAttacking boolean Whether the entity is attacking
function Visual.setStateFromMovement(visual, isMoving, isRunning, isAttacking)
   local state

   if isAttacking then
      if isMoving then
         state = isRunning and "RunAttack" or "WalkAttack"
      else
         state = "Attack"
      end
   elseif isMoving then
      state = isRunning and "Run" or "Walk"
   else
      state = "Idle"
   end

   Visual.setAnimation(visual, nil, state)
end

--- Update the animation (should be called every frame)
--- @param visual table Visual component
--- @param dt number Delta time
function Visual.update(visual, dt)
   local anim = Visual.getActiveAnimation(visual)
   if anim then
      anim:update(dt)
   end
end

--- Draw the current animation frame
--- @param visual table Visual component
--- @param x number World X position
--- @param y number World Y position
function Visual.draw(visual, x, y)
   local anim = Visual.getActiveAnimation(visual)
   if anim then
      anim:draw(
         x, y,
         0, -- rotation
         visual.scaleX, visual.scaleY,
         visual.offsetX, visual.offsetY
      )
   end
end

--- Duplicate a Visual component (for ECS cloning)
--- @param visual table Visual component to duplicate
--- @return table New Visual component
function Visual.duplicate(visual)
   local newVisual = {
      spritesheets = {},
      activeSheet = visual.activeSheet,
      direction = visual.direction,
      state = visual.state,
      offsetX = visual.offsetX,
      offsetY = visual.offsetY,
      scaleX = visual.scaleX,
      scaleY = visual.scaleY,
   }

   -- Recreate peachy objects for each spritesheet
   for name, anim in pairs(visual.spritesheets) do
      local jsonPath = anim:getJSON()
      local newAnim = peachy.new(jsonPath, anim.image)

      -- Restore current animation state
      if name == visual.activeSheet then
         local tag = buildAnimationTag(visual.direction, name, visual.state)
         if newAnim.frameTags and newAnim.frameTags[tag] then
            newAnim:setTag(tag)
            newAnim:play()
         end
      end

      newVisual.spritesheets[name] = newAnim
   end

   return newVisual
end

--- Check if a specific animation tag exists
--- @param visual table Visual component
--- @param direction string Direction
--- @param state string Animation state
--- @return boolean
function Visual.hasAnimation(visual, direction, state)
   local anim = Visual.getActiveAnimation(visual)
   if anim and anim.frameTags then
      local tag = buildAnimationTag(direction, visual.activeSheet, state)
      return anim.frameTags[tag] ~= nil
   end
   return false
end

--- Set a callback for when the animation loops
--- @param visual table Visual component
--- @param callback function Callback function
--- @param ... any Additional arguments to pass to callback
function Visual.onLoop(visual, callback, ...)
   local anim = Visual.getActiveAnimation(visual)
   if anim then
      anim:onLoop(callback, ...)
   end
end

--- Pause the animation
--- @param visual table Visual component
function Visual.pause(visual)
   local anim = Visual.getActiveAnimation(visual)
   if anim then
      anim:pause()
   end
end

--- Resume playing the animation
--- @param visual table Visual component
function Visual.play(visual)
   local anim = Visual.getActiveAnimation(visual)
   if anim then
      anim:play()
   end
end

return Visual
