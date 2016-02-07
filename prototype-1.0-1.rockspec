package = "prototype"
version = "1.0-1"

description = {
  summary = "Prototype Oriented Programming with Lua",
  detailed = [[
    A straight forward prototype-based object system, and a selection of
    useful objects build on it.
  ]],
  homepage = "http://lua-stdlib.github.io/prototype",
  license = "MIT/X11",
}

source = {
  url = "git://github.com/lua-stdlib/prototype.git",
}

dependencies = {
  "lua >= 5.1, < 5.4",
}

build = {
  type = "builtin",
  modules = {
    prototype			= "lib/prototype/init.lua",
    ["prototype._base"]		= "lib/prototype/_base.lua",
    ["prototype.container"]	= "lib/prototype/container.lua",
    ["prototype.init"]		= "lib/prototype/init.lua",
    ["prototype.object"]	= "lib/prototype/object.lua",
    ["prototype.sequence"]	= "lib/prototype/sequence.lua",
    ["prototype.set"]		= "lib/prototype/set.lua",
    ["prototype.strbuf"]	= "lib/prototype/strbuf.lua",
    ["prototype.trie"]		= "lib/prototype/trie.lua",
  },
}
