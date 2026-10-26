--[[
 Prototype Oriented Programming for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2000-2026 std.prototype authors
]]
--[[--
 Scanner Prototype.

 This module returns a table of scanner helpers, as well as the prototype
 for a Scanner object.

 A Scanner reads a string of text one character at a time, for the
 lexer of a parser to build its tokens from.  It always knows where the
 next character is, and `peek` looks at characters that are not read yet,
 `next` reads them, `back` unreads them, and `take`, `skip` and `match`
 read a whole run of them in one call.

 Classes of character are sets, which join with `+`, and make a lexer
 read like its grammar:

    local Scanner = require 'std.prototype.scanner'.prototype
    local charset = require 'std.prototype.scanner'.charset

    local isspace = charset ' \t\r\n'
    local isdelimiter = charset '()"' + isspace

    local scanner = Scanner('(add 1 2)', 'sum.lsp')
    scanner:next()                      --> '('
    scanner:take(function(c)            --> 'add'
       return not isdelimiter[c]
    end)
    scanner:skip(isspace)
    scanner:match '%d+'                 --> '1'
    scanner:error 'unexpected end'      --> error: sum.lsp:1: unexpected end

 An index is the position of a character in the text, counting from 1.
 Where the cursor stands is the index of the next character to read, so
 `pos` is 1 before anything is read and one more than the length of the
 text at the end.

 In addition to the functionality described here, Scanner objects also
 have all the methods and metamethods of the @{prototype.object.prototype}
 (except where overridden here).

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> Scanner

 @module std.prototype.scanner
]]


local _ENV = require 'std.normalize' {
   'string.find',
   'string.format',
   'string.gmatch',
   'string.sub',
   max = math.max,
   Module = require 'std.prototype._base'.Module,
   Object = require 'std.prototype.object'.prototype,
   Set = require 'std.prototype.set'.prototype,
   argscheck = require 'std.prototype._base'.argscheck,
   nonempty = next,
}



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


-- A function that says whether a character is in the class *set*, which
-- is a function, a table with a true value for each character in it, as a
-- Set is, or a string of the characters.
local function member(set)
   if type(set) == 'function' then
      return set
   elseif type(set) == 'string' then
      return function(c)
         return find(set, c, 1, true) ~= nil
      end
   end
   return function(c)
      return set[c]
   end
end


-- The characters of the string *s*, as a Set.
local function charset(s)
   local chars = {}
   for i = 1, #s do
      chars[i] = sub(s, i, i)
   end
   return Set(chars)
end



--[[ ================ ]]--
--[[ Scanner Methods. ]]--
--[[ ================ ]]--


local function eof(self)
   return self.pos > #self.text
end


local function peek(self, offset)
   local i = self.pos + (offset or 0)
   if i >= 1 and i <= #self.text then
      return sub(self.text, i, i)
   end
end


local function next_chars(self, n)
   local r = sub(self.text, self.pos, self.pos + (n or 1) - 1)
   self.pos = self.pos + #r
   if r ~= '' then
      return r
   end
end


local function back(self, n)
   self.pos = max(1, self.pos - (n or 1))
   return self
end


