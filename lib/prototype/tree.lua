--[[--
 Tree container prototype.

 This module returns a table of tree operators, as well as the prototype
 for a Tree container object.

 This is not a search tree, but rather a way to efficiently store and
 retrieve values stored with a path as a key, such as a multi-key
 keytable.  Although it does have iterators for walking the tree with
 various algorithms.

 In addition to the functionality described here, Tree containers also
 have all the methods and metamethods of the @{prototype.container.prototype}
 (except where overridden here),

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Tree

 @prototype prototype.tree
]]


local getmetatable	= getmetatable
local rawget		= rawget
local rawset		= rawset
local setmetatable	= setmetatable
local type		= type

local coroutine_wrap	= coroutine.wrap
local coroutine_yield	= coroutine.yield
local table_remove	= table.remove
local table_unpack	= table.unpack or unpack


local _ = {
  base			= require "prototype._base",
  container		= require "prototype.container",
}

local Container		= _.container.prototype
local Module		= _.base.Module

local argscheck		= _.base.typecheck and _.base.typecheck.argscheck
local ipairs		= _.base.ipairs
local len		= _.base.len
local pack		= _.base.pack
local pairs		= _.base.pairs

local _ENV		= _.base.strict and _.base.strict {} or {}

_ = nil



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local prototype -- forward declaration



