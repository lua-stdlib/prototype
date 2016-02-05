--[[--
 List prototype.

 In addition to the functionality described here, List objects also
 have all the methods and metamethods of the @{prototype.object.prototype}
 (except where overridden here),

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> List

 @prototype prototype.list
]]


local table_unpack	= table.unpack or unpack


local _ = {
  object		= require "prototype.object",
  std			= require "prototype._base",
}

local Module		= _.std.object.Module
local Object		= _.object.prototype

local _ipairs		= _.std.ipairs
local _pairs		= _.std.pairs
local argscheck		= _.std.typecheck and _.std.typecheck.argscheck
local compare		= _.std.list.compare
local len		= _.std.operator.len

local _ENV		= _.std.strict and _.std.strict {} or {}

_ = nil



--[[ ================= ]]--
--[[ Implementatation. ]]--
--[[ ================= ]]--


local List


local function append (l, x)
  local r = l {}
  r[#r + 1] = x
  return r
end


local function concat (l, ...)
  local r = List {}
  for _, e in _ipairs {l, ...} do
    for _, v in _ipairs (e) do
      r[#r + 1] = v
    end
  end
  return r
end


local function rep (l, n)
  local r = List {}
  for i = 1, n do
    r = concat (r, l)
  end
  return r
end


local function sub (l, from, to)
  local r = List {}
  local lenl = len (l)
  from = from or 1
  to = to or lenl
  if from < 0 then
    from = from + lenl + 1
  end
  if to < 0 then
    to = to + lenl + 1
  end
  for i = from, to do
    r[#r + 1] = l[i]
  end
  return r
end



--[[ ================== ]]--
--[[ Type Declarations. ]]--
--[[ ================== ]]--


local function X (decl, fn)
  return argscheck and argscheck ("prototype.list." .. decl, fn) or fn
end


local methods = {
  --- Methods
  -- @section methods

  --- Append an item to a list.
  -- @function prototype:append
  -- @param x item
  -- @treturn prototype new list with *x* appended
  -- @usage
  -- --> List {"shorter", "longer"}
  -- longer = (List {"shorter"}):append "longer"
  append = X ("append (List, any)", append),

  --- Compare two lists element-by-element, from left-to-right.
  -- @function prototype:compare
  -- @tparam prototype|table m another list, or table
  -- @return -1 if *l* is less than *m*, 0 if they are the same, and 1
  --   if *l* is greater than *m*
  -- @usage
  -- if list1:compare (list2) == 0 then print "same" end
  compare = X ("compare (List, List|table)", compare),

  --- Concatenate the elements from any number of lists.
  -- @function prototype:concat
  -- @tparam prototype|table ... additional lists, or list-like tables
  -- @treturn prototype new list with elements from arguments
  -- @usage
  -- --> List {"shorter", "short", "longer", "longest"}
  -- longest = (List {"shorter"}):concat ({"short", "longer"}, {"longest"})
  concat = X ("concat (List, List|table...)", concat),

  --- Prepend an item to a list.
  -- @function prototype:cons
  -- @param x item
  -- @treturn prototype new list with *x* followed by elements of *l*
  -- @usage
  -- --> List {"x", 1, 2, 3}
  -- consed = (List {1, 2, 3}):cons "x"
  cons = X ("cons (List, any)", function (l, x) return List {x, table_unpack (l, 1, len (l))} end),

  --- Repeat a list.
  -- @function prototype:rep
  -- @int n number of times to repeat
  -- @treturn prototype *n* copies of *l* appended together
  -- @usage
  -- --> List {1, 2, 3, 1, 2, 3, 1, 2, 3}
  -- repped = (List {1, 2, 3}):rep (3)
  rep = X ("rep (List, int)", rep),

  --- Return a sub-range of a list.
  -- (The equivalent of @{string.sub} on strings; negative list indices
  -- count from the end of the list.)
  -- @function prototype:sub
  -- @int[opt=1] from start of range
  -- @int[opt=#l] to end of range
  -- @treturn prototype new list containing elements between *from* and *to*
  --   inclusive
  -- @usage
  -- --> List {3, 4, 5}
  -- subbed = (List {1, 2, 3, 4, 5, 6}):sub (3, 5)
  sub = X ("sub (List, ?int, ?int)", sub),

  --- Return a list with its first element removed.
  -- @function prototype:tail
  -- @treturn prototype new list with all but the first element of *l*
  -- @usage
  -- --> List {3, {4, 5}, 6, 7}
  -- tailed = (List {{1, 2}, 3, {4, 5}, 6, 7}):tail ()
  tail = X ("tail (List)", function (l) return sub (l, 2) end),
}


--- List prototype object.
-- @object prototype
-- @string[opt="List"] _type object name
-- @tfield[opt] table|function _init object initialisation
-- @see prototype.object.prototype
-- @usage
-- local List = require "prototype.list".prototype
-- assert (prototype.type (List) == "List")
List = Object {
  _type = "List",

  --- Metamethods
  -- @section metamethods

  --- Concatenate lists.
  -- @function prototype:__concat
  -- @tparam prototype|table m another list, or table (hash part is ignored)
  -- @see concat
  -- @usage
  -- new = alist .. {"append", "these", "elements"}
  __concat = concat,

  --- Append element to list.
  -- @function prototype:__add
  -- @param e element to append
  -- @see append
  -- @usage
  -- list = list + "element"
  __add = append,

  --- List order operator.
  -- @function prototype:__lt
  -- @tparam prototype m another list
  -- @see compare
  -- @usage
  -- max = list1 > list2 and list1 or list2
  __lt = function (list1, list2) return compare (list1, list2) < 0 end,

  --- List equality or order operator.
  -- @function prototype:__le
  -- @tparam prototype m another list
  -- @see compare
  -- @usage
  -- min = list1 <= list2 and list1 or list2
  __le = function (list1, list2) return compare (list1, list2) <= 0 end,

  __index = methods,
}


return Module {
  prototype = List,

  append  = methods.append,
  compare = methods.compare,
  concat  = methods.concat,
  cons    = methods.cons,
  rep     = methods.rep,
  sub     = methods.sub,
  tail    = methods.tail,
}
