# Maru's bootstrap process

## Meta

This document explains the bootstrap process, both conceptually and the specifics of this implementation.

Don't forget to consult the [glossary](glossary.md).

## Overview

A language evolves by the introduction of new features (optimizations, new primitives, etc).
If you want to use such a novel language feature in its own implementation,
then you need to [*bootstrap*](http://bootstrappable.org/) it:

1) First, implement the support for the new feature only assuming the
   axioms of your **host** VM. Then produce an executable that can
   already compile and/or eval this new version of the language.

2) After that, you can start using this feature, and now you may even
   rewrite the implementation of this very feature itself, and
   use/assume this feature in its own implementation.

It's a confusing enough process, therefore it makes sense to fork the
codebase of 1) and 2) into git branches. Strictly speaking, it would
be enough to git checkout and build a specific prior commit to provide
an executable to host the bootstrap process, but it's better to have
separate branches.

Once it's working fine, the old branch becomes irrelevant/stale, except for:

  - Didactic purposes: to make it easier to understand how a
    self-hosted language grows.

  - Aesthetics: cherry-picking or backporting changes wouldn't be
    possible without having separate branches.

  - "Oh God, we have lost all the executables!" -- bootstrap again all
    the way up from the first C implementation.
    
  - Tricky issues sometimes require modifying both branches in
    parallel: cherry-picking or backporting some commits, or
    developing specific fixes or debug helpers for working out the
    bootstrap.

  - Sometimes the world changes (e.g. the C compiler becomes more
    restrictive, or 32 bit x86 support becomes extinct). To retain
    bootstrappability throughout the entire evolution of the language
    we need to do some facelifting on the old codebase.

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

A Maru implementation consists of two separate, but not completely
independent artifacts:

 - A binary file that can be executed on the target. This binary
   already defines a few well-known objects and some primitive
   functions implemented by the binary.

 - And the .l source code files that can be loaded by this binary to
   further extend the VM with definitions.

There are 3 main namespaces/players in the bootstrap process:

 - The host: a Maru VM animating the process.

 - The slave: basically the latest version of the codebase loaded into
   a separate environment in the host VM. This means that most
   definitons get duplacted, and a few (and hopefully well controlled)
   ties are created between the host and the slave. Uncontrolled
   leakage between the host and the slave can lead to the most
   mind boggling puzzles (read: bugs).

 - The target: this is an env in the host. The definitions defined
   into it will be level-shifted into the target architecture to
   implement the bootstrapped VM binary.

The bootstrap process in general is the following:

 - Actors, overview:
   - eval0: The makefile checkes out our latest commit as a worktree
     into `build/`, builds it there, and leaves it alone until a `make
     veryclean`, `make update-eval0`, `make eval0`, or similar
     intervention happens. Corollary: the bootstrap is only fully
     tested once eval0 has been rebuilt, because only that will cross
     the stage n-1 to stage n gap.
   - eval1: latest source compiled by eval0 (the `evolving` variable
     is `true` in this phase)
   - eval2: latest source compiled by itself (by eval1)
   - eval3: latest source compiled by itself, once agains (by
     eval2). This is done to verify that eval2 and eval3 are bit by
     bit equivalent.

 1) Stage `n` checks out and builds its parent/hosting stage under
    `build/` (typically stage `(n-1)` of the same language) to acquire
    an `eval` executable. Let's call this *eval0*.

 2) Using the compiler of *eval0* (i.e. the previous stage), the
    current stage is compiled. Let's call the result *eval1*. It can
    already load and compile itself, i.e. the vanilla codebase in
    stage `n`, but the resulting executable may not be fully
    functional yet. The discrepancies are typically in the categories
    of performance and safety checks. In this phase the `evolving?`
    variable is true, signifying that the host and the slave are not
    the same version.

    **Note** that compiling *eval1* is not always necessary, depending
    on the nature of the new features that are being
    bootstrapped. It's useful to immediately enjoy the benefits of the
    new features of this stage, and it's necessary when we introduce a
    new feature that the compiler itself needs to be aware of (either
    because its implementation relies on it or uses this feature, or
    e.g. in the case of the introduction of modules it needs to reach
    across module boundaries during the compilation process).

 3) Then it uses the resulting, potentially only semi-functional
    `eval1` executable to now compile itself using its own compiler,
    which will yield the final, fully functional `eval2` executable.

 4) Optionally, the `test-bootstrap` makefile target runs one more
    cycle to produce `eval3`, and checks if the compiler's output is
    identical with that of the previous step.

