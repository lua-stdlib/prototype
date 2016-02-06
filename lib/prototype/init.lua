local pcall		= pcall
local rawset		= rawset
local require		= require
local setmetatable	= setmetatable



--- Metamethods
-- @section Metamethods

return setmetatable ({}, {
  --- Lazy loading of prototype modules.
  -- Don't load everything on initial startup, wait until first attempt
  -- to access a submodule, and then load it on demand.
  -- @function __index
  -- @string name submodule name
  -- @treturn table|nil the submodule that was loaded to satisfy the missing
  --   `name`, otherwise `nil` if nothing was found
  -- @usage
  -- local prototype = require "prototype"
  -- local Object = prototype.object.prototype
  __index = function (self, name)
    local ok, t = pcall (require, "prototype." .. name)
    if ok then
      rawset (self, name, t)
      return t
    end
  end,
})