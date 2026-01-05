--- Entity management for Lua.
--- @class nata

local nata = {
   _VERSION = "Nata v0.3.3",
   _DESCRIPTION = "Entity management for Lua.",
   _URL = "https://github.com/tesselode/nata",
   _LICENSE = [[
		MIT License

		Copyright (c) 2020 Andrew Minnich

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	]]
}

-- gets the error level needed to make an error appear
-- in the user's code, not the library code
local function getUserErrorLevel()
   local source = debug.getinfo(1).source
   local level = 1
   while debug.getinfo(level).source == source do
      level = level + 1
   end
   --[[
		we return level - 1 here and not just level
		because the level was calculated one function
		deeper than the function that will actually
		use this value. if we produced an error *inside*
		this function, level would be correct, but
		for the function calling this function, level - 1
		is correct.
	]]
   return level - 1
end

-- gets the name of the function that the user called
-- that eventually caused an error
local function getUserCalledFunctionName()
   return debug.getinfo(getUserErrorLevel() - 1).name
end

local function checkCondition(condition, message)
   if condition then return end
   error(message, getUserErrorLevel())
end

-- changes a list of types into a human-readable phrase
-- i.e. string, table, number -> "string, table, or number"
local function getAllowedTypesText(...)
   local numberOfArguments = select("#", ...)
   if numberOfArguments >= 3 then
      local text = ""
      for i = 1, numberOfArguments - 1 do
         text = text..string.format("%s, ", select(i, ...))
      end
      text = text..string.format("or %s", select(numberOfArguments, ...))
      return text
   elseif numberOfArguments == 2 then
      return string.format("%s or %s", select(1, ...), select(2, ...))
   end
   return select(1, ...)
end

-- checks if an argument is of the correct type, and if not,
-- throws a "bad argument" error consistent with the ones
-- lua and love produce
local function checkArgument(argumentIndex, argument, ...)
   for i = 1, select("#", ...) do
      -- allow tables with the __call metamethod to be treated like functions
      if select(i, ...) == "function" then
         if type(argument) == "table" and getmetatable(argument).__call then
            return
         end
      end
      if type(argument) == select(i, ...) then return end
   end
   error(
      string.format(
         "bad argument #%i to '%s' (expected %s, got %s)",
         argumentIndex,
         getUserCalledFunctionName(),
         getAllowedTypesText(...),
         type(argument)
      ),
      getUserErrorLevel()
   )
end

local function checkOptionalArgument(argumentIndex, argument, ...)
   if argument == nil then return end
   checkArgument(argumentIndex, argument, ...)
end

local function removeByValue(t, v)
   for i = #t, 1, -1 do
      if t[i] == v then table.remove(t, i) end
   end
end

local function entityHasKeys(entity, keys)
   for _, key in ipairs(keys) do
      if not entity[key] then return false end
   end
   return true
end

local function filterEntity(entity, filter)
   if type(filter) == "table" then
      return entityHasKeys(entity, filter)
   elseif type(filter) == "function" then
      return filter(entity)
   end
   return true
end

--- Defines the behaviors of a system.
---
--- There's no constructor for SystemDefinitions. Rather, you simply
--- define a table with functions that correspond to events. These
--- events can be named anything you like. Below are the built-in events
--- that the pool will automatically call.
--- @class SystemDefinition
--- @field init? fun(self: System, ...) Called when the pool is first created.
--- @field add? fun(self: System, e: table) Called when an entity is added to the pool.
--- @field remove? fun(self: System, e: table) Called when an entity is removed from the pool.
--- @field addToGroup? fun(self: System, groupName: string, e: table) Called when an entity is added to a group.
--- @field removeFromGroup? fun(self: System, groupName: string, e: table) Called when an entity is removed from a group.

--- Responds to events in a pool.
---
--- Systems are not created directly. They're created by the [Pool]
--- according to the [SystemDefinition]s passed to `nata.new`.
--- Each system instance inherits all of the functions of its
--- [SystemDefinition].
--- @class System: SystemDefinition
--- @field pool Pool The Pool that this system is running on.

--- Manages a subset of entities.
--- @class Group
--- @field filter? table|fun(entity: table):boolean The filter that defines which entities are added to this group.
--- @field sort? fun(a: table, b: table):boolean A function that specifies how the entities in this group should be sorted.
--- @field entities table[] A list of all the entities in the group.
--- @field hasEntity table<table, boolean> A set of all the entities in the group.
--- @field _needsResort? boolean

--- Manages entities in a game world.
--- @class Pool
--- @field entities table[] A list of all the entities in the pool.
--- @field hasEntity table<table, boolean> A set of all the entities in the pool.
--- @field groups table<string, Group> A dictionary of the Groups in the pool.
--- @field data any A field containing any data you want.
--- @field _queue table[]
--- @field _entitiesToFlush table[]
--- @field _systems System[]
--- @field _events table<string, function[]>
local Pool = {}
Pool.__index = Pool

