--[[
 Prototype Oriented Programming for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2000-2026 std.prototype authors
]]
--[[--
 Ordered Map Prototype.

 This module returns a table of ordered map operators, as well as the
 prototype for an OrderedMap container object.

 An OrderedMap is a table that remembers the order in which its keys were
 first added.  Fields are read and written as for any table, and a new
 key goes to the end, while writing the value of a key that is already
 there keeps it in its place.

 A map is not a list and it has no length: `#` and `len` give the length
 of the sequence part of its fields, not the number of actual keys.
 Count the keys with @{size}.

 To remove a key, use @{delete}.  The remaining keys keep their order,
 and a key that is appended again is put at the end.  Writing `nil` to
 a field or using `rawset` bypasses the OrderedMap metadata bookkeeping
 leaving stale keys until updated by appending again or the whole map
 is copied.

 A key can be any value but `nil`, and its value can be any value but
 `nil`.  While the entries are the fields of the object itself, the entry
 order is held in the metatable of each object.

 Write the entries of a new map as a list of tables of one pair each:

    local OrderedMap = require 'std.prototype.orderedmap'.prototype
    local build = OrderedMap {{core = 'core.c'}, {util = 'util.c'}}
    build.extra = 'extra.c'
    for name, source in elems(build) do
       print(name, source)      --> core core.c, util util.c, extra extra.c
    end

 In addition to the functionality described here, OrderedMap containers
 also have all the methods and metamethods of the
 @{prototype.container.prototype} (except where overridden here).

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> OrderedMap

 @module std.prototype.orderedmap
]]


local _ENV = require 'std.normalize' {
   Container = require 'std.prototype.container'.prototype,
   Module = require 'std.prototype._base'.Module,
   argscheck = require 'std.prototype._base'.argscheck,
   concat = table.concat,
   nonempty = next,
   format = string.format,
   remove = table.remove,
   sub = string.sub,
}


local OrderedMap -- forward declaration



--[[ ==================== ]]--
--[[ Primitive Functions. ]]--
--[[ ==================== ]]--


-- These functions know about internal implementation.
-- The entries are fields of the object, and its metatable, which each
-- object has to itself, lists its `_keys` in order, and the position of
-- each in `_pos`.  A field assigned `nil` where the object is a plain
-- table, as `rawset` does, leaves its key listed, so the list can have
-- keys that are no longer fields, which are skipped.


-- Forget the key at *i* of the list of the metatable *mt*.
local function unlist(mt, i)
   local keys, pos = mt._keys, mt._pos
   pos[keys[i]] = nil
   remove(keys, i)
   for j = i, #keys do
      pos[keys[j]] = j
   end
end


local function get(om, key)
   return rawget(om, key)
end


