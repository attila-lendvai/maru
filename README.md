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

## Meta

This document aims to present an overview of Maru. There are various
documents in the [`doc/`](doc/) directory that discuss some topics in
more detail.

## How

Maru's architecture is described in Ian Piumarta's paper:
[Open, extensible composition models](https://www.piumarta.com/freeco11/freeco11-piumarta-oecm.pdf).

> it is a sketch of how Maru's generalised eval works,
> which is entirely accurate in intent and approach,
> if a little different in some implementation details (Ian Piumarta)

### The Parts - an overview

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
abstract to the concrete; while implementing your new universe (the Maru language in
this case). More details are available in [the compiler's doc](doc/compiler.md).

* `boot.l` contains some basic data structures, algorithms, and paradigms that are needed by
`emit.l`; it's written in the s-expression language.

### Build instructions

To test a bootstrap cycle using one or all of the backends:

```
make test-bootstrap-x86    # defaults to the libc platform
make PLATFORM=[libc,linux] test-bootstrap[-llvm,-x86]
```

#### Linux

```
sudo apt install make time rlwrap
```

You will need LLVM, and/or a C compiler (any version beyond LLVM 8 should work):

```
sudo apt install llvm clang
```

For now the x86 backend only supports 32 bit mode. To use it you will
need to have support for compiling and running 32 bit C code. On
Debian based x86_64 systems this will install all the necessary
libraries:

```
sudo apt install gcc-multilib
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

Patches are welcome for other platforms.

## Who

Initially written by [Ian Piumarta](https://www.piumarta.com/software/maru/),
at around 2011. Full commit history is available in the
[`piumarta`](https://github.com/attila-lendvai/maru/tree/piumarta)
branch.

This repo and readme is maintained by [attila@lendvai.name](mailto:attila@lendvai.name).

## Where

Bugs and patches: [maru github page](https://github.com/attila-lendvai/maru).

Discussion: [maru-dev google group](https://groups.google.com/forum/#!forum/maru-dev).

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

## Contribution

You are very welcome to contribute, but beware that until further notice
**this repo will receive forced pushes** (i.e.
**`git push -f`** rewriting git history (except the `piumarta` branch)). This will stop
eventually when I settle with
a build setup that nicely facilitates bootstrapping multiple, parallel paths of
language development. Please make sure that you open a branch for your work,
and/or that you are ready for some `git fetch` and `git rebase`.

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

### Notable new features

There are several Maru stages/branches now, introducing non-trivial
new features. Some that are worth mentioning:

  - Introduction of *platforms*: they are the "holding environments"
    where the implementation of `eval` can be brought alive. Notably,
    besides the original `libc` platform, there is now a `linux`
    platform that compiles to a statically linked executable that runs
    directly on top of the Linux kernel,
    [using `syscall`s](https://en.wikibooks.org/wiki/X86_Assembly/Interfacing_with_Linux);
    i.e. without linking anything from `libc`, or `ld-linux.so`. From
    a practical perspective this is equivalent with running directly
    on the bare metal (i.e. all dynamically allocated memory is
    provided by our own GC, etc).

    List of platforms: `libc`, `linux`, `metacircular` (only planned:
    loading the evaluator's implementation into another instance of
    the evaluator, as opposed to compiling it to machine code).

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

### Assorted TODO:

  - Finish the proof of concept in `tests/test-elf.l` to compile the
    Linux plaform directly into an ELF binary.

  - Rewrite the build process in Maru; eliminate dependency on GNU Make.

  - Replace the hand-written parser in `eval.l` with something generated by the
    [PEG](https://en.wikipedia.org/wiki/Parsing_expression_grammar) compiler.

  - Implement modules and phase separation along with what is outlined in
    [Submodules in Racket - You Want it When, Again?](https://www.cs.utah.edu/plt/publications/gpce13-f-color.pdf).
    Part of this is already done and is used in the bootstrap process.

  - Use LLVM's [tablegen](https://llvm.org/docs/TableGen/index.html)
    definitions to generate bytecode assemblers. It requires either
    the reimplementation of the tablegen parser/logic in Maru (doesn't
    seem to be trivial), or writing C++ code (uhh!) to compile the
    data to the Maru definitions implementing an assembler.

  - Introduce a simplified language that drops some langauge features,
    e.g. remove *forms* and the *expand* protocol. Make sure that this
    language can bootstrap itself off of C99. Then reintroduce *forms*
    and *expand* by using this simplified Maru as the implementation
    language.

  - Compile to, and bootstrap on the bare metal of some interesting
    targets. It's already demonstrated by the Linux platform. Another
    one could be
    [pc-bios](https://github.com/cirosantilli/x86-bare-metal-examples),
    because it's easily testable using QEMU. Or port it on an ARM
    board (like Raspberry Pi)? Or maybe even a C64 port?

  - Revive all the goodies in the `piumarta` branch, but in a structured way.

  - Simplify the types-are-objects part and its bootstrap, and maybe even
    make it optional?

  - Merge the language and API that the compiler and the evaluator understands;
    i.e. make the level-shifted code (`eval.l` & co.) less different than code
    understood by the evaluator. This would mean that we can e.g. load/compile
    `source/buffer.l` both into the level-shifted code and into the evaluator.
    This is slowly happening, but it's nowhere near done, and I'm not even sure
    what done means here.

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
the [minimal/historical version](https://www.piumarta.com/software/maru/)
of Maru that can already self-host. I started out
my work from this minimal repo (hence the divergence between the `piumarta` and
the `maru.x` branches in this repo).

#### Other instances

There are some other copies/versions of Maru. Here are the ones
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
