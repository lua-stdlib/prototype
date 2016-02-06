local _ENV		= _ENV
local getmetatable	= getmetatable
local next		= next
local pairs		= pairs
local select		= select
local setmetatable	= setmetatable
local type		= type
local unpack		= table.unpack or unpack

local table_concat	= table.concat
local table_pack	= table.pack or false
local table_sort	= table.sort


--[[ ================== ]]--
--[[ Initialize _DEBUG. ]]--
--[[ ================== ]]--


local _DEBUG, argscheck, strict
do
  -- Make sure none of these symbols leak out into the rest of the
  -- module, in case we can enable 'strict' mode at the end of the block.
  local pcall		= pcall
  local require		= require

  local ok, debug_init	= pcall (require, "std.debug_init")
  if ok then
    _DEBUG		= debug_init._DEBUG
  else
    local function choose (t)
      for k, v in pairs (t) do
        if _DEBUG == false then
          t[k] = v.fast
        elseif _DEBUG == nil then
          t[k] = v.default
        elseif type (_DEBUG) ~= "table" then
          t[k] = v.safe
        elseif _DEBUG[k] ~= nil then
          t[k] = _DEBUG[k]
        else
          t[k] = v.default
        end
      end
      return t
    end

    _DEBUG = choose {
      strict    = {default = true,  safe = true,  fast = false},
      argcheck  = {default = true,  safe = true,  fast = false},
    }
  end

  -- Unless strict was disabled (`_DEBUG = false`), or that module is not
  -- available, check for use of undeclared variables in this module...
  if _DEBUG.strict then
    ok, strict		= pcall (require, "strict")
    if ok then
      _ENV = strict {}
    else
      -- ...otherwise, the strict function is not available at all!
      _DEBUG.strict	= false
      strict		= false
    end
  end

  -- Unless strict was disabled (`_DEBUG = false`), or that module is not
  -- available, check for use of undeclared variables in this module...
  if _DEBUG.argcheck then
    local ok, typecheck	= pcall (require, "typecheck")
    if ok then
      argscheck		= typecheck.argscheck
    else
      -- ...otherwise, the strict function is not available at all!
      _DEBUG.argcheck	= false
      typecheck		= false
    end
  end
end



--[[ ================== ]]--
--[[ Normalize Lua API. ]]--
--[[ ================== ]]--


local function getmetamethod (x, n)
  local m = (getmetatable (x) or {})[n]
  if type (m) == "function" then return m end
  return (getmetatable (m) or {}).__call
end


-- Iterate over keys 1..n, where n is the key before the first nil
-- valued ordinal key (like Lua 5.3).
local ipairs = (_VERSION == "Lua 5.3") and ipairs or function (l)
  return function (l, n)
    n = n + 1
    if l[n] ~= nil then
      return n, l[n]
    end
  end, l, 0
end


-- Respect __len metamethod (like Lua 5.2+), otherwise always return one
-- less than the index of the first nil value in table x.
local function len (x)
  local m = getmetamethod (x, "__len")
  if m then return m (x) end
  if type (x) ~= "table" then return #x end

  local n = #x
  for i = 1, n do
    if x[i] == nil then return i -1 end
  end
  return n
end


-- Respect __pairs method, even in Lua 5.1.
if not pairs(setmetatable({},{__pairs=function() return false end})) then
  local _pairs = pairs
  pairs = function (t)
    return (getmetamethod (t, "__pairs") or _pairs) (t)
  end
end


-- Use the fastest pack implementation available.
local pack = table_pack or function (...)
  return { n = select ("#", ...), ...}
end



--[[ ================= ]]--
--[[ Shared Functions. ]]--
--[[ ================= ]]--


local function copy (dest, src)
  if src == nil then dest, src = {}, dest end
  for k, v in pairs (src) do dest[k] = v end
  return dest
end


-- Write pretty-printing based on:
--
--   John Hughes's and Simon Peyton Jones's Pretty Printer Combinators
--
--   Based on "The Design of a Pretty-printing Library in Advanced
--   Functional Programming", Johan Jeuring and Erik Meijer (eds), LNCS 925
--   http://www.cs.chalmers.se/~rjmh/Papers/pretty.ps
--   Heavily modified by Simon Peyton Jones, Dec 96

local function render (x, fns, roots)
  roots = roots or {}

  local function stop_roots (x)
    return roots[x] or render (x, fns, copy (roots))
  end

  if fns.term (x) then
    return fns.elem (x)

  else
    local buf, keys = {fns.open (x)}, {}	-- pre-buffer table open
    roots[x] = fns.elem (x)			-- recursion protection

    for k in pairs (x) do			-- collect keys
      keys[#keys + 1] = k
    end
    keys = fns.sort (keys)

    local pair, sep = fns.pair, fns.sep
    local kp, vp				-- previous key and value
    for _, k in ipairs (keys) do
      local v = x[k]
      buf[#buf + 1] = sep (x, kp, vp, k, v)	-- | buffer << separator
      buf[#buf + 1] = pair (x, kp, vp, k, v, stop_roots (k), stop_roots (v))
						-- | buffer << key/value pair
      kp, vp = k, v
    end
    buf[#buf + 1] = sep (x, kp, vp)		-- buffer << trailing separator
    buf[#buf + 1] = fns.close (x)		-- buffer << table close

    return table_concat (buf)			-- stringify buffer
  end
end


local function keysort (a, b)
  if type (a) == "number" then
    return type (b) ~= "number" or a < b
  else
    return type (b) ~= "number" and tostring (a) < tostring (b)
  end
end


local tostring_vtable = {
  open  = function (x) return "{" end,
  close = function (x) return "}" end,
  elem  = tostring,
  pair  = function (x, kp, vp, k, v, kstr, vstr)
            if k == 1 or type (k) == "number" and k -1 == kp then return vstr end
            return kstr .. "=" .. vstr
          end,
  sep   = function (x, kp, vp, kn, vn)
            if kp == nil or kn == nil then return "" end
            if type (kp) == "number" and kn ~= kp + 1 then return "; " end
            return ", "
          end,
  sort  = function (t)
            table_sort (t, keysort)
            return t
          end,
  term  = function (x)
            return type (x) ~= "table" or getmetamethod (x, "__tostring")
	  end,
}


return {
  _DEBUG	= _DEBUG,
  strict	= strict,
  typecheck	= typecheck,

  copy		= copy,
  getmetamethod = getmetamethod,
  ipairs        = ipairs,
  len		= len,
  pack		= pack,
  pairs         = pairs,
  str		= function (x) return render (x, tostring_vtable) end,
  unpack	= unpack,


  Module = function (t)
    return setmetatable (t, {
      _type  = "Module",
      __call = function (self, ...) return self.prototype (...) end,
    })
  end,

  mapfields = function (obj, src, map)
    local mt = getmetatable (obj) or {}

    -- Map key pairs.
    -- Copy all pairs when `map == nil`, but discard unmapped src keys
    -- when map is provided (i.e. if `map == {}`, copy nothing).
    if map == nil or next (map) then
      map = map or {}
      local k, v = next (src)
      while k do
        local key, dst = map[k] or k, obj
        local kind = type (key)
        if kind == "string" and key:sub (1, 1) == "_" then
          mt[key] = v
        elseif next (map) and kind == "number" and len (dst) + 1 < key then
          -- When map is given, but has fewer entries than src, stop copying
          -- fields when map is exhausted.
          break
        else
          dst[key] = v
        end
        k, v = next (src, k)
      end
    end

    -- Only set non-empty metatable.
    if next (mt) then
      setmetatable (obj, mt)
    end
    return obj
  end,
}