local function set(om, key, value)
   if key == nil then
      error('OrderedMap key expected, got nil', 3)
   end
   local mt = getmetatable(om)
   if value == nil then
      if rawget(om, key) ~= nil then
         rawset(om, key, nil)
         unlist(mt, mt._pos[key])
      end
   else
      if rawget(om, key) == nil then
         -- A key that was listed but is no longer a field goes to the end.
         if mt._pos[key] ~= nil then
            unlist(mt, mt._pos[key])
         end
         mt._keys[#mt._keys + 1] = key
         mt._pos[key] = #mt._keys
      end
      rawset(om, key, value)
   end
   return om
end


local function elems(om)
   local keys, i = getmetatable(om)._keys, 0
   return function()
      while true do
         i = i + 1
         local key = keys[i]
         if key == nil then
            return nil
         end
         local value = rawget(om, key)
         if value ~= nil then
            return key, value
         end
      end
   end, om
end


local function size(om)
   local n = 0
   for _ in elems(om) do
      n = n + 1
   end
   return n
end



--[[ ===================== ]]--
--[[ High Level Functions. ]]--
--[[ ===================== ]]--


-- These functions are independent of the internal implementation.


local function keys(om)
   local r, n = {}, 0
   for key in elems(om) do
      n = n + 1
      r[n] = key
   end
   r.n = n
   return r
end


local function values(om)
   local r, n = {}, 0
   for _, value in elems(om) do
      n = n + 1
      r[n] = value
   end
   r.n = n
   return r
end


local function entries(om)
   local r, n = {}, 0
   for key, value in elems(om) do
      n = n + 1
      r[n] = {[key] = value}
   end
   r.n = n
   return r
end


local function merged(...)
   local r = OrderedMap {}
   for i = 1, select('#', ...) do
      local om = select(i, ...)
      if om ~= nil then
         for key, value in elems(om) do
            set(r, key, value)
         end
      end
   end
   return r
end


local function pluck(om, wanted)
   local want = {}
   for i = 1, wanted.n or len(wanted) do
      if wanted[i] ~= nil then
         want[wanted[i]] = true
      end
   end
   local r = OrderedMap {}
   for key, value in elems(om) do
      if want[key] then
         set(r, key, value)
      end
   end
   return r
end


local function mapvalues(om, fn)
   local r = OrderedMap {}
   for key, value in elems(om) do
      set(r, key, fn(value, key))
   end
   return r
end



--[[ ================== ]]--
--[[ OrderedMap Object. ]]--
--[[ ================== ]]--


local function X(decl, fn)
   return argscheck('std.prototype.orderedmap.' .. decl, fn)
end


-- The keys and entries of *t*, a table that makes or adds to a map.
local function addentries(om, t)
   local mt = getmetatable(om)
   for k, v in next, t do
      if type(k) == 'string' and sub(k, 1, 1) == '_' then
         mt[k] = v
      elseif type(k) ~= 'number' and k ~= 'n' then
         error(format("OrderedMap entry expected, got field '%s'", str(k)), 4)
      end
   end
   for i = 1, len(t) do
      local entry = t[i]
      local key, value = next(type(entry) == 'table' and entry or {})
      if key == nil or next(entry, key) ~= nil then
         error(format('OrderedMap entry #%d must be a table of one pair', i), 4)
      end
      set(om, key, value)
   end
   return om
end


-- A new map from the fields and the order of *self*, and then either
-- the entries of the list that is the one argument, or whatever the
-- `_init` function of the type makes of the arguments.
local function derive(self, ...)
   local mt, obj, nmt = getmetatable(self), {}, {}
   for k, v in next, mt do
      nmt[k] = v
   end
   nmt._keys, nmt._pos = {}, {}
   setmetatable(obj, nmt)
   for key, value in elems(self) do
      set(obj, key, value)
   end

   if type(mt._init) == 'function' then
      return mt._init(obj, ...) or obj
   end

   local t, n = ..., select('#', ...)
   if n == 0 then
      argerror(mt._type, 1, 'table expected, got no value', 2)
   elseif type(t) ~= 'table' then
      argerror(mt._type, 1, 'table expected, got ' .. type(t), 2)
   elseif n > 1 then
      argerror(mt._type, 2, 'no more than 1 argument expected, got ' .. n, 2)
   end
   return addentries(obj, t)
end


--- OrderedMap prototype object.
-- @object prototype
-- @string[opt='OrderedMap'] _type object name
-- @see prototype.container.prototype
-- @usage
--   local OrderedMap = require 'std.prototype.orderedmap'.prototype
--   assert(prototype.type(OrderedMap) == 'OrderedMap')


OrderedMap = Container {
   _type = 'OrderedMap',

   _keys = {},

   _pos = {},

   --- Metamethods
   -- @section metamethods

   --- OrderedMap object initialisation.
   --
   -- Returns a new OrderedMap with the entries of this one, and then
   -- those of the list *t* of tables of one pair each, in order; where
   -- a key is written more than once the last value replaces the first,
   -- in place.  A field of *t* that is named with a leading underscore,
   -- such as `_type`, is a field of the metatable instead, its `n`
   -- field, as @{entries} makes, is ignored, and any other is an error.
   --
   -- A type that is derived with an `_init` function is called with the
   -- new map, which has the entries of the one called, and then all the
   -- arguments, as Container's `_init` is, in place of all that, and
   -- returns the map.  As for Container, deriving another type from one
   -- with an `_init` calls it with the table that describes the new
   -- type, so it must handle fields that start with an underscore.
   -- @function __call
   -- @tparam table t entries, and fields of the metatable
   -- @treturn OrderedMap a new map
   -- @usage
   --   local build = OrderedMap {{core = 'core.c'}, {util = 'util.c'}}
   --   local Config = OrderedMap {_type = 'Config', _init = function(new, name)
   --      new.name = name
   --      return new
   --   end}
   --   local config = Config 'demo'
   __call = derive,

   --- Set the value of a key that is new to the map.
   -- A new key goes to the end.  A field that is already there is
   -- written without this, and keeps its place.
   -- @function __newindex
   -- @param key a key
   -- @param value the value
   -- @usage
   --   om[key] = value
   __newindex = function(om, key, value)
      set(om, key, value)
   end,

   --- Iterate over the keys and values, in order.
   -- The `pairs` of std.normalize honors it in every Lua, and the host's
   -- `pairs` in Lua 5.2 and later; @{elems} does the same.
   -- @function __pairs
   -- @usage
   --   for key, value in pairs(om) do print(key, value) end
   __pairs = elems,

   --- Return a string representation of this map.
   -- @function __tostring
   -- @treturn string the keys and values in order
   -- @usage
   --   --> OrderedMap {b=1, a=2}
   --   print(OrderedMap {{b = 1}, {a = 2}})
   __tostring = function(self)
      local pieces = {}
      for key, value in elems(self) do
         pieces[#pieces + 1] = str(key) .. '=' .. str(value)
      end
      return getmetatable(self)._type .. ' {' .. concat(pieces, ', ') .. '}'
   end,
}


return Module {
   prototype = OrderedMap,


   --- Module Functions
   -- @section functions

   --- Remove a key from a map.
   -- @function delete
   -- @tparam OrderedMap om a map
   -- @param key a key
   -- @treturn OrderedMap *om*, without *key*
   -- @usage
   --   delete(om, 'old')
   delete = X('delete(OrderedMap, any)', function(om, key)
      return set(om, key, nil)
   end),

   --- The entries of a map, as a list of tables of one pair each.
   -- This is the form that the constructor takes.
   -- @function entries
   -- @tparam OrderedMap om a map
   -- @treturn table the entries in order, with their number in field `n`
   -- @usage
   --   --> {{b = 1}, {a = 2}, n = 2}
   --   entries(OrderedMap {{b = 1}, {a = 2}})
   entries = X('entries(OrderedMap)', entries),

   --- Iterate over the keys and values of a map, in order.
   -- Don't add or remove keys while iterating.
   -- @function elems
   -- @tparam OrderedMap om a map
   -- @treturn function an iterator that returns a key and its value
   -- @treturn OrderedMap *om*
   -- @usage
   --   for key, value in elems(om) do print(key, value) end
   elems = X('elems(OrderedMap)', elems),

   --- The value of a key.
   -- @function get
   -- @tparam OrderedMap om a map
   -- @param key a key
   -- @return the value of *key*, or `nil`
   -- @usage
   --   local value = get(om, 'key')
   get = X('get(OrderedMap, any)', get),

   --- The keys of a map, in order.
   -- @function keys
   -- @tparam OrderedMap om a map
   -- @treturn table the keys in order, with their number in field `n`
   -- @usage
   --   --> {'b', 'a', n = 2}
   --   keys(OrderedMap {{b = 1}, {a = 2}})
   keys = X('keys(OrderedMap)', keys),

   --- Make a new map of the entries of the maps given.
   -- Keys are in the order they first appear, and a key that is in more
   -- than one map keeps its first place and the value of the last.
   -- @function merged
   -- @tparam OrderedMap ... maps to merge, where `nil` is skipped
   -- @treturn OrderedMap a new map
   -- @usage
   --   --> OrderedMap {a=3, b=2, c=4}
   --   merged(OrderedMap {{a = 1}, {b = 2}}, OrderedMap {{c = 4}, {a = 3}})
   merged = X('merged(<?OrderedMap...>)', merged),

   --- Make a new map of the values of a map, with a function applied.
   -- Keys keep their order, and a key whose function result is `nil` is
   -- left out.
   -- @function mapvalues
   -- @tparam OrderedMap om a map
   -- @tparam callable fn called with a value and then its key
   -- @treturn OrderedMap a new map
   -- @usage
   --   --> OrderedMap {a=10, b=20}
   --   mapvalues(OrderedMap {{a = 1}, {b = 2}}, function(v) return v * 10 end)
   mapvalues = X('mapvalues(OrderedMap, callable)', mapvalues),

   --- Make a new map of just some of the entries of a map.
   -- The entries are in the order of the map, and not of the keys.
   -- @function pluck
   -- @tparam OrderedMap om a map
   -- @tparam table keylist the keys to keep
   -- @treturn OrderedMap a new map
   -- @usage
   --   --> OrderedMap {a=1, c=3}
   --   pluck(OrderedMap {{a = 1}, {b = 2}, {c = 3}}, {'c', 'a'})
   pluck = X('pluck(OrderedMap, table)', pluck),

   --- Set the value of a key, or remove it with `nil`.
   -- A new key goes to the end of the map.
   -- @function set
   -- @tparam OrderedMap om a map
   -- @param key a key
   -- @param value the new value, or `nil` to remove *key*
   -- @treturn OrderedMap *om*
   -- @usage
   --   set(om, 'key', 'value')
   set = X('set(OrderedMap, any, ?any)', set),

   --- The number of keys in a map.
   -- Not its length, which is that of the sequence part of its fields:
   -- the keys are counted every time, so keep the result if you want it
   -- again.
   -- @function size
   -- @tparam OrderedMap om a map
   -- @treturn int the number of keys
   -- @usage
   --   --> 2
   --   size(OrderedMap {{b = 1}, {a = 2}})
   size = X('size(OrderedMap)', size),

   --- The values of a map, in the order of its keys.
   -- @function values
   -- @tparam OrderedMap om a map
   -- @treturn table the values in order, with their number in field `n`
   -- @usage
   --   --> {1, 2, n = 2}
   --   values(OrderedMap {{b = 1}, {a = 2}})
   values = X('values(OrderedMap)', values),
}
