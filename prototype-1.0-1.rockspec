package = "prototype"
version = "git-1"

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
    ["std.container"]	= "lib/std/container.lua",
    ["std.list"]	= "lib/std/list.lua",
    ["std.object"]	= "lib/std/object.lua",
    ["std.set"]		= "lib/std/set.lua",
    ["std.strbuf"]	= "lib/std/strbuf.lua",
    ["std.tree"]	= "lib/std/tree.lua",
  },
}
