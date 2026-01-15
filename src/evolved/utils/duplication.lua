-- ============================================================================
-- Duplication Utilities
-- ============================================================================
-- Helper functions for duplicating/cloning various data types in the ECS

local duplication = {}

--- Duplicates a Vector object
--- @param vector table A Vector object with x and y components
--- @return table A new Vector with the same x and y values
function duplication.duplicateVector(vector)
   return Vector(vector.x, vector.y)
end

--- Shallow clone - creates a new table with the same array values
--- @param original table The table to clone
--- @return table A new table with unpacked values from original
function duplication.clone(original)
   return {table.unpack(original)}
end

--- Deep clone - recursively copies a table and all nested tables
--- Preserves metatables
--- @param original any The value to deep clone
--- @return any A deep copy of the original value
function duplication.deepClone(original)
   local originalType = type(original)
   local copy
   if originalType == "table" then
      copy = {}
      for originalKey, originalValue in next, original, nil do
         copy[duplication.deepClone(originalKey)] = duplication.deepClone(originalValue)
      end
      setmetatable(copy, duplication.deepClone(getmetatable(original)))
   else -- number, string, boolean, etc
      copy = original
   end
   return copy
end

return duplication
