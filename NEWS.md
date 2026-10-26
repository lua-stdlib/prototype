# std.prototype NEWS - User visible changes

## Noteworthy changes in release ?.? (????-??-??) [?]

### New features

  - New `std.prototype.orderedmap` has an `OrderedMap` container, a table
    that remembers the order in which its keys were added.  Write the
    entries of a new one as a list of tables of one pair each,
    `OrderedMap {{core = 'core.c'}, {util = 'util.c'}}`, read and write its
    fields as for any table, and iterate in order with `elems`.  New keys
    go to the end, a key keeps its place when its value changes, and
    `nil` removes it.  A map is a table and not a list, so `#` and `len`
    are not its number of keys: `size` counts them.  The module also has
    `get`, `set`, `delete`, `keys`, `values`, `entries`, `merged`,
    `pluck` and `mapvalues`.

  - New `std.prototype.scanner` has a `Scanner` object that reads a
    string of text for the lexer of a parser: `peek`, `next` and `back`
    look at, read and unread characters, `lookahead` and `match` test
    for text or a Lua pattern, and `take` and `skip` read a run of the
    characters in a class, which is a Set, a function or a string.
    `line` finds the line number of an index when it is asked for,
    and `error` raises an error that says where it is.  The module
    function `charset` makes a Set of the characters of a string, and
    sets join with `+`.

  - New `std.prototype.contextmanager` has a `ContextManager` object that
    holds a resource until it is released, and passes the methods that it
    does not have to the resource, with `File`, `Pipe` and `TmpFile`
    managers of an open file, a pipe and a temporary file that is removed
    afterwards.  `with(manager..., function)` calls the function with
    the managers and releases them last first, even when the function
    raises an error, which is raised again once they are released, and
    `slurp(manager)` reads all that a file or a pipe has and releases it.
    A resource that cannot be acquired makes `nil` and the reason, as
    `io.open` does, which `with` and `slurp` pass on.


## Noteworthy changes in release 2 (2026-10-20) [stable]

### New features

  - std.prototype builds with luke instead of make.  To install current
    git master, use the `std.prototype-dev-1.rockspec`:

    ```bash
    luarocks install https://raw.githubusercontent.com/lua-stdlib/prototype/master/std.prototype-dev-1.rockspec
    ```

### Incompatible changes

  - std.prototype needs std.normalize 2.0 or later, whose std._debug
    settings it follows.

### Bug fixes

  - With typecheck installed, a container prototype called with a table
    `_init` diagnoses a missing or extra argument, rather than raising
    "variable 'argcheck' is not declared" under std.strict, or not
    checking at all without it.

  - Assigning through a key list into a trie keeps its existing trie
    branches, even those of a type derived from Trie, and makes new
    branches of the same type as that trie, rather than replacing
    branches with plain Tries.


## Noteworthy changes in release 1.1 (2020-07-26) [stable]

### New Features

  - Initial support for Lua 5.4 and 5.5.


## Noteworthy changes in release 1.0.1 (2016-02-07) [stable]

### Bug fixes

  - The former lua-stdlib `strict` module, has moved to `std.strict`
    to avoid confusion with the original PUC-Rio strict.lua.  The base
    module now looks for it there.


## Noteworthy changes in release 1.0 (2016-02-07) [stable]

### New features (since lua-stdlib-41.2)

  - Initial release, now separated out from lua-stdlib.

  - Objects and Modules are no longer conflated - what you get back from
    a `require "std.prototype.something"` is now ALWAYS a module:

    ```lua
    local object = require "std.prototype.object"
    assert (object.type (object) == "Module")
    ```

    And the modules that provide objects have a new `prototype` field
    that contains the prototye for that kind of object:

    ```lua
    local Object = object.prototype
    assert (object.type (Object) == "Object")
    ```

    For backwards compatibility, if you call the module with a
    constructor table, the previous recommended way to disambiguate
    between a module and the object it prototyped, that table is passed
    through to the module's object prototype.

  - Now that we have proper separation of concerns between module tables
    and object prototype tables, the central `std.prototype.object.mapfields`
    instantiation function is much cleaner and faster.

  - We used to have an object module method, `std.object.type`, which
    often got imported using:

    ```lua
    local prototype = require "std.object".type
    ```

    So we renamed it to `std.object.prototype` to avoid a name clash with
    the `type` symbol, and subsequently deprecated the earlier equivalent
    `type` method; but that was a mistake, because core Lua provides `type`,
    and `io.type` (and in recent releases, `math.type`).  So now, for
    orthogonality with core Lua, we're going back to using
    `std.prototype.object.type`, because that just makes more sense.  Sorry!

### Bug fixes

  - You can now derive other types from `std.prototype.set` by passing a
    `_type` field in the init argument, just like the other table argument
    objects.

  - In-order iteration with `__pairs` metamethod has been reinstated.
    There were no spec examples, and the implementation mysteriously
    went missing in a previous round of refactoring.

### Incompatible changes

  - Deprecated methods and functions have all been removed.

  - `std.tree` is now `std.prototype.trie` and defines a Trie object, not a
    Tree object.  The implementation has been a _Radix Tree_ (aka _Trie_)
    all along.

  - Objects no longer honor mangling and stripping `_functions` tables
    from objects during instantiation, instead move your actual object
    into the module `prototype` field, and add the module functions to    
    the parent table returned when the module is required.