local function lookahead(self, s)
   return sub(self.text, self.pos, self.pos + #s - 1) == s
end


local function match(self, pattern)
   local found = pack(find(self.text, '^' .. pattern, self.pos))
   if found[1] == nil then
      return nil
   end
   self.pos = found[2] + 1
   if found.n > 2 then
      return unpack(found, 3, found.n)
   end
   return sub(self.text, found[1], found[2])
end


local function take(self, set)
   local inset, first = member(set), self.pos
   while not eof(self) and inset(peek(self)) do
      self.pos = self.pos + 1
   end
   return sub(self.text, first, self.pos - 1)
end


local function skip(self, set)
   take(self, set)
   return self
end


-- Line numbers are found by counting from where the last was, so that
-- asking for the line of each token in turn does not count them again.
local function line(self, index)
   index = index or self.pos
   local from, n = self.lineindex, self.lineno
   if from == nil or index < from then
      from, n = 1, 1
   end
   for _ in gmatch(sub(self.text, from, index - 1), '\n') do
      n = n + 1
   end
   self.lineindex, self.lineno = index, n
   return n
end


local function scan_error(self, msg, index)
   local where = format('%d: ', line(self, index))
   if self.name ~= nil then
      where = self.name .. ':' .. where
   end
   -- Level 0, so that no position of Lua code is added to the message.
   error(where .. msg, 0)
end



--[[ ============== ]]--
--[[ Scanner Object. ]]--
--[[ ============== ]]--


local function X(decl, fn)
   return argscheck('std.prototype.scanner.' .. decl, fn)
end


--- Scanner prototype object.
-- @object prototype
-- @string[opt='Scanner'] _type object name
-- @see prototype.object.prototype
-- @usage
--   local Scanner = require 'std.prototype.scanner'.prototype
--   assert(prototype.type(Scanner) == 'Scanner')
--   local scanner = Scanner('text to scan', 'name of the source')


return Module {
   prototype = Object {
      _type = 'Scanner',

      --- Scanner object initialisation.
      --
      -- Returns a Scanner for *text*, with the cursor at the start.
      -- A table, as a type derived from this one is described with,
      -- has any field with a leading underscore, such as `_type`, put in
      -- the metatable, and no other fields.
      -- @init prototype._init
      -- @tparam table new uninitialised Scanner container object
      -- @string text the text to scan
      -- @string[opt] name what to call the source of *text* in errors
      _init = function(new, ...)
         local text, name = ...
         if type(text) == 'table' then
            local mt = {}
            for k, v in next, text do
               if type(k) == 'string' and sub(k, 1, 1) == '_' then
                  mt[k] = v
               else
                  error(format("Scanner field '%s' is not allowed", tostring(k)), 3)
               end
            end
            return nonempty(mt) and setmetatable(new, mt) or new
         end

         if type(text) ~= 'string' then
            argerror('Scanner', 1, format('string expected, got %s',
               select('#', ...) == 0 and 'no value' or type(text)), 3)
         elseif name ~= nil and type(name) ~= 'string' then
            argerror('Scanner', 2, format('string expected, got %s', type(name)), 3)
         end

         new.text, new.name, new.pos = text, name, 1
         return new
      end,

      __index = {
         --- Fields
         -- @section fields

         --- The text that is scanned.
         -- @string text

         --- Where the cursor is, the index of the next character to read.
         -- Set it with @{prototype:back}, and not directly, so that it
         -- stays within the text.
         -- @int pos

         --- What the source is called in errors, if anything.
         -- @string name

         --- Methods
         -- @section methods

         --- Whether the cursor is at the end of the text.
         -- @function prototype:eof
         -- @treturn boolean `true` if every character has been read
         -- @usage
         --   while not scanner:eof() do ... end
         eof = X('eof(table)', eof),

         --- Look at a character that is not read yet.
         -- @function prototype:peek
         -- @int[opt=0] offset 0 is the next character, 1 the one after,
         --   and a negative offset a character that is read already
         -- @treturn string|nil the character, or `nil` if there is none
         -- @usage
         --   if scanner:peek(1) == '-' then ... end
         peek = X('peek(table, [?int])', peek),

         --- Read characters.
         -- @function prototype:next
         -- @int[opt=1] n how many to read
         -- @treturn string|nil the characters read, fewer than *n* at the
         --   end of the text, or `nil` if there were none
         -- @usage
         --   local c = scanner:next()
         next = X('next(table, [?int])', next_chars),

         --- Unread characters, to read them again.
         -- The cursor stops at the start of the text.
         -- @function prototype:back
         -- @int[opt=1] n how many to unread
         -- @treturn prototype *scanner*
         -- @usage
         --   if scanner:next() ~= ',' then scanner:back() end
         back = X('back(table, [?int])', back),

         --- Whether the next characters are the text given.
         -- @function prototype:lookahead
         -- @string s the text to look for
         -- @treturn boolean `true` if the text is next
         -- @usage
         --   if scanner:lookahead '--[[' then ... end
         lookahead = X('lookahead(table, string)', lookahead),

         --- Read what a Lua pattern matches, if it matches next.
         -- The pattern is matched as if it started with `^`, from the
         -- cursor.
         -- @function prototype:match
         -- @string pattern a Lua pattern
         -- @return the captures of the pattern, or what it matched if it
         --   has none, and `nil` if it does not match
         -- @usage
         --   local digits = scanner:match '%d+'
         match = X('match(table, string)', match),

         --- Read the run of characters that are in a class.
         -- @function prototype:take
         -- @tparam table|function|string set a class of character, as a
         --   table with a true value for each, such as a Set, or a
         --   function that is true for each, or a string of them
         -- @treturn string the characters read, possibly none
         -- @usage
         --   local name = scanner:take(isidentifier)
         take = X('take(table, table|function|string)', take),

         --- Read the run of characters that are in a class, and drop them.
         -- @function prototype:skip
         -- @tparam table|function|string set a class of character
         -- @treturn prototype *scanner*
         -- @see prototype:take
         -- @usage
         --   scanner:skip(isspace)
         skip = X('skip(table, table|function|string)', skip),

         --- The line number of an index in the text.
         -- The first line is 1.  Line numbers are not counted until asked
         -- for, so they cost nothing to a scanner that is never asked.
         -- @function prototype:line
         -- @int[opt] index defaults to the cursor
         -- @treturn int the line that the character at *index* is on
         -- @usage
         --   local l = scanner:line()
         line = X('line(table, [?int])', line),

         --- Raise an error that says where in the text it is.
         -- The message is `name:line: msg`, or `line: msg` for a scanner
         -- with no name, and has no Lua position added to it.
         -- @function prototype:error
         -- @string msg what is wrong
         -- @int[opt] index defaults to the cursor
         -- @usage
         --   scanner:error "missing ')'"
         error = X('error(table, string, [?int])', scan_error),
      },

      --- Metamethods
      -- @section metamethods

      --- Return a string representation of this scanner.
      -- @function prototype:__tostring
      -- @treturn string the name of the source and the line of the cursor,
      --   or only the type, for a prototype that has no text
      -- @usage
      --   print(scanner) --> Scanner sum.lsp:1
      __tostring = function(self)
         local kind = getmetatable(self)._type
         if self.text == nil then
            return kind
         end
         return format('%s %s%d', kind,
            self.name ~= nil and self.name .. ':' or '', line(self))
      end,
   },


   --- Module Functions
   -- @section functions

   --- The characters of a string, as a Set.
   -- Sets join with `+`, so classes of characters are made from others.
   -- @function charset
   -- @string s a string of characters
   -- @treturn Set the set of the characters in *s*
   -- @usage
   --   local isspace = charset ' \t\r\n'
   --   local isdelimiter = charset '()' + isspace
   charset = X('charset(string)', charset),
}
