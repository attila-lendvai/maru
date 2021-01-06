# Maru

## What

Maru is a programming language. It's a
[self-hosting](https://en.wikipedia.org/wiki/Self-hosting_(compilers)),
yet tiny [lisp](https://en.wikipedia.org/wiki/Lisp_(programming_language))
dialect: a symbolic expression evaluator that can compile its own implementation to
[machine code](https://en.wikipedia.org/wiki/Machine_code),
in about 2000 LoC altogether.

> Maru is in particular trying to be malleable at the very lowest levels,
> so any special interest that cannot be accommodated easily within the common
> platform would be a strong indicator of a deficiency within the platform
> that should be addressed rather than disinherited. (Ian Piumarta)

This repo is also a place for exploration in the land of bootstrapping
and computing system development. My personal interest is in clearly
and formally expressing that which is mostly treated as black magic:
the bootstrapping of a language on top of other languages (which
includes the previous developmental stage of the same language).

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
(a subset of) this s-expression language that can be compiled to machine code.
In other words, `eval.l` implementats a
[metacircular evaluator](https://en.wikipedia.org/wiki/Meta-circular_evaluator)
for the language it is written in.

* `emit.l` contains a compiler from s-expressions to
[IA-32](https://en.wikipedia.org/wiki/IA-32) (x86) assembly (and [LLVM](https://llvm.org/) IR),
written in the s-expression language. This compiler can be thought of
as a semantics-preserving "level shift" from s-expressions to machine code, letting
the metacircular evaluator in `eval.l` escape from the "infinite metacircular regression"
to a language grounded in hardware. A possible metaphor of this is a "target universe"
implemented by some electric circuits (i.e. transistors wired to each other in a CPU)
that provide you a set of axiomatic foundations to build upon while compiling the
abstract to the concrete; while implementing your new universe (the Maru language in this case).

* `boot.l` contains some basic data structures, algorithms, and paradigms that are needed by
`emit.l`; it's written in the s-expression language.

### Build architecture

The details of [the bootstrap process](doc/bootstrap.md) are in a standalone
document. This is only a bird's eye view.

#### Repo layout

The developmental stages of the language are kept in separate git branches. When a new stage is opened,
this readme is replaced in the old branch to only document what's new/relevant for that specific stage
(i.e. if you switch branches on github you'll see it right away).

Naming convention of the branches (no `master`):

`[language name].[bootstrap stage]`, e.g `maru.1`.

Optionally, e.g. for stage zero in the bootstrap, it may also include the name of the
parent language, from which this "bootstrap sprout" grows out:

`[language name].[bootstrap stage].[parent language]`, e.g. `maru.0.c99`, which holds
the bootstrap implementation written in C.

During the build the previous stage is `git checkout`'ed locally under `./build/`,
and its own build process is invoked in that directory. Note that this potentially
becomes a recursive process until a stage is reached that can be built using some
external dependency. This may happen by reaching an `eval.c` in the bottom stage/branch
called `maru.0.c99` that can be built using a C compiler, or by reaching a higher level
stage that has its build output checked into the git repo.

### Build instructions

To test a bootstrap cycle using one or all of the backends:

```
make test-bootstrap[-llvm,-x86]
```

#### Linux

You may need LLVM (any version beyond 8 should work):
```
sudo apt-get install llvm-8 clang-8
```

If you want to test the x86 backend then you will need to have support for compiling and
running 32 bit C code. On Debian based x86_64 systems:

```
sudo apt-get install gcc-multilib
```

#### MacOS

Please note that recent MacOS versions don't support 32 bit executables anymore,
but Maru's LLVM backend is expected to work fine.

1. Make sure XCode is installed. In a Terminal:

```
xcode-select --install
```

2. [Install Homebrew](https://brew.sh/)

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

3. [Install LLVM using Homebrew](https://embeddedartistry.com/blog/2017/02/24/installing-llvm-clang-on-osx/)
```
brew install llvm
echo export PATH="$(brew --prefix llvm)/bin:$PATH" >> ~/.bash_profile
source ~/.bash_profile
```

#### Other platforms

Currently Maru should work everywhere where there's a `libc`, and either the
GNU toolchain, or LLVM is available.

Patches are welcome for other platforms, including the extension of this readme.

## Who

Initially written by [Ian Piumarta](https://www.piumarta.com/software/maru/), at around 2011.

This repo and readme is maintained by [attila@lendvai.name](mailto:attila@lendvai.name).

## Where

Bugs and patches: [maru github page](https://github.com/attila-lendvai/maru).

Discussion: [maru-dev google group](https://groups.google.com/forum/#!forum/maru-dev).

## Contribution

You are very welcome to contribute, but beware that until further notice
**this repo will receive forced pushes** (i.e.
**`git push -f`** rewriting git history (except the `piumarta` branch)). This will stop
eventually when I settle with
a build setup that nicely facilitates bootstrapping multiple, parallel paths of
language development. Please make sure that you open a branch for your work,
and/or that you are ready for some `git fetch` and `git rebase`.

## Why

* Programming badly needs
[better foundations](https://github.com/nagydani/seedling/blob/master/RATIONALE.md),
and Maru is part of this exploration. The foundations should get **smaller, simpler,
more self-contained, and more approachable** by people who set out to learn programming.

* We lose a lot of value by not capturing the history of the growth of a language, including
the formal encoding of its build instructions. They are useful both for educational purposes,
and also for practical reasons: to have a minimal *seed* that is very simple to
port to a new architecture, and then have a self-contained, formal bootstrap process that
can automatically "grow" an entire computing system on top of that freshly laid, tiny foundation.

* Maru is very small: in about 1700 lines of code in the `maru.1` branch it can self-host
(plus around 2300 LoC of throwaway C code for the initial step).

* Ian seems to have stopped working on Maru, but it's an interesting piece of code that
deserves a repo and a maintainer.

* This work is full of puzzles that are a whole lot of fun to resolve!

## Status

### Maru's status

Backporting and bootstrapping the latest semantics from the `piumarta`
branch is done: the `eval.l` in the latest branch of this repo should
be semantically equivalent with the `eval.l` that resides in the
`piumarta` branch, although we have arrived to this state on two
different paths:

  - Ian, while evolving Maru, kept his `eval.c` and `eval.l`
    semantically in sync,

  - while I have bootstrapped the new features: I started out from an
    earlier version of the `eval.l` + `eval.c` couple (the [minimal
    ones](https://www.piumarta.com/software/maru/) published on Ian's
    website). Then I bootstrapped the later stages of `eval.l` using
    an earlier stage of itself. I only used the C code as the initial
    stepping stone in the bootstrap process, and then I left it
    behind.

There are several Maru stages/branches now, introducing non-trivial
new features. Some that are worth mentioning:

  - The host and the slave are isolated while bootstrapping which makes it possible to
    do things like reordering types (changing their type id in the target),
    or changing their object layout.

  - Relying on this isolation, the code in `eval.l` now looks pretty much the same
    as something that is meant to be loaded into the evaluator (i.e. the function
    implementing `car` in `eval.l` is now called `car`). This paves the way for
    metacircularity: to be able to "bring alive" the evaluator by loading it
    verbatim into another instance of itself (as opposed to compiling it to
    machine code and giving it to a CPU to bring it alive).

  - The addition of an LLVM backend.

The two compiler backends currently emit text files. Therefore, for now, a
C toolchain is required for a full cycle of bootstrap even on x86. With the addition
of an IA-32 assembler that directly outputs machine code this requirement
can be eliminated; i.e. there's no inherent external dependency on the C
infrastructure in the codebase (the basic IO and memory management services
of `libc` are also pluggable).

Assorted TODO:
  - Revive all the goodies in the `piumarta` branch, but in a structured way.

  - Replace the hand-written parser in `eval.l` with something generated by the
   [PEG](https://en.wikipedia.org/wiki/Parsing_expression_grammar) compiler.

  - Simplify the types-are-objects part and its bootstrap, and maybe even
    make it optional?

  - Compile to, and bootstrap on the bare metal of some interesting target
    (C64? an ARM board?).

  - Rewrite the build process in Maru; eliminate dependency on GNU Make.

  - Implement modules and phase separation along what is outlined in
    [Submodules in Racket - You Want it When, Again?](https://www.cs.utah.edu/plt/publications/gpce13-f-color.pdf).
    Part of this is already done and is used in the bootstrap process.

  - Merge the language and API that the compiler and the evaluator understands;
    i.e. make the level-shifted code (`eval.l` & co.) less different than code
    meant for the evaluator. This would mean that we can e.g. load/compile
    `source/buffer.l` both into the level-shifted code and into the evaluator.
    This is partially done, but there are still loose ends to deal with.

  - Directly generate IA-32 machine code and thus eliminate the dependency on
    an external assembler. Then use this to implement a JIT that attempts to
    compile closures to machine code instead of interpreting them.
    
  - Understand and incorporate François René Rideau's model of
    [First Class Implementations: Climbing up the Semantic Tower](https://www.youtube.com/watch?v=fH51qhI3hq0),
    (see this [couple of page summary](https://github.com/fare/climbing), or
    see his [page on reflection](http://fare.tunes.org/reflection.html))

### History and perspective

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
repo that was once available at
[http://piumarta.com/hg/maru/](http://piumarta.com/hg/maru/).
To the best of my knowledge
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

#### Other instances

There are other copies/versions of Maru online. Here are the ones
that I know about and contain interesting code:

- [github.com/melvinzhang/maru](https://github.com/melvinzhang/maru)

- [below-the-top](https://github.com/jbulow/below-the-top) is some kind of
  generic sexp tokenizer and evaluator written in Common Lisp that can be
  configured so that it can bootstrap Maru. I haven't tried it myself.

#### Related projects

A list of projects that are worth mentioning in this context:

  - [Project Oberon](http://www.projectoberon.com/): a project which encompasses CPU,
    language, operating system and user interface, and which can be run on a relatively
    inexpensive FPGA board, and simple enough for one person to understand it all.

  - [Seedling](https://github.com/nagydani/seedling/)
