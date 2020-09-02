# Maru

## What

Maru is a programming language. It's a
[self-hosting](https://en.wikipedia.org/wiki/Self-hosting_(compilers)), yet tiny lisp dialect:
a symbolic expression evaluator that can compile its own implementation language
to [machine code](https://en.wikipedia.org/wiki/Machine_code), in less than 2000 LoC.

This repo is also a place of exploration in the land of bootstrapping
and computing system development. I'm planning to introduce simpler languages
into the bootstrap process; e.g. develop/incorporate
[a trivial stack machine based language](https://github.com/nagydani/seedling/)
that can be used to bootstrap Maru directly onto the raw metal, without
assuming a C compiler toolchain, or even an Operating System.

> Maru is in particular trying to be malleable at the very lowest levels,
> so any special interest that cannot be accommodated easily within the common
> platform would be a strong indicator of a deficiency within the platform
> that should be addressed rather than disinherited. (Ian Piumarta)

## How

Maru's architecture is described in Ian Piumarta's paper:
[Open, extensible composition models](https://www.piumarta.com/freeco11/freeco11-piumarta-oecm.pdf).

> it is a sketch of how Maru's generalised eval works,
> which is entirely accurate in intent and approach,
> if a little different in some implementation details (Ian Piumarta)

### The Parts

* `eval.c` (in branch `maru.0.c99`) contains a reader and
[evaluator](https://en.wikipedia.org/wiki/Interpreter_(computing)) (interpreter) for an
s-expression language, written in C ([C99](https://en.wikipedia.org/wiki/C99)).

* `eval.l` (in branch `maru.1` and up) contains the same evaluator, written in
(a subset of) this s-expression language.
In other words, `eval.l` is a
[metacircular evaluator](https://en.wikipedia.org/wiki/Meta-circular_evaluator)
for the language it is written in.

* `emit.l` contains a compiler from s-expressions to [IA-32](https://en.wikipedia.org/wiki/IA-32) (x86)
machine code and [LLVM](https://llvm.org/) IR, written in the s-expression language. This compiler can be thought of as a
semantics-preserving "level shift" from s-expressions to IA-32 machine code, letting the metacircular
evaluator in `eval.l` escape from "infinite metacircular regression" to a language grounded in hardware.
A possible metaphor of this is a "target universe" that, when compiling the abstract to the concrete,
provides you with a set of axiomatic foundations to build upon.

* `boot.l` contains some basic data structures, algorithms, and paradigms that are needed by `emit.l`,
written in the s-expression language.

### Build architecture

#### Overview - bootstrap stages

A language evolves by the introduction of new features (optimizations, new primitives, etc).
If you want to use such a novel language feature in its own implementation,
then you need to *bootstrap* it:

1) first, implement the support for it in your compiler and/or eval, and produce
   an executable that can already compile and/or eval this new version of the language
2) after that, you can start using this feature, and now you may even rewrite the
   implementation of this very feature, and use/assume this feature in its own
   implementation.

It's a confusing enough process, so it makes sense to fork the codebase at the point between 1) and 2).
Strictly speaking, checking out and building a specific prior commit would be enough to provide an
executable to execute the bootstrap process,
but you may want to harmonize the build system, or you need to `git cherry-pick` some fixes into 1),
and sometimes the implementation of the new feature simply requires two parallel, wildly diverged
instances of the codebase, until the feature is fully implemented/debugged/bootstrapped.
But once it's working fine, the old branch becomes irrelevant/stale, except for:

- didactic purposes (to make it easier to follow how a language grows)
- aesthetics (cherry-picking or backporting changes wouldn't be possible without having separate branches)
- "Oh God, we have lost all the executables!" -- bootstrap again all the way up from the C implementation

> NOTE: do not confuse this notion of a *stage* (as in 'developmental stages') with e.g.
> [the 3 bootstrap stages while compiling GCC](https://gcc.gnu.org/install/build.html).
> Our notion is an endless iterative process of evolving the language.
> Suggestions for a better nomenclature are welcome!

#### Repo layout

The developmental stages of the language are kept in separate git branches. When a new stage is opened,
this readme is replaced in the old branch to only document what's new/relevant for that specific stage.

Naming convention of the branches (no `master`):

`[language name].[bootstrap stage]`, e.g `maru.1`.

Optionally, e.g. for stage zero in the bootstrap, it may also include the name of the
parent language, from which this "bootstrap sprout" grows out:

`[language name].[bootstrap stage].[parent language]`, e.g. `maru.0.c99`, which holds
the bootstrap implementation written in C.

The bootstrap process in general is the following:
 - stage `n` checks out and builds its parent/hosting stage under `build/` (typically stage
   `(n-1)` of the same language) to acquire an `eval` executable.

 - using that executable it compiles a version of itself that can already
   load and run the codebase in stage `n`, but the resulting executable may not be
   fully functional (in this phase the `evolving?` variable is true). It's called
   `eval1` in the build process.

 - then it uses the resulting, potentially only semi-functional `eval1` executable to
   once again compile itself, which will yield the final, fully functional `eval2` executable.

 - optionally, the `test-bootstrap` makefile target runs one more cycle to produce `eval3`,
   and checks if the compiled output is identical with that of the previous step.

The `boot.l` and `emit.l` files are kept in the same branch with the `eval.l`
whose semantics they are assuming, i.e. the `eval1` executable of the `maru.2`
stage is built using the `eval` executable, `boot.l`, and `emit.l` of the previous,
`maru.1` stage.

During the build the previous stage is `git checkout`'ed locally under `./build/`,
and its own build process is invoked in that directory. Note that short of caching
the build output, this potentially becomes a
recursive process until a stage is reached that can be built using some
assumed external dependency; e.g. GCC building an `eval.c`.

My plan is not only to grow, but also to *shrink* the languages (i.e. try to introduce
"negative" bootstrap stages). This will be part of the collaboration with
Daniel A. Nagy's [seedling](https://github.com/nagydani/seedling/) project.

#### Bootstrap "shortcuts"

Starting with `maru.5`, the LLVM IR output (`eval2.ll`) is pushed to the repo under
`build/`. This effectively short-circuits the recursive bootstrap process by
straight away producing an executable by compiling the checked-in `eval2.ll` using `llc`
(see `make eval-llvm`).

Deleting these files (note that `make clean` retains them), or touching the sources will
force a normal bootstrap process building the previous stage(s).

### Build instructions

From the default branch invoke `make test-bootstrap[-llvm,-x86]`.

You will of course need:
```
sudo apt-get install llvm-8 clang-8
```

If you want to test the x86 backend then you will need to have support for compiling and
running 32 bit C code. On Debian based x86_64 systems:

```
sudo apt-get install gcc-multilib
```

Patches are welcome for dealing with other platforms, including the extension of this readme.
The LLVM backend should work even on untested targets, but I only test it on Linux for now.

## Who

Initially written by [Ian Piumarta](https://www.piumarta.com/software/maru/), at around 2011.

This repo and readme is maintained by [attila@lendvai.name](mailto:attila@lendvai.name).

## Where

Bugs and patches: [maru github page](https://github.com/attila-lendvai/maru).

Discussion: [maru-dev google group](https://groups.google.com/forum/#!forum/maru-dev).

## Contribution

You are very welcome to contribute, but beware that until further notice
**this repo will receive forced pushes** (i.e.
**`git push -f`** to rewrite git history (except the `piumarta` branch)). This will stop
eventually when I settle with
a build setup that nicely facilitates bootstrapping multiple, parallel paths of
language development. Please make sure that you open a branch for your work,
and/or that you are ready for some `git fetch` and `git rebase`.

## Why

* Programming badly [needs better foundations](https://github.com/nagydani/seedling/blob/master/RATIONALE.md),
and Maru is part of this exploration.
The foundations should get smaller, simpler, more self-contained, and more approachable
by people who set out to learn programming.

* We lose a lot of value by not capturing the history of the growth of a language, including
the formal encoding of its build instructions. They are useful both for educational purposes,
and also for practical reasons: to have a minimal *seed* that is very simple to
port to a new architecture, and then have a self-contained, formal bootstrap process that
can automatically "grow" an entire computing system on top of that freshly laid, tiny foundation.

* Maru is very small: in about 1700 lines of code in the `maru.1` branch it can self-host
(plus around 2300 LoC of throwaway C code for the initial step).

* Ian seems to have stopped working on Maru, but it's an interesting piece of code that deserves
a repo and a maintainer.

* This work is full of puzzles that are a whole lot of fun to resolve!

## Status

### Maru's status

Backporting of the latest from the `piumarta` branch is done: the latest branch should be
semantically equivalent with the `eval.l` that resides in the Piumarta branch, although
we have arrived to this state on a different path: Ian has kept `eval.c` and `eval.l`
semantically in sync, while I have bootstrapped the needed changes from an earlier
version of `eval.l`, starting out from, and abandoning a simpler `eval.c` at my first step.

There are several Maru stages/branches now, introducing non-trivial features.

The compiler backends currently emit text files. Therefore, for now, a
C toolchain is required for a full circle of bootstrap even on x86. With the addition of an IA-32
assembler this requirement can be eliminated; i.e. there's no inherent external
dependency in the codebase (the basic IO and memory management services
of `libc` will also be made pluggable).

Assorted TODO:
- revive all the goodies in the `piumarta` branch, but in a structured way
- replace the hand-written parser in `eval.l` with something generated by the
  [PEG](https://en.wikipedia.org/wiki/Parsing_expression_grammar) generator
- compile to, and bootstrap on the bare metal of some interesting target (C64? an ARM board?)
- rewrite the build process in Maru; eliminate dependency on GNU Make

### History

#### Around 2010-2013
Maru was developed as part of Alan Kay's *Fundamentals of New Computing* project,
by the *[Viewpoints Research Institute](https://web.archive.org/web/20111002111856/http://www.viewpointsresearch.org/fonc_wiki/index.php/Idst)*.
The goal of the project was to implement an entirely new, self-hosting computing system, with GUI, in 20.000 lines of code.

At some point VPRI went quiet and closed down in 2018. Much of their online content disappeared, and the team (probably) also dissolved.

Their annual reports:
[2007](http://www.vpri.org/pdf/tr2007008_steps.pdf),
[2008](http://www.vpri.org/pdf/tr2008004_steps08.pdf),
[2009](http://www.vpri.org/pdf/tr2009016_steps09.pdf),
[2010](http://www.vpri.org/pdf/tr2010004_steps10.pdf),
[2011](http://www.vpri.org/pdf/tr2011004_steps11.pdf),
[2012](http://www.vpri.org/pdf/tr2012001_steps.pdf).

#### This git repo

The `piumarta` branch of this git repo is a conversion of Ian Piumarta's Mercurial
repo that was once available at http://piumarta.com/hg/maru/. To the best of my knowledge
this is the latest publically available state of Ian's work. This repo was full of
assorted code, probably driving the VPRI demos.

The `piumarta` branch will be left stale (modulo small fixes and cleanups).
My plan is to eventually revive most of the goodies from this branch, but in a
more organized and approachable manner, and also paying attention to the
bootstrapping issues.

Ian published another Mercurial repo somewhere halfway in the commit history
with only a couple of commits from around 2011. I assume that it was meant to hold
the minimal/historical version of Maru that can already self-host. I started out
my work from this minimal repo (hence the divergence between the `piumarta` and
the `maru.x` branches in this repo).

#### Other repos

There are a few different copies/versions of Maru online. Here are the ones
that I know about and contain non-trivial work:

- [github.com/melvinzhang/maru](https://github.com/melvinzhang/maru)
