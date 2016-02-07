# Stdlib NEWS - User visible changes

## Noteworthy changes in release 1.0 (2016-02-08) [stable]

### New features (since lua-stdlib-41.2)

  - Initial release, now separated out from lua-stdlib.

  - Objects and Modules are no longer conflated - what you get back from
    a `require "protatype.something"` is now ALWAYS a module:

    ```lua
    local object = require "prototype.object"
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
    and object prototype tables, the central `prototype.object.mapfields`
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
    `prototype.object.type`, because that just makes more sense.  Sorry!

### Bug fixes

  - You can now derive other types from `std.set` by passing a `_type`
    field in the init argument, just like the other table argument
    objects.

  - In order iteration with `__pairs` metamethod has been reinstated.
    There were no spec examples, and the implementation mysteriously
    went missing in a previous round of refactoring.

### Incompatible changes

  - Deprecated methods and functions have all been removed.

  - `std.tree` is now `prototype.trie` and defines a Trie object, no a
    Tree object.  The implementation has been a _Radix Tree_ (aka _Trie_)
    all along.

  - Now that the `prototype` field is used to reference a module's
    object prototype, `prototype.object.prototype` no longer return the
    object type of an argument. Additionally, for orthogonality with the
    way Lua itself uses `io.type` and `math.type` to get more detail about
    certain objects than `type` itself, `std.object.type` now operates
    purely on stdlib objects with a `_type` metatable field, and returns
    `nil` for anything else.

    To replicate the old behaviour, use this:

    ```lua
    local functional  = require "functional"
    local prototype   = require "prototype"
    local object_type = functional.any (prototype.object.type, io.type, type)
    ```

  - Objects no longer honor mangling and stripping `_functions` tables
    from objects during instantiation, instead move your actual object
    into the module `prototype` field, and add the module functions to    
    the parent table returned when the module is required.
