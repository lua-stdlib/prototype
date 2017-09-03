local _MODREV, _SPECREV = 'git', '-1'

package = 'std.prototype'
version = _MODREV .. _SPECREV

description = {
   summary = 'Prototype Oriented Programming with Lua',
   detailed = [[
     A straight forward prototype-based object system, and a selection of
     useful objects build on it.
   ]],
   homepage = 'http://lua-stdlib.github.io/prototype',
   license = 'MIT/X11',
}

source = {
   url = 'git://github.com/lua-stdlib/prototype.git',
   --url = 'http://github.com/lua-stdlib/prototype/archive' .. _MODREV .. '.zip',
   --dir = 'prototype-' .. _MODREV,
}

dependencies = {
   'ldoc',
   'lua >= 5.1, < 5.4',
   'std.normalize >= 1.0.3',
}

build = {
   type = 'builtin',
   modules = {
      ['std.prototype']		  = 'lib/std/prototype/init.lua',
      ['std.prototype._base']	  = 'lib/std/prototype/_base.lua',
      ['std.prototype.container'] = 'lib/std/prototype/container.lua',
      ['std.prototype.object']	  = 'lib/std/prototype/object.lua',
      ['std.prototype.set']	  = 'lib/std/prototype/set.lua',
      ['std.prototype.strbuf']	  = 'lib/std/prototype/strbuf.lua',
      ['std.prototype.trie']	  = 'lib/std/prototype/trie.lua',
      ['std.prototype.version']	  = 'lib/std/prototype/version.lua',
  },
}