### Repo layout

The developmental stages of the language are kept in separate git
branches. When a new stage needs to be opened, the readme is replaced
in the branch that is becaming stale to only document what's new/relevant
for that specific stage (i.e. if you switch branches on the GitHub
website you'll see it displayed).

Naming convention of the branches (no `main` branch):

`[language name].[bootstrap stage]`, e.g `maru.1`.

Optionally, and typically for the first stage, it may also include the
name of the hosting language, from which this "bootstrap sprout" grows
out:

`[language name].[bootstrap stage].[hosting language]`, e.g. `maru.1.c99`,
which holds the bootstrap implementation written in C.

During the build the previous stage is `git checkout`'ed locally under
`./build/`, and its own build process is invoked in that
directory. Note that this may potentially become a recursive process
until a stage is reached that can be built by itself. This may happen
by reaching an `eval.c` in the bottom stage/branch called `maru.1.c99`
that can be built using a C compiler, or by reaching a stage that has
its build artifacts checked into the git repo (e.g. an `eval.s` or
`eval.ll`).

Potentially something like a `maru.5.common-lisp` can also be
developed to serve as another "entry point" to the bootstrap (there's
an experiment for that). In that case `maru.6` should yield the same
binary output regardless of which parent is being used in the
bootstrap chain.

### Bootstrap "shortcuts"

Starting with `maru.5`, the LLVM IR output (`eval2.ll`) is committed into the repo under
`build/`. This effectively short-circuits the recursing bootstrap chain by
straight away producing an executable from the checked-in `eval2.ll`
(an LLVM IR file, see `make eval-llvm`).

Deleting these files (**note:** `make clean` retains them! see `make veryclean`),
or touching the sources will force a normal bootstrap process hosted by
the previous stage.

It's possible to skip these shortcuts and run the bootstrap procedure all the way from
the/a bottom stage by `make PREVIOUS_STAGE_EXTRA_TARGETS=veryclean veryclean test-bootstrap`.

## Bootstrap "leakage"

In the bootstrap process most abstractions are present twice: the old
versions in the host env, and the new versions loaded into in the
slave env. At certain parts of the codebase these potentially
incompatible definitions can mix:

  - The compiler is running in the host's environment, but compiles
    the definitions of the slave. Thus, it inherently needs to cross
    the host-slave boundary (ideally, always in a controlled and
    explicit way, guarded by asserts that fail early and loud).

  - A lot of the `forms` (macros) of the slave must be
    executed/expanded while building up the set of definitions that
    will be level-shifted by the compiler to the target
    universe. These forms sometimes need to deal with the lexical
    environment (of type `<env>`) that is instantiated by the host.
    The object layout of these `<env>` objects will be that of which
    was specified in the host's codebase at the time of generating an
    eval executable from it. (The constructor function of `<env>`s is
    called `environment` in `eval.l`. When `eval.l` is compiled, it
    "captures" the object layout through the slot-index literals in
    the expansion of the accessor forms. Accessors expand to `oop-at`
    forms with literal indexes, and these are then directly compiled to
    machine instructions).

A list of types and occasions where such leakage happens (meant to be
exhaustive, but it's probably not yet):

  - objects in the slave's source code: `<pair>`, `<long>`, `<string>`,
    `<symbol>`, `()`, i.e. objects that are created by the host's reader
    while parsing the slave's codebase into an object graph.

  - `<primitive-function>`, `<expr>`, `<env>`, `<fixed>`: the source
    code of the slave gets `encode`d by the host, therefore it may
    also contain objects of these types besides the list above.

  - `<env>`: whenever environments are passed to slave code, e.g. the
    forms defined in the slave will receive instances of the host's
    `<env>` type.

  - `<type>`, `<record>`: if we want to dispatch on the slave types while
    the host executable is bringing the slave to life, then the slave
    types need to integrate into that of the host's. What this means
    is that in the bootstrap process the slave does not create its own
    `<type>` and `<record>` instances, but "borrows" them from the host.
