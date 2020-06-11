# Maru (stage 2)

> **NOTE:** This readme only covers this specific stage of Maru. The full README.md file can be found in the git branch of the latest stage.

## Assorted smaller changes

- -c command line arg to call a function (used by the makefile/bootstrap)

## New abstraction: *module*

This stage introduces the concept of *modules*. They will be used by the next stage to hermetically isolate the *host* and the *slave* universes in the bootstrap process. Modules can be thought of as isolated Maru universes that can peek into each other using the following new primitives:

- `(eval-in-module form module)`
- `[set-]current-module`
- `create-module`

A module is a struct with two slots:
- `symbols` to hold the interned symbols
- `env` to hold the module-global definitions (this used to be `*globals*`)

Objects are instantiated into the same heap, but otherwise everything else should be isolated between modules, including the Maru primitives that are instantiated by the eval executable at startup, and that affect the evaluation rules of programs.

The **reader** has been extended to read `foo:bar` the following way: `foo` will be interpreted as a variable and assumed to resolve to a module instance in the env of the current module. Then `bar` will be interned into this newly looked up module. Note: this does not affect evaluation; it only affects the interning of symbols.
