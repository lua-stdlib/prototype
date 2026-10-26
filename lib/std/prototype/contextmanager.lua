--[[
 Prototype Oriented Programming for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2000-2026 std.prototype authors
]]
--[[--
 Context Manager Prototype.

 This module returns a table of context manager helpers, as well as the
 prototype for a ContextManager object.

 A context manager holds a resource, such as an open file, that has to be
 released when the code that uses it is finished with it, whatever
 happens.  @{with} runs a function with the managers that it is given
 and releases them all afterwards, even when the function raises an
 error, which it raises again once they are released:

    local contextmanager = require 'std.prototype.contextmanager'
    local File, with = contextmanager.File, contextmanager.with

    with(File('input.txt', 'r'), File('output.txt', 'w'), function(input, output)
       output:write(input:read '*a')
    end)

 A manager passes the methods that it does not have to its resource, so
 `input:read` above is the `read` of the open file.  When the resource
 cannot be acquired, what makes the manager is `nil` and the reason, as
 `io.open` returns them, and `with` passes the function a `nil` for it
 and releases nothing.

 In addition to the functionality described here, ContextManager objects
 also have all the methods and metamethods of the
 @{prototype.object.prototype} (except where overridden here).

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> ContextManager

 @module std.prototype.contextmanager
]]


local _ENV = require 'std.normalize' {
   'io.close',
   'io.open',
   'io.popen',
   'os.remove',
   'os.tmpname',
   iotype = 'io.type',
   Module = require 'std.prototype._base'.Module,
   Object = require 'std.prototype.object'.prototype,
   argscheck = require 'std.prototype._base'.argscheck,
}


local ContextManager -- forward declaration



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


-- A manager passes a method that it does not have on to its resource.
local function passthrough(self, key)
   local context = rawget(self, 'context')
   local method = context ~= nil and context[key]
   if iscallable(method) then
      return function(_, ...)
         return method(context, ...)
      end
   end
end


-- Close the resource of *cm*, if it is an open file.
local function closefile(cm)
   return iotype(cm.context) == 'file' and close(cm.context)
end


-- A manager of what *acquirer* returns when called with the arguments,
-- which is released by calling *release* with the manager, or else nil
-- and what *acquirer* returns, when it gets nothing.
local function manage(release, acquirer, ...)
   local context, err = acquirer(...)
   if not context then
      return nil, err
   end
   return setmetatable({
      context = context,
      release = release,
      n       = select('#', ...), ...
   }, getmetatable(ContextManager))
end


local function with(...)
   local argu = pack(...)
   local block = argu[argu.n]
   argu[argu.n], argu.n = nil, argu.n - 1

   local result = pack(pcall(block, unpack(argu, 1, argu.n)))

   -- Release every manager that there is, last first, whatever happened,
   -- and keep the first error to raise afterwards.
   local failure
   for i = argu.n, 1, -1 do
      local cm = argu[i]
      if cm ~= nil then
         local ok, err = pcall(cm.release, cm)
         if not ok and failure == nil then
            failure = {err}
         end
      end
   end

   if not result[1] then
      error(result[2], 0)
   elseif failure ~= nil then
      error(failure[1], 0)
   end
   return unpack(result, 2, result.n)
end


local function slurp(cm, ...)
   if not cm then
      return cm, ...
   end
   return with(cm, function(h)
      return h:read '*a'
   end)
end



--[[ ======================= ]]--
--[[ ContextManager Object. ]]--
--[[ ======================= ]]--


local function X(decl, fn)
   return argscheck('std.prototype.contextmanager.' .. decl, fn)
end


--- ContextManager prototype object.
-- Call it, or the module, to make a manager of any resource.
-- @function prototype
-- @tparam callable release called with the manager to release the
--   resource
-- @tparam callable acquire called with the arguments to get the resource
-- @param ... arguments for *acquire*, which the manager keeps in its
--   list part, with their number in `n`
-- @treturn ContextManager|nil a manager of what *acquire* returns, which
--   is also in its `context` field, or `nil` if it returns none
-- @return the reason, if there is no manager, as *acquire* gave it
-- @usage
--   local cm = contextmanager(function(cm) cm.context:close() end, io.open, 'file', 'r')
-- @see File