--- Tree iterator.
-- @tparam function it iterator function
-- @tparam prototype|table tr tree container or tree-like table
-- @treturn string type ("leaf", "branch" (pre-order) or "join" (post-order))
-- @treturn table path to node (`{i1, ...in}`)
-- @treturn node node
local function _nodes (it, tr)
  local p = {}
  local function visit (n)
    if type (n) == "table" then
      coroutine_yield ("branch", p, n)
      for i, v in it (n) do
        p[#p + 1] = i
        visit (v)
        table_remove (p)
      end
      coroutine_yield ("join", p, n)
    else
      coroutine_yield ("leaf", p, n)
    end
  end
  return coroutine_wrap (visit), tr
end


-- No need to recurse because functables are second class citizens in
-- Lua:
-- func=function () print "called" end
-- func() --> "called"
-- functable=setmetatable ({}, {__call=func})
-- functable() --> "called"
-- nested=setmetatable ({}, {__call=functable})
-- nested()
-- --> stdin:1: attempt to call a table value (global 'd')
-- --> stack traceback:
-- -->	stdin:1: in main chunk
-- -->		[C]: in ?
local function callable (x)
  if type (x) == "function" then return x end
  return (getmetatable (x) or {}).__call
end


local function clone (t, nometa)
  local r = {}
  if not nometa then
    setmetatable (r, getmetatable (t))
  end
  local d = {[t] = r}
  local function copy (o, x)
    for i, v in pairs (x) do
      if type (v) == "table" then
        if not d[v] then
          d[v] = {}
          if not nometa then
            setmetatable (d[v], getmetatable (v))
          end
          o[i] = copy (d[v], v)
        else
          o[i] = d[v]
        end
      else
        o[i] = v
      end
    end
    return o
  end
  return copy (r, t)
end


local function ielems (t)
  -- capture ipairs iterator initial state
  local fn, istate, ctrl = ipairs (t)
  return function (state, _)
    local v
    ctrl, v = fn (state, ctrl)
    if ctrl then return v end
  end, istate, true -- wrapped initial state
end


local function get (t, k)
  return t and t[k] or nil
end


local function last (t) return t[len (t)] end


local function leaves (it, tr)
  local function visit (n)
    if type (n) == "table" then
      for _, v in it (n) do
        visit (v)
      end
    else
      coroutine_yield (n)
    end
  end
  return coroutine_wrap (visit), tr
end


local function merge (t, u)
  for ty, p, n in _nodes (pairs, u) do
    if ty == "leaf" then
      t[p] = n
    end
  end
  return t
end


local function reduce (fn, d, ifn, ...)
  local argt
  if not callable (ifn) then
    ifn, argt = pairs, pack (ifn, ...)
  else
    argt = pack (...)
  end

  local nextfn, state, k = ifn (table_unpack (argt, 1, argt.n))
  local t = pack (nextfn (state, k))		-- table of iteration 1

  local r = d					-- initialise accumulator
  while t[1] ~= nil do				-- until iterator returns nil
    k = t[1]
    r = fn (r, table_unpack (t, 1, t.n))	-- pass all iterator results to fn
    t = pack (nextfn (state, k))		-- maintain loop invariant
  end
  return r
end



--[[ ============ ]]--
--[[ Tree Object. ]]--
--[[ ============ ]]--


local function X (decl, fn)
  return argscheck and argscheck ("prototype.tree." .. decl, fn) or fn
end


--- Return the object type, if set, otherwise the Lua type.
-- @param x item to act on
-- @treturn string object type of *x*, otherwise `type (x)`
local function _type (x)
  return (getmetatable (x) or {})._type or type (x)
end


--- Tree prototype object.
-- @object prototype
-- @string[opt="Tree"] _type object name
-- @see prototype.container.prototype
-- @usage
-- local tree = require "prototype.tree"
-- local Tree = tree.prototype
-- local tr = Tree {}
-- tr[{"branch1", 1}] = "leaf1"
-- tr[{"branch1", 2}] = "leaf2"
-- tr[{"branch2", 1}] = "leaf3"
-- print (tr[{"branch1"}])      --> Tree {leaf1, leaf2}
-- print (tr[{"branch1", 2}])   --> leaf2
-- print (tr[{"branch1", 3}])   --> nil
-- --> leaf1	leaf2	leaf3
-- for leaf in tree.leaves (tr) do
--   io.write (leaf .. "\t")
-- end
prototype = Container {
  _type = "Tree",

  --- Metamethods
  -- @section metamethods

  --- Deep retrieval.
  -- @function prototype:__index
  -- @param i non-table, or list of keys `{i1, ...i_n}`
  -- @return `tr[i1]...[i_n]` if *i* is a key list, `tr[i]` otherwise
  -- @todo the following doesn't treat list keys correctly
  --       e.g. tr[{{1, 2}, {3, 4}}], maybe flatten first?
  -- @usage
  -- del_other_window = keymap[{"C-x", "4", KEY_DELETE}]
  __index = function (tr, i)
    if _type (i) == "table" then
      return reduce (get, tr, ielems, i)
    else
      return rawget (tr, i)
    end
  end,

  --- Deep insertion.
  -- @function prototype:__newindex
  -- @param i non-table, or list of keys `{i1, ...i_n}`
  -- @param[opt] v value
  -- @usage
  -- function bindkey (keylist, fn) keymap[keylist] = fn end
  __newindex = function (tr, i, v)
    if _type (i) == "table" then
      for n = 1, len (i) - 1 do
        if _type (tr[i[n]]) ~= "Tree" then
          rawset (tr, i[n], prototype {})
        end
        tr = tr[i[n]]
      end
      rawset (tr, last (i), v)
    else
      rawset (tr, i, v)
    end
  end,
}


return Module {
  prototype = prototype,

  --- Functions
  -- @section functions

  --- Make a deep copy of a tree or table, including any metatables.
  -- @function clone
  -- @tparam table tr tree or tree-like table
  -- @tparam boolean nometa if non-`nil` don't copy metatables
  -- @treturn prototype|table a deep copy of *tr*
  -- @see std.table.clone
  -- @see prototype.object.clone
  -- @usage
  -- tr = {"one", {two=2}, {{"three"}, four=4}}
  -- copy = clone (tr)
  -- copy[2].two=5
  -- assert (tr[2].two == 2)
  clone = X ("clone (table, ?boolean|:nometa)", clone),

  --- Tree iterator which returns just numbered leaves, in order.
  -- @function ileaves
  -- @tparam prototype|table tr tree or tree-like table
  -- @treturn function iterator function
  -- @treturn prototype|table the tree *tr*
  -- @see inodes
  -- @see leaves
  -- @usage
  -- --> t = {"one", "three", "five"}
  -- for leaf in ileaves {"one", {two=2}, {{"three"}, four=4}}, foo="bar", "five"}
  -- do
  --   t[#t + 1] = leaf
  -- end
  ileaves = X ("ileaves (table)", function (t) return leaves (ipairs, t) end),

  --- Tree iterator over numbered nodes, in order.
  --
  -- The iterator function behaves like @{nodes}, but only traverses the
  -- array part of the nodes of *tr*, ignoring any others.
  -- @function inodes
  -- @tparam prototype|table tr tree or tree-like table to iterate over
  -- @treturn function iterator function
  -- @treturn tree|table the tree, *tr*
  -- @see nodes
  inodes = X ("inodes (table)", function (t) return _nodes (ipairs, t) end),

  --- Tree iterator which returns just leaves.
  -- @function leaves
  -- @tparam table t tree or tree-like table
  -- @treturn function iterator function
  -- @treturn table *t*
  -- @see ileaves
  -- @see nodes
  -- @usage
  -- for leaf in leaves {"one", {two=2}, {{"three"}, four=4}}, foo="bar", "five"}
  -- do
  --   t[#t + 1] = leaf
  -- end
  -- --> t = {2, 4, "five", "foo", "one", "three"}
  -- table.sort (t, lambda "=tostring(_1) < tostring(_2)")
  leaves = X ("leaves (table)", function (t) return leaves (pairs, t) end),

  --- Destructively deep-merge one tree into another.
  -- @function merge
  -- @tparam table t destination tree
  -- @tparam table u table with nodes to merge
  -- @treturn table *t* with nodes from *u* merged in
  -- @see std.table.merge
  -- @usage
  -- merge (dest, {{exists=1}, {{not = {present = { inside = "dest" }}}}})
  merge = X ("merge (table, table)", merge),

  --- Tree iterator over all nodes.
  --
  -- The returned iterator function performs a depth-first traversal of
  -- `tr`, and at each node it returns `{node-type, tree-path, tree-node}`
  -- where `node-type` is `branch`, `join` or `leaf`; `tree-path` is a
  -- list of keys used to reach this node, and `tree-node` is the current
  -- node.
  --
  -- Note that the `tree-path` reuses the same table on each iteration, so
  -- you must `table.clone` a copy if you want to take a snap-shot of the
  -- current state of the `tree-path` list before the next iteration
  -- changes it.
  -- @function nodes
  -- @tparam prototype|table tr tree or tree-like table to iterate over
  -- @treturn function iterator function
  -- @treturn prototype|table the tree, *tr*
  -- @see inodes
  -- @usage
  -- -- tree = +-- node1
  -- --        |    +-- leaf1
  -- --        |    '-- leaf2
  -- --        '-- leaf 3
  -- tree = Tree { Tree { "leaf1", "leaf2"}, "leaf3" }
  -- for node_type, path, node in nodes (tree) do
  --   print (node_type, path, node)
  -- end
  -- --> "branch"   {}      {{"leaf1", "leaf2"}, "leaf3"}
  -- --> "branch"   {1}     {"leaf1", "leaf2")
  -- --> "leaf"     {1,1}   "leaf1"
  -- --> "leaf"     {1,2}   "leaf2"
  -- --> "join"     {1}     {"leaf1", "leaf2"}
  -- --> "leaf"     {2}     "leaf3"
  -- --> "join"     {}      {{"leaf1", "leaf2"}, "leaf3"}
  -- os.exit (0)
  nodes = X ("nodes (table)", function (t) return _nodes (pairs, t) end),
}
