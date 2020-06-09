# Maru

## What

Maru is a programming language. It's a tiny, self-hosting lisp dialect:
a symbolic expression evaluator that can compile its own implementation language,
in less than 2000 LoC.

This repo is also the place of exploration in the land of bootstrapping
and computing system development. I'm planning to also **shrink**
what's currently known as Maru, and/or introducing simpler languages into the
bootstrap process; e.g. develop
[a trivial stack machine based language](https://github.com/nagydani/seedling/)
that can be used to bootstrap Maru directly onto the raw metal, without
assuming a C compiler toolchain, or an Operating System, and all that with
minimal efforts.

## How

Maru's architecture is described in Ian Piumarta's paper:
[Open, extensible composition models](https://www.piumarta.com/freeco11/freeco11-piumarta-oecm.pdf).

> it is a sketch of how Maru's generalised eval works,
> which is entirely accurate in intent and approach,
> if a little different in some implementation details

### The Parts

* `eval.c` (in branch `maru.0.c99`) contains a reader/evaluator for a simple
s-expression language, written in C ([C99](https://en.wikipedia.org/wiki/C99)).

* `eval.l` (in branch `maru.1` and up) contains the same evaluator, written in
(a subset of) this s-expression language.
In other words, `eval.l` is a metacircular evaluator for the language it is written in.

* `emit.l` contains a compiler from s-expressions to [IA-32](https://en.wikipedia.org/wiki/IA-32) (x86)
machine code, written in the s-expression language. This compiler can be thought of as a
semantics-preserving "level shift" from s-expressions to IA-32 machine code, letting the metacircular
evaluator in `eval.l` escape from "infinite metacircular regression" to a language grounded in hardware.
A possible metaphor of this is a "host universe" that, when compiling the abstract to the concrete,
provides you with a set of axiomatic foundations you can build upon. Other possible such
"host universes" are e.g. C99 or LLVM.

* `boot.l` contains some basic data structures, algorithms, and paradigms that are needed by `emit.l`,
written in the s-expression language.

The recursive implementation and compiler (in the .l files) is split into three parts for clarity,
but it could all be in a single source file.

### Build architecture, git repo layout

The bootstrap stages are in separate git branches with the following
naming convention (without a `master` branch):

`[language name].[bootstrap stage]`, e.g `maru.1`.

Optionally, for stage zero in the bootstrap, it also includes the name of the
parent language, from which this "bootstrap sprout" grows out:

`[language name].[bootstrap stage].[parent language]`, e.g. `maru.0.c99`, which holds
the bootstrap implementation written in C.

The bootstrap process in general is planned to be like this: stage `n` requests
the/a parent stage (typically stage `(n-1)` of the same language) to compile an
`eval` executable. Then it uses that executable to compile itself (and provide
the foundations for stage `(n+1)`).

The `boot.l` and `emit.l` files are kept in the same branch with the `eval.l`
whose semantics they depend on. IOW, the `maru.2` stage is built using the
`eval` executable, `boot.l`, and `emit.l` of the previous stage (`maru.1`).

During the build the bootstrap stages are locally `git checkout`'ed into `build/`
and they are built there (this becomes recursive with multiple stages). A new stage
needs to be opened when you want to use a new feature
of the language in the code implementing the language itself.

My plan is not only to grow, but also to *shrink* the languages (i.e. try to introduce
"negative" bootstrap stages). This will be part of the collaboration with
Daniel A. Nagy's [seedling](https://github.com/nagydani/seedling/) project.

### Build instructions

TL;DR: From the default branch (currently `maru.3`) invoke `make test-bootstrap`.

**Linux:**

You need support for compiling and running 32bit C code. On Debian based x64 systems:

```
sudo apt-get install gcc-multilib
```

## Who

Initially written by [Ian Piumarta](https://www.piumarta.com/software/maru/).

This repo is maintained by [attila@lendvai.name](mailto:attila@lendvai.name).

## Why

* Programming badly needs better foundations, and Maru is part of this exploration.
The foundations should get smaller, simpler, more self-contained, and more approachable
for people who set out to learn programming.

* We lose a lot of value by not capturing the growth of a language into repo branches
and formally encoded build instructions. They are useful both for educational purposes,
and also for practical reasons: to have a minimal *seed* that is very simple to
port to a new architecture, and then have a self-contained, formal bootstrap process that
can automatically "grow" the entire system on top of that freshly layed, tiny foundation.

* Maru is very small: in about 1700 lines of code it can self-host
(with about 2300 LoC of throwaway C code for the bootstrap).

* Ian seems to have stopped working on Maru, but it's an interesting piece of code that deserves
a repo and a maintainer.

## Status

There are 3 stages now, introducing non-trivial changes, and the repo structure seems to slowly mature.

A short-term TODO:
- capture the emitted `eval.s` files and check them into the repo; add makefile targets
that use them, regenerate them, compare them (to "short circuit" the bootstrap process).
- revive all the goodies in the repo in a structured way (PEG parser, x86 assembler, etc).
- generate LLVM output.

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

This git repo is a conversion of Ian Piumarta's mercurial repo that was once
available at http://piumarta.com/hg/maru/, whose contents are preserved in the
branch called `piumarta`. The plan is to eventually revive most of the goodies
available there in a more organized and approachable manner, and also pay attention
to the bootstrapping issues.

To the best of my knowledge this repo holds the latest published state of
Ian's work (captured in the branch called `piumarta`).

Ian published another mercurial repo somewhere halfway in the commit history,
with only a few commits. I assume that it was meant to hold a "vanilla"
version of Maru that can self-host, but is not tailored to accommodate the VPRI demos.
I started out my work from this minimal repo, hence the divergence between the
git branch histories.

**This repo will receive forced pushes** (i.e.
`git push -f` to rewrite git history (except the `piumarta` branch)) until I come up with
a build setup that nicely facilitates bootstrapping in multiple, parallel bootstrapping
paths of language development.

There were two Mercurial repositories, one for the VPRI demos, and one for the
minimal self-hosting Maru (? it's just an assumption of mine). I based my work
on top of the minimal repo, which was created by Ian in 2011.
