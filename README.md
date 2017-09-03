Prototype Oriented Programming with Lua
=======================================

by the [prototype project][github]

[![License](http://img.shields.io/:license-mit-blue.svg)](http://mit-license.org)
[![travis-ci status](https://secure.travis-ci.org/lua-stdlib/prototype.png?branch=master)](http://travis-ci.org/lua-stdlib/prototype/builds)
[![codecov.io](https://codecov.io/github/lua-stdlib/prototype/coverage.svg?branch=master)](https://codecov.io/github/lua-stdlib/prototype?branch=master)
[![Stories in Ready](https://badge.waffle.io/lua-stdlib/prototype.png?label=ready&title=Ready)](https://waffle.io/lua-stdlib/prototype)


This is a collection of Prototype Oriented Programming libraries for
Lua 5.1 (including LuaJIT), 5.2 and 5.3. The libraries are copyright by
their authors 2000-2016 (see the [AUTHORS][] file for details), and
released under the [MIT license][mit] (the same license as Lua itself).
There is no warranty.

_prototype_ has no run-time prerequisites beyond a standard Lua system,
though it will take advantage of [stdlib][], [strict][] and [typecheck][]
if they are installed.

[authors]: http://github.com/lua-stdlib/prototype/blob/master/AUTHORS.md
[github]: http://github.com/lua-stdlib/prototype/ "Github repository"
[lua]: http://www.lua.org "The Lua Project"
[mit]: http://mit-license.org "MIT License"
[stdlib]: https://github.com/lua-stdlib/lua-stdlib "Standard Lua Libraries"
[strict]: https://github.com/lua-stdlib/strict "strict variables"
[typecheck]: https://github.com/gvvaughan/typecheck "function type checks"


Installation
------------

The simplest and best way to install prototype is with [LuaRocks][]. To
install the latest release (recommended):

```bash
    luarocks install prototype
```

To install current git master (for testing, before submitting a bug
report for example):

```bash
    luarocks install http://raw.githubusercontent.com/lua-stdlib/prototype/master/prototype-git-1.rockspec
```

The best way to install without [LuaRocks][] is to copy the `prototype`
folder and its contents into a directory on your package search path.

[luarocks]: http://www.luarocks.org "Lua package manager"


Documentation
-------------

The latest release of these libraries is [documented in LDoc][github.io].
Pre-built HTML files are included in the release.

[github.io]: http://lua-stdlib.github.io/prototype


Bug reports and code contributions
----------------------------------

These libraries are written and maintained by their users.

Please make bug reports and suggestions as [GitHub Issues][issues].
Pull requests are especially appreciated.

But first, please check that your issue has not already been reported by
someone else, and that it is not already fixed by [master][github] in
preparation for the next release (see Installation section above for how
to temporarily install master with [LuaRocks][]).

There is no strict coding style, but please bear in mind the following
points when proposing changes:

0. Follow existing code. There are a lot of useful patterns and avoided
   traps there.

1. 3-character indentation using SPACES in Lua sources: It makes rogue
   TABs easier to see, and lines up nicely with 'if' and 'end' keywords.

2. Simple strings are easiest to type using single-quote delimiters,
   saving double-quotes for where a string contains apostrophes.

3. Save horizontal space by only using SPACEs where the parser requires
   them.

4. Use vertical space to separate out compound statements to help the
   coverage reports discover untested lines.

[issues]: http://github.com/lua-stdlib/prototype/issues