---

function Pool:_validateOptions(options)
   checkOptionalArgument(1, options, "table")
   if not options then return end
   if options.groups then
      checkCondition(type(options.groups) == "table", "groups must be a table")
      for groupName, groupOptions in pairs(options.groups) do
         checkCondition(type(groupOptions) == "table",
            string.format("options for group '$s' must be a table", groupName))
         local filter = groupOptions.filter
         if filter ~= nil then
            checkCondition(type(filter) == "table" or type(filter) == "function",
               string.format("filter for group '%s' must be a table or function", groupName))
         end
         local sort = groupOptions.sort
         if sort ~= nil then
            checkCondition(type(sort) == "function",
               string.format("sort for group '%s' must be a function", groupName))
         end
      end
   end
   if options.systems then
      checkCondition(type(options.systems) == "table", "systems must be a table")
      for _, system in ipairs(options.systems) do
         checkCondition(type(system) == "table", "all systems must be tables")
      end
   end
end

function Pool:_init(options, ...)
   self:_validateOptions(options)
   options = options or {}
   -- entities that will be added to the pool on the next flush
   self._queue = {}
   -- a temporary table for entities that will be added to the pool
   -- on the current flush (see Pool.flush for more details)
   self._entitiesToFlush = {}
   self.entities = {}
   self.hasEntity = {}
   self.groups = {}
   self._systems = {}
   self._events = {}
   self.data = options.data or {}
   local groups = options.groups or {}
   local systems = options.systems or {nata.oop()}
   for groupName, groupOptions in pairs(groups) do
      self.groups[groupName] = {
         filter = groupOptions.filter,
         sort = groupOptions.sort,
         entities = {},
         hasEntity = {},
      }
   end
   for _, systemDefinition in ipairs(systems) do
      local system = setmetatable({
         pool = self,
      }, {__index = systemDefinition})
      table.insert(self._systems, system)
   end
   self:emit("init", ...)
end

--- Queues an entity to be added to the pool.
--- @param entity table the entity to add
--- @return table entity the queued entity
function Pool:queue(entity)
   table.insert(self._queue, entity)
   return entity
end

--- Adds the queued entities to the pool. Entities are added
-- in the order they were queued.
function Pool:flush()
   --[[
		Move the currently queued entities to a temporary
		table. This way, if an add/addToGroup/removeToGroup
		event emission leads to another entity being queued,
		it will be saved for the next flush, rather than
		adding entities to the table we're in the middle
		of iterating over, which would lead to an array with
		holes and screw everything up.
	]]
   for i = 1, #self._queue do
      local entity = self._queue[i]
      self._entitiesToFlush[i] = entity
      self._queue[i] = nil
   end
   for i = 1, #self._entitiesToFlush do
      local entity = self._entitiesToFlush[i]
      -- check if the entity belongs in each group and
      -- add it to/remove it from the group as needed
      for groupName, group in pairs(self.groups) do
         if filterEntity(entity, group.filter) then
            if not group.hasEntity[entity] then
               table.insert(group.entities, entity)
               group.hasEntity[entity] = true
               self:emit("addToGroup", groupName, entity)
            end
            if group.sort then group._needsResort = true end
         elseif group.hasEntity[entity] then
            removeByValue(group.entities, entity)
            group.hasEntity[entity] = nil
            self:emit("removeFromGroup", groupName, entity)
         end
      end
      -- add the entity to the pool if it hasn't been added already
      if not self.hasEntity[entity] then
         table.insert(self.entities, entity)
         self.hasEntity[entity] = true
         self:emit("add", entity)
      end
      self._entitiesToFlush[i] = nil
   end
   -- re-sort groups
   for _, group in pairs(self.groups) do
      if group._needsResort then
         table.sort(group.entities, group.sort)
         group._needsResort = nil
      end
   end
end

--- Removes entities from the pool.
--- @param f fun(entity: table):boolean the condition upon which an entity should be removed.
function Pool:remove(f)
   checkArgument(1, f, "function")
   for groupName, group in pairs(self.groups) do
      for i = #group.entities, 1, -1 do
         local entity = group.entities[i]
         if f(entity) then
            self:emit("removeFromGroup", groupName, entity)
            table.remove(group.entities, i)
            group.hasEntity[entity] = nil
         end
      end
   end
   for i = #self.entities, 1, -1 do
      local entity = self.entities[i]
      if f(entity) then
         self:emit("remove", entity)
         table.remove(self.entities, i)
         self.hasEntity[entity] = nil
      end
   end
