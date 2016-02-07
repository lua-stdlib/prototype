--[[--
 Store an ordered sequence of elements.

 In addition to the functionality described here, Sequence objects also
 have all the methods and metamethods of the @{prototype.object.prototype}
 (except where overridden here),

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> Sequence

 @module prototype.sequence
]]

local tonumber		= tonumber

local math_min		= math.min
local table_unpack	= table.unpack or unpack


local Object		= require "prototype.object".prototype
local _			= require "prototype._base"

local Module		= _.Module
local ipairs		= _.ipairs
local argscheck		= _.typecheck and _.typecheck.argscheck
local len		= _.len

local _ENV		= _.strict and _.strict {} or {}

_ = nil



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local Sequence		-- forward declaration


local function append (l, x)
  local r = l {}
  r[#r + 1] = x
  return r
end


local function compare (l, m)
  local lenl, lenm = len (l), len (m)
  for i = 1, math_min (lenl, lenm) do
    local li, mi = tonumber (l[i]), tonumber (m[i])
    if li == nil or mi == nil then
      li, mi = l[i], m[i]
    end
    if li < mi then
      return -1
    elseif li > mi then
      return 1
    end
  end
  if lenl < lenm then
    return -1
  elseif lenl > lenm then
    return 1
  end
  return 0
end


local function concat (l, ...)
  local r = Sequence {}
  for _, e in ipairs {l, ...} do
    for _, v in ipairs (e) do
      r[#r + 1] = v
    end
  end
  return r
end


local function rep (l, n)
  local r = Sequence {}
  for i = 1, n do
    r = concat (r, l)
  end
  return r
end


local function sub (l, from, to)
  local r = Sequence {}
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



--[[ ================ ]]--
--[[ Sequence Object. ]]--
--[[ ================ ]]--


--- Sequence prototype object.
-- @object prototype
-- @string[opt="Sequence"] _type object name
-- @tfield[opt] table|function _init object initialisation
-- @see prototype.object.prototype
-- @usage
-- local Sequence = require "prototype.sequence".prototype
-- assert (prototype.type (Sequence) == "Sequence")


local function X (decl, fn)
  return argscheck and argscheck ("prototype.sequence." .. decl, fn) or fn
end


Sequence = Object {
  _type = "Sequence",

  __index = {
    --- Methods
    -- @section methods

    --- Append an item to a sequence.
    -- @function prototype:append
    -- @param x item
    -- @treturn prototype new sequence with *x* appended
    -- @usage
    -- --> Sequence {"shorter", "longer"}
    -- longer = (Sequence {"shorter"}):append "longer"
    append = X ("append (Sequence, any)", append),

    --- Compare two sequences element-by-element, from left-to-right.
    -- @function prototype:compare
    -- @tparam prototype|table m another sequence, or table
    -- @return -1 if *l* is less than *m*, 0 if they are the same, and 1
    --   if *l* is greater than *m*
    -- @usage
    -- if sequence1:compare (sequence2) == 0 then print "same" end
    compare = X ("compare (Sequence, Sequence|table)", compare),

    --- Concatenate the elements from any number of sequences.
    -- @function prototype:concat
    -- @tparam prototype|table ... additional sequences, or sequence-like tables
    -- @treturn prototype new sequence with elements from arguments
    -- @usage
    -- --> Sequence {"shorter", "short", "longer", "longest"}
    -- longest = (Sequence {"shorter"}):concat ({"short", "longer"}, {"longest"})
    concat = X ("concat (Sequence, Sequence|table...)", concat),

    --- Prepend an item to a sequence.
    -- @function prototype:cons
    -- @param x item
    -- @treturn prototype new sequence with *x* followed by elements of *l*
    -- @usage
    -- --> Sequence {"x", 1, 2, 3}
    -- consed = (Sequence {1, 2, 3}):cons "x"
    cons = X ("cons (Sequence, any)", function (l, x) return Sequence {x, table_unpack (l, 1, len (l))} end),

    --- Repeat a sequence.
    -- @function prototype:rep
    -- @int n number of times to repeat
    -- @treturn prototype *n* copies of *l* appended together
    -- @usage
    -- --> Sequence {1, 2, 3, 1, 2, 3, 1, 2, 3}
    -- repped = (Sequence {1, 2, 3}):rep (3)
    rep = X ("rep (Sequence, int)", rep),

    --- Return a sub-range of a sequence.
    -- (The equivalent of @{string.sub} on strings; negative sequence indices
    -- count from the end of the sequence.)
    -- @function prototype:sub
    -- @int[opt=1] from start of range
    -- @int[opt=#l] to end of range
    -- @treturn prototype new sequence containing elements between *from* and *to*
    --   inclusive
    -- @usage
    -- --> Sequence {3, 4, 5}
    -- subbed = (Sequence {1, 2, 3, 4, 5, 6}):sub (3, 5)
    sub = X ("sub (Sequence, ?int, ?int)", sub),

    --- Return a sequence with its first element removed.
    -- @function prototype:tail
    -- @treturn prototype new sequence with all but the first element of *l*
    -- @usage
    -- --> Sequence {3, {4, 5}, 6, 7}
    -- tailed = (Sequence {{1, 2}, 3, {4, 5}, 6, 7}):tail ()
    tail = X ("tail (Sequence)", function (l) return sub (l, 2) end),
  },


  --- Metamethods
  -- @section metamethods

  --- Concatenate sequences.
  -- @function prototype:__concat
  -- @tparam prototype|table m another sequence, or table (hash part is ignored)
  -- @see concat
  -- @usage
  -- new = asequence .. {"append", "these", "elements"}
  __concat = concat,

  --- Append element to sequence.
  -- @function prototype:__add
  -- @param e element to append
  -- @see append
  -- @usage
  -- sequence = sequence + "element"
  __add = append,

  --- Sequence order operator.
  -- @function prototype:__lt
  -- @tparam prototype m another sequence
  -- @see compare
  -- @usage
  -- max = sequence1 > sequence2 and sequence1 or sequence2
  __lt = function (sequence1, sequence2) return compare (sequence1, sequence2) < 0 end,

  --- Sequence equality or order operator.
  -- @function prototype:__le
  -- @tparam prototype m another sequence
  -- @see compare
  -- @usage
  -- min = sequence1 <= sequence2 and sequence1 or sequence2
  __le = function (sequence1, sequence2) return compare (sequence1, sequence2) <= 0 end,
}


return Module {
  prototype = Sequence,

  append  = Sequence.append,
  compare = Sequence.compare,
  concat  = Sequence.concat,
  cons    = Sequence.cons,
  rep     = Sequence.rep,
  sub     = Sequence.sub,
  tail    = Sequence.tail,
}
