--[[--
 Object prototype.

 This module provides a specialization of the @{prototype.container.prototype}
 with the addition of object methods.  In addition to the functionality
 described here, object prototypes also have all the methods and
 metamethods of the @{prototype.container.prototype}.

 Note that object methods are stored in the `__index` field of their
 metatable, and so cannot also use the `__index` metamethod to lookup
 references with square brackets.  Use a @{prototype.container.prototype} based
 object if you want to do that.

 Prototype Chain
 ---------------

       table
        `-> Container
             `-> Object

 @prototype prototype.object
]]


local getmetatable	= getmetatable


local _ = {
  container		= require "prototype.container",
  std			= require "prototype._base",
}

local Container 	= _.container.prototype
local Module		= _.std.object.Module

local argscheck		= _.std.typecheck and _.std.typecheck.argscheck
local getmetamethod	= _.std.getmetamethod
local mapfields		= _.std.object.mapfields
local merge		= _.std.base.merge

local _ENV		= _.std.strict and _.std.strict {} or {}

_ = nil



--[[ ================= ]]--
--[[ Implementatation. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return argscheck and argscheck ("prototype.object." .. decl, fn) or fn
end


--- Methods
-- @section methods

local methods = {
  --- Return a clone of this object and its metatable.
  --
  -- This function is useful if you need to override the normal use of
  -- the `__call` metamethod for object cloning, without losing the
  -- ability to clone an object.
  -- @function prototype:clone
  -- @param ... arguments to prototype's *\_init*, often a single table
  -- @treturn prototype a clone of this object, with shared or merged
  --   metatable as appropriate
  -- @see prototype.container.__call
  -- @usage
  -- local Node = Object { _type = "Node" }
  -- -- A trivial FSA to recognize powers of 10, either "0" or a "1"
  -- -- followed by zero or more "0"s can transition to state 'finish'
  -- local states; states = {
  --   start  = Node { ["1"] = states[1], ["0"] = states.finish },
  --   [1]    = Node { ["0"] = states[1], [""] = states.finish },
  --   finish = Node {},
  -- }
  clone = getmetamethod (Container, "__call"),


  --- Object Functions
  -- @section objfunctions

  --- Return *new* with references to the fields of *src* merged in.
  --
  -- You can change the value of this function in an object, and that
  -- new function will be called during cloning instead of the
  -- standard @{prototype.container.mapfields} implementation.
  -- @function prototype.mapfields
  -- @tparam table new partially instantiated clone container
  -- @tparam table src @{clone} argument table that triggered cloning
  -- @tparam[opt={}] table map key renaming specification in the form
  --   `{old_key=new_key, ...}`
  -- @treturn table merged public fields from *new* and *src*, with a
  --   metatable of private fields (if any), both renamed according to
  --   *map*
  -- @see prototype.container.mapfields
  mapfields = X ("mapfields (table, table|object, ?table)", mapfields),
}


--- Object prototype.
-- @object prototype
-- @string[opt="Object"] _type object name
-- @tfield[opt] table|function _init object initialisation
-- @usage
-- local Object = require "prototype.object".prototype
-- local Process = Object {
--   _type = "Process",
--   _init = { "status", "out", "err" },
-- }
-- local process = Process {
--   procs[pid].status, procs[pid].out, procs[pid].err, -- auto assigned
--   command = pipeline[pid],                           -- manual assignment
-- }
local prototype = Container {
  _type  = "Object",

  --- Metamethods
  -- @section metamethods

  --- Return an in-order iterator over public object fields.
  -- @function prototype:__pairs
  -- @treturn function iterator function
  -- @treturn Object *self*
  -- @usage
  -- for k, v in prototype.pairs (anobject) do process (k, v) end

  __index = methods,
}


return Module {
  prototype	= prototype,
  type		= function (x) return (getmetatable (x) or {})._type end,
}
