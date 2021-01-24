# Maru's bootstrap process

## Overview

A language evolves by the introduction of new features (optimizations, new primitives, etc).
If you want to use such a novel language feature in its own implementation,
then you need to *bootstrap* it:

1) First, implement the support for it in your compiler and/or eval, and produce
   an executable that can already compile and/or eval this new version of the language.

2) After that, you can start using this feature, and now you may even rewrite the
   implementation of this very feature, and use/assume this feature in its own
   implementation.

It's a confusing enough process, therefore it makes sense to fork the codebase at
the point between 1) and 2). Strictly speaking, it would be enough to git checkout
and build a specific prior commit to provide an executable to execute the bootstrap
process, but it's better to have separate branches.

Once it's working fine, the old branch becomes irrelevant/stale, except for:

  - Didactic purposes: to make it easier to understand how a self-hosted language grows.

  - Aesthetics: cherry-picking or backporting changes wouldn't be possible without
    having separate branches.

  - "Oh God, we have lost all the executables!" -- bootstrap again all the way up
    from a C implementation.
    
  - Sometimes the implementation of the new feature simply requires two parallel,
    wildly diverging instances of the codebase, until the new feature is fully
    implemented/debugged/bootstrapped.

  - Secure computing requires, above all, trusing your compiler.
    [Reproducible builds](https://en.wikipedia.org/wiki/Reproducible_builds),
    and being able to bootstrap your compiler on top of multiple platforms is useful
    for achieving it. See
    [here](https://www.acsa-admin.org/countering-trusting-trust-through-diverse-double-compiling/), and
    [here](http://c2.com/cgi/wiki?TheKenThompsonHack) for more.

> NOTE: do not confuse our notion of a *stage* (as in 'developmental stages') with e.g.
> [the 3 bootstrap stages while compiling GCC](https://gcc.gnu.org/install/build.html).
> Our notion is an endless iterative process of evolving the language.
> Suggestions for a better nomenclature are welcome!

## The bootstrap process

The bootstrap process in general is the following:

 1) Stage `n` checks out and builds its parent/hosting stage under `build/` (typically stage
    `(n-1)` of the same language) to acquire an `eval` executable.

 2) Using that executable and the compiler of the previous stage, it compiles a
    version of itself that can already load and compile the codebase in stage `n`,
    but the resulting executable may not be fully functional yet (in this phase the
    `evolving?` variable is true). It's called `eval1` in the build process.
    **Note** that this phase is not always necessary, depending on the nature of
    the new features that are being bootstrapped, and in some stages it is not
    done. It's needed when we introduce a new feature that the compiler itself
    needs to be aware of (either because its implementation relies on this feature,
    or e.g. in the case of the introduction of modules it needs to reach through
    module boundaries at certain places).

 3) Then it uses the resulting, potentially only semi-functional `eval1` executable to
    now compile itself using its own compiler, which will yield the final, fully
    functional `eval2` executable.

 4) Optionally, the `test-bootstrap` makefile target runs one more cycle to produce
    `eval3`, and checks if the compiler's output is identical with that of the
    previous step.

The `boot.l` and `emit.l` files are kept in the same branch with the `eval.l`
whose semantics they are assuming, i.e. the `eval1` executable of the `maru.2`
stage is built by the `eval` executable, the `boot.l`, and the `emit.l` files
of the previous, `maru.1` stage.

### Bootstrap "shortcuts"

Starting with `maru.5`, the LLVM IR output (`eval2.ll`) is committed into the repo under
`build/`. This effectively short-circuits the recursive bootstrap process by
straight away producing an executable from the checked-in `eval2.ll` using `llc`
(see `make eval-llvm`).

Deleting these files (**note:** `make clean` retains them! see `make veryclean`),
or touching the sources will force a normal bootstrap process using the previous stage(s).

In the future, when Maru can produce binary executable files
(see `make test-elf`) even those files could be checked in the git repo to provide
optional "shortcuts" in the bootstrap process.

It's possible to skip these shortcuts and run the bootstrap procedure all the way from
the/a bottom stage by `make PREVIOUS_STAGE_EXTRA_TARGETS=veryclean test-bootstrap`.

## Bootstrap "leakage"

In the bootstrap process most abstractions are present twice: the old
versions in the host module, and the new versions loaded into in the
slave module. At certain parts of the codebase these potentially
incompatible definitions can mix:

  - The compiler is running in the host's environment, but compiles
    the definitions of the slave. Thus, it inherently needs to cross
    the host-slave boundary (ideally, always in a controlled and
    explicit way, guarded by asserts).

  - A lot of the `forms` (macros) of the slave must be
    executed/expanded while building up the set of definitions that
    are meant to be level-shifted by the compiler to the target
    universe. These forms sometimes need to deal with the lexical
    environment (of type `<env>`) that is instantiated by the host.
    The object layout of these `<env>` objects will be that of which
    was specified in the host's codebase at the time of generating an
    eval executable from it. (The constructor function of `<env>`s is
    called `environment` in `eval.l`. When `eval.l` is compiled, it
    "captures" the object layout through the slot-index literals in
    the expansion of the accessor forms. Accessors expand to `oop-at`
    forms with literal indexes, and these are directly compiled to
    machine instructions).

A list of types and occasions where such leakage happens (meant to be
exhaustive, but it's probably not yet):

  - objects in the slave's source code: <pair>, <long>, <string>,
    <symbol>, (), i.e. objects that are created by the host's reader
    while parsing the slave's codebase into an object graph.

  - <primitive-function>, <expr>, <env>, <fixed>: the source code of the slave gets
    `encode`d by the host, therefore it may also contain objects of
    these types besides the list above.

  - <env>: whenever environments are passed to slave code, e.g. the
    forms defined in the slave will receive instances of the host's
    <env> type.

  - <type>, <record>: if we want to dispatch on the slave types while
    the host executable is bringing the slave to life, then the slave
    types need to integrate into that of the host's. What this means
    is that in the bootstrap process the slave does not create its own
    <type> and <record> instances, but "borrows" them from the host.
