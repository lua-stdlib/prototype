# std.prototype NEWS - User visible changes

## Noteworthy changes in release ?.? (????-??-??) [?]



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