ContextManager = Object {
   _type = 'ContextManager',

   --- Fields
   -- @section fields

   --- The resource that the manager holds.
   -- @field context

   --- The function that releases the resource, called as `cm:release()`.
   -- @function release

   --- The number of arguments that the resource was acquired with, which
   -- are in the list part of the manager.
   -- @int n

   --- Metamethods
   -- @section metamethods

   --- Pass methods that are not the manager's own on to its resource.
   -- @function __index
   -- @string key a method of the resource
   -- @treturn function that calls the method of the resource
   __index = passthrough,

   __call = function(_, release, acquirer, ...)
      return manage(release, acquirer, ...)
   end,
}


return Module {
   prototype = ContextManager,


   --- Module Functions
   -- @section functions

   --- A manager of a file, that is closed when it is released.
   -- The name of the file is in the manager as `filename`.
   -- @function File
   -- @string fname the name of the file
   -- @string[opt] mode how to open it, as for `io.open`
   -- @treturn ContextManager|nil a manager of the open file, or `nil`
   -- @return the reason, if there is no manager
   -- @usage
   --   with(File('input.txt', 'r'), function(input) return input:read '*a' end)
   File = X('File(string, [?string])', function(fname, mode)
      local cm, err = manage(closefile, open, fname, mode)
      if cm ~= nil then
         cm.filename = fname
      end
      return cm, err
   end),

   --- A manager of a pipe to or from a command, that is closed when it is
   -- released.
   -- The command is in the manager as `command`.
   -- @function Pipe
   -- @string cmd the command to run
   -- @string[opt] mode `'r'` to read its output, or `'w'` to write to its
   --   input, as for `io.popen`
   -- @treturn ContextManager|nil a manager of the pipe, or `nil`
   -- @return the reason, if there is no manager
   -- @usage
   --   local date = slurp(Pipe 'date')
   Pipe = X('Pipe(string, [?string])', function(cmd, mode)
      local cm, err = manage(closefile, popen, cmd, mode)
      if cm ~= nil then
         cm.command = cmd
      end
      return cm, err
   end),

   --- A manager of a temporary file, that is closed and removed when it is
   -- released.
   -- The name of the file is in the manager as `filename`.
   -- @function TmpFile
   -- @string[opt] fname the name of the file, which is one that `os.tmpname`
   --   makes by default
   -- @string[opt='w'] mode how to open it, as for `io.open`
   -- @treturn ContextManager|nil a manager of the open file, or `nil`
   -- @return the reason, if there is no manager
   -- @usage
   --   with(TmpFile(), function(tmp) tmp:write 'scratch' end)
   TmpFile = X('TmpFile([?string], [?string])', function(fname, mode)
      fname = fname or tmpname()
      local cm, err = manage(function(self)
         if closefile(self) then
            return remove(self.filename)
         end
         return false
      end, open, fname, mode or 'w')
      if cm ~= nil then
         cm.filename = fname
      end
      return cm, err
   end),

   --- Read everything from a manager of a file or pipe, and release it.
   -- A `nil` that there is no manager is passed on, with the reason that
   -- there is none, so that `slurp(File(fname))` is the contents of the
   -- file or else `nil` and why not.
   -- @function slurp
   -- @tparam ContextManager|nil cm a manager of something to read
   -- @param ... the reason there is no manager, to return with it
   -- @treturn string|nil what was read
   -- @usage
   --   local text, err = slurp(File 'input.txt')
   slurp = slurp,

   --- Run a function, and release the managers that it was given after.
   -- The function is called with the managers, and its results are the
   -- results of `with`.  The managers are released last first, even if the
   -- function raises an error, and that error is raised again afterwards;
   -- or else the first error of a release.  A `nil` for a resource that
   -- could not be acquired is passed to the function, and not released.
   -- @function with
   -- @tparam ContextManager|nil ... the managers to release afterwards
   -- @tparam callable block the function to call with them
   -- @return the results of *block*
   -- @usage
   --   with(File('a', 'w'), File('b', 'w'), function(a, b)
   --      a:write 'to a'
   --      b:write 'to b'
   --   end)
   with = with,
}
