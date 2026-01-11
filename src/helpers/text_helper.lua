--- Recursively inspect a value and return a string representation
--- @param obj any The object to inspect
--- @param depth number|nil Current recursion depth (default 0)
--- @param maxDepth number|nil Maximum recursion depth (default 3)
--- @return string
function inspect(obj, depth, maxDepth)
   depth = depth or 0
   maxDepth = maxDepth or 3

   if depth > maxDepth then
      return "..."
   end

   local objType = type(obj)

   if objType == "nil" then
      return "nil"
   elseif objType == "boolean" then
      return tostring(obj)
   elseif objType == "number" then
      return tostring(obj)
   elseif objType == "string" then
      return string.format("%q", obj)
   elseif objType == "table" then
      local parts = {}
      local indent = string.rep("  ", depth + 1)
      local closingIndent = string.rep("  ", depth)

      -- Check if it's an array-like table
      local isArray = true
      local count = 0
      for k, _ in pairs(obj) do
         count = count + 1
         if type(k) ~= "number" or k ~= count then
            isArray = false
         end
      end

      -- Empty table
      if count == 0 then
         return "{}"
      end

      if isArray then
         for i, v in ipairs(obj) do
            table.insert(parts, indent..inspect(v, depth + 1, maxDepth))
         end
      else
         -- Collect and sort keys for consistent output
         local keys = {}
         for k, _ in pairs(obj) do
            table.insert(keys, k)
         end
         table.sort(keys, function(a, b)
            if type(a) == type(b) then
               return tostring(a) < tostring(b)
            else
               return type(a) < type(b)
            end
         end)

         for _, k in ipairs(keys) do
            local v = obj[k]
            local keyStr
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
               keyStr = k
            else
               keyStr = "["..inspect(k, depth + 1, maxDepth).."]"
            end
            table.insert(parts, indent..keyStr.." = "..inspect(v, depth + 1, maxDepth))
         end
      end

      if #parts <= 3 and not string.find(table.concat(parts), "\n") then
         -- Compact format for small tables
         local compactParts = {}
         for _, part in ipairs(parts) do
            table.insert(compactParts, part:match("^%s*(.-)%s*$"))
         end
         return "{ "..table.concat(compactParts, ", ").." }"
      else
         return "{\n"..table.concat(parts, ",\n").."\n"..closingIndent.."}"
      end
   elseif objType == "function" then
      return "<function>"
   elseif objType == "userdata" then
      return "<userdata>"
   elseif objType == "thread" then
      return "<thread>"
   else
      return tostring(obj)
   end
end
