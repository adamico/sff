--[[
   Animation Fragment

   Manages animated sprites using peachy for entities.
   Supports multiple spritesheets (e.g., "sword", "unarmed") with automatic
   animation tag generation based on direction and state.

   Animation tags follow the pattern: {Direction}{Weapon}{State}
   e.g., "FrontSwordIdle", "BackSwordWalk", "RightSwordAttack"

   Directions: Front, Back, Left, Right
   States: Death, Hurt, Attack, Idle, Walk, WalkAttack, Run, RunAttack
]]

local peachy = require("lib.peachy")

local Animation = {}

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

--- Create a new Animation component
--- @param data table|nil Configuration data
--- @return table Animation component instance
function Animation.new(data)
   data = data or {}

   local animation = {
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

      animation.spritesheets[name] = anim

      -- Track first sheet for default
      if not firstSheet then
         firstSheet = name
      end
   end

   -- Set the first loaded sheet as active
   if firstSheet then
      animation.activeSheet = firstSheet
      -- Set initial animation tag
      local initialTag = buildAnimationTag(animation.direction, firstSheet, animation.state)
      animation.spritesheets[firstSheet]:setTag(initialTag)
      animation.spritesheets[firstSheet]:play()
   end

   return animation
end

--- Get the currently active peachy animation object
--- @param animation table Animation component
--- @return table|nil Peachy animation object or nil
function Animation.getActiveAnimation(animation)
   if animation.activeSheet and animation.spritesheets[animation.activeSheet] then
      return animation.spritesheets[animation.activeSheet]
   end
   return nil
end

--- Set the active spritesheet
--- @param animation table Animation component
--- @param sheetName string Name of the spritesheet to activate
function Animation.setActiveSheet(animation, sheetName)
   if animation.spritesheets[sheetName] then
      animation.activeSheet = sheetName
      -- Apply current direction and state to new sheet
      Animation.setAnimation(animation, animation.direction, animation.state)
   end
end

--- Set the animation state and/or direction
--- @param animation table Animation component
--- @param direction string|nil Direction ("Front" "Back" "Left" "Right")
--- @param state string|nil Animation state ("Idle" "Walk" "Attack" etc.)
function Animation.setAnimation(animation, direction, state)
   direction = direction or animation.direction
   state = state or animation.state

   -- Only update if something changed
   if direction == animation.direction and state == animation.state then
      return
   end

   animation.direction = direction
   animation.state = state

   local anim = Animation.getActiveAnimation(animation)
   if anim then
      local tag = buildAnimationTag(direction, animation.activeSheet, state)
      -- Check if the tag exists before setting
      if anim.frameTags and anim.frameTags[tag] then
         anim:setTag(tag)
         anim:play()
      end
   end
end

--- Set animation direction based on velocity vector
--- @param animation table Animation component
--- @param velocityX number X velocity
--- @param velocityY number Y velocity
function Animation.setDirectionFromVelocity(animation, velocityX, velocityY)
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

   Animation.setAnimation(animation, direction, nil)
end

--- Set animation state based on movement state
--- @param animation table Animation component
--- @param isMoving boolean Whether the entity is moving
--- @param isRunning boolean Whether the entity is running (vs walking)
--- @param isAttacking boolean Whether the entity is attacking
function Animation.setStateFromMovement(animation, isMoving, isRunning, isAttacking)
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

   Animation.setAnimation(animation, nil, state)
end

--- Update the animation (should be called every frame)
--- @param animation table Animation component
--- @param dt number Delta time
function Animation.update(animation, dt)
   local anim = Animation.getActiveAnimation(animation)
   if anim then
      anim:update(dt)
   end
end

--- Draw the current animation frame
--- @param animation table Animation component
--- @param x number World X position
--- @param y number World Y position
function Animation.draw(animation, x, y)
   local anim = Animation.getActiveAnimation(animation)
   if anim then
      anim:draw(
         x, y,
         0, -- rotation
         animation.scaleX, animation.scaleY,
         animation.offsetX, animation.offsetY
      )
   end
end

--- Duplicate an Animation component (for ECS cloning)
--- @param animation table Animation component to duplicate
--- @return table New Animation component
function Animation.duplicate(animation)
   local newAnimation = {
      spritesheets = {},
      activeSheet = animation.activeSheet,
      direction = animation.direction,
      state = animation.state,
      offsetX = animation.offsetX,
      offsetY = animation.offsetY,
      scaleX = animation.scaleX,
      scaleY = animation.scaleY,
   }

   -- Recreate peachy objects for each spritesheet
   for name, anim in pairs(animation.spritesheets) do
      local jsonPath = anim:getJSON()
      local newAnim = peachy.new(jsonPath, anim.image)

      -- Restore current animation state
      if name == animation.activeSheet then
         local tag = buildAnimationTag(animation.direction, name, animation.state)
         if newAnim.frameTags and newAnim.frameTags[tag] then
            newAnim:setTag(tag)
            newAnim:play()
         end
      end

      newAnimation.spritesheets[name] = newAnim
   end

   return newAnimation
end

--- Check if a specific animation tag exists
--- @param animation table Animation component
--- @param direction string Direction
--- @param state string Animation state
--- @return boolean
function Animation.hasAnimation(animation, direction, state)
   local anim = Animation.getActiveAnimation(animation)
   if anim and anim.frameTags then
      local tag = buildAnimationTag(direction, animation.activeSheet, state)
      return anim.frameTags[tag] ~= nil
   end
   return false
end

--- Set a callback for when the animation loops
--- @param animation table Animation component
--- @param callback function Callback function
--- @param ... any Additional arguments to pass to callback
function Animation.onLoop(animation, callback, ...)
   local anim = Animation.getActiveAnimation(animation)
   if anim then
      anim:onLoop(callback, ...)
   end
end

--- Pause the animation
--- @param animation table Animation component
function Animation.pause(animation)
   local anim = Animation.getActiveAnimation(animation)
   if anim then
      anim:pause()
   end
end

--- Resume playing the animation
--- @param animation table Animation component
function Animation.play(animation)
   local anim = Animation.getActiveAnimation(animation)
   if anim then
      anim:play()
   end
end

return Animation