end

--- Registers a function to be called when an event is emitted.
--- @param event string the event to listen for
--- @param f function the function to call
--- @return function f the function that was registered
function Pool:on(event, f)
   checkCondition(event ~= nil, "event cannot be nil")
   checkArgument(2, f, "function")
   self._events[event] = self._events[event] or {}
   table.insert(self._events[event], f)
   return f
end

--- Unregisters a function from an event.
--- @param event string the event to unregister the function from
--- @param f function the function to unregister
function Pool:off(event, f)
   checkCondition(event ~= nil, "event cannot be nil")
   checkArgument(2, f, "function")
   if self._events[event] then
      removeByValue(self._events[event], f)
   end
end

--- Emits an event. The `system[event]` function will be called for each system that has it, and functions registered to the event will be called as well.
--- @param event string the event to emit
--- @param ... any additional arguments to pass to the functions that are called
function Pool:emit(event, ...)
   checkCondition(event ~= nil, "event cannot be nil")
   for _, system in ipairs(self._systems) do
      if type(system[event]) == "function" then
         system[event](system, ...)
      end
   end
   if self._events[event] then
      for _, f in ipairs(self._events[event]) do
         f(...)
      end
   end
end

--- Gets this pool's instance of a system.
--- @param systemDefinition SystemDefinition the system class to get the instance of
--- @return System? system the instance of the system running in this pool
function Pool:getSystem(systemDefinition)
   checkArgument(1, systemDefinition, "table")
   for _, system in ipairs(self._systems) do
      if getmetatable(system).__index == systemDefinition then
         return system
      end
   end
end

---
-- @section end

local function validateOopOptions(options)
   checkOptionalArgument(1, options, "table")
   if not options then return end
   if options.include then
      checkCondition(type(options.include) == "table", "include must be a table")
   end
   if options.exclude then
      checkCondition(type(options.exclude) == "table", "exclude must be a table")
   end
end

--- Defines the behavior of an OOP system.
--- @class OopOptions
--- @field include? string[] A list of events to forward to entities. If not defined, the system will forward all events to entities (except for the ones in the exclude list).
--- @field exclude? string[] A list of events *not* to forward to entities.
--- @field group? string The name of the group of entities to forward events to. If not defined, the system will forward events to all entities.

---
-- @section end

--- Creates a new OOP system definition.
---
--- An OOP system, upon receiving an event, will call
--- the function of the same name on each entity it monitors
--- (if it exists). This facilitates a more traditional, OOP-style
--- entity management, where you loop over a table of entities and
--- call update and draw functions on them.
--- @param options? OopOptions how to set up the OOP system
--- @return SystemDefinition systemDefinition the new OOP system definition
function nata.oop(options)
   validateOopOptions(options)
   local group = options and options.group
   local include, exclude
   if options and options.include then
      include = {}
      for _, event in ipairs(options.include) do
         include[event] = true
      end
   end
   if options and options.exclude then
      exclude = {}
      for _, event in ipairs(options.exclude) do
         exclude[event] = true
      end
   end
   return setmetatable({_cache = {}}, {
      __index = function(t, event)
         t._cache[event] = t._cache[event] or function(self, ...)
            local shouldCallEvent = true
            if include and not include[event] then shouldCallEvent = false end
            if exclude and exclude[event] then shouldCallEvent = false end
            if shouldCallEvent then
               local entities
               -- not using ternary here because if the group doesn't exist,
               -- i'd rather it cause an error than just silently falling back
               -- to the main entity pool
               if group then
                  entities = self.pool.groups[group].entities
               else
                  entities = self.pool.entities
               end
               for _, entity in ipairs(entities) do
                  if type(entity[event]) == "function" then
                     entity[event](entity, ...)
                  end
               end
            end
         end
         return t._cache[event]
      end
   })
end

--- Defines the filter and sort function for a [Group].
--- @class GroupOptions
--- @field filter? table|fun(entity: table):boolean The filter that defines which entities are added to this group.
--- @field sort? fun(a: table, b: table):boolean A function that specifies how the entities in this group should be sorted.

--- Defines the groups and systems for a [Pool].
--- @class PoolOptions
--- @field groups? table<string, GroupOptions> A dictionary of groups for the pool to have.
--- @field systems? SystemDefinition[] A list of [SystemDefinition]s for the pool to use.
--- @field data? any An initial value to set [Pool.data] to.

---
-- @section end

--- Creates a new [Pool].
--- @param options? PoolOptions how to set up the pool
--- @param ... any additional arguments to pass to the pool's init event
--- @return Pool pool the new pool
function nata.new(options, ...)
   local pool = setmetatable({}, Pool)
   pool:_init(options, ...)
   return pool
end

return nata
