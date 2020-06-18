# Maru (stage 3)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Assorted smaller changes

- a phony `define-constant`; only to denote the intention for now.
- several stuff backported from the latest `eval.l` & co.

## Hermetic isolation of the bootstrap stages

Use the *module* abstraction introduced in the previous stage to create a
*slave* module in the *host*, and load the entire code that will comprise
the *slave* (the next stage; `boot.l` and `eval.l`) into this isolated module.
See [early.l](bootstrapping/early.l) for how this is set up.

This isolation makes sure that the symbols and definitions of the *host* and
the *slave* are never mixed up unintentionally; `eval.l` will only ever see
definitions in the corresponding `boot.l`. The compiler from the *host*'s `emit.l`
gets loaded into the *host*, and it can cross the *host*/*slave*
boundary with explicit operators as needed.

This has made the situation much better regarding:

 - The structs that are defined in `boot.l` (and used in `eval.l`) don't need
   to have the same layout in the host and in the slave. You're free to
   rearrange fields or structure definition order. `eval.l` will pick up
   from its own `boot.l` whatever is needed for it in the level-shifted
   code.

 - A new [bootstrapping/](bootstrapping/) directory has been created
   to hold files that are loaded in different moments in the bootstrap
   process.

 - The build process has been updated to repeate three times the
   compilation, and check whether the 2nd and 3rd iteration produces
   the same output. (The first iteration may contain dummies that are
   needed for the bootstrap.

If there was an assembler written in Maru, then this slave VM
could be started under the full supervision of the host VM.

## Backported the latest from eval.l from the piumarta branch

All the semantic differences between the *minimal* and the latest `eval.l`
in the *piumarta* branch have been backported into our lineage.

**The head of his branch/stage should now behave identically with the
`eval.l` in the piumarta branch.**

There are some trivialities left to be addressed, but the executional
semantics should be the same. It's similar enough in behavior to at
least bootstrap itself and load/use the `boot.l` from the *piumarta*
branch.
