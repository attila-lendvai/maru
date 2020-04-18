# Maru

## What

Maru is a tiny self-hosting lisp dialect: a symbolic expression evaluator that can compile its own implementation language.

## How

The architecture is described in Ian Piumarta's paper:
[Open, extensible composition models](https://www.piumarta.com/freeco11/freeco11-piumarta-oecm.pdf).

> it is a sketch of how Maru's generalised eval works,
> which is entirely accurate in intent and approach,
> if a little different in some implementation details

### The Parts

* `eval.c` (in branch `stage-0.c99`) contains a reader/evaluator for a simple
s-expression language, written in C ([C99](https://en.wikipedia.org/wiki/C99)).

* `eval.l` contains the same evaluator, written in the s-expression language.
In other words, eval.l is a metacircular evaluator for the language it is written in.

* `emit.l` contains a compiler from s-expressions to [IA-32](https://en.wikipedia.org/wiki/IA-32) (x86)
machine code, written in the s-expression language. This compiler can be thought of as a
semantics-preserving "level shift" from s-expressions to IA-32 machine code, letting the metacircular
evaluator in `eval.l` escape from "infinite metacircular regression" to a language grounded in hardware.

* `boot.l` contains the data structures, algorithms and paradigms that are needed by `emit.l`,
written in the s-expression language.

The recursive implementation and compiler (in the .l files) is split into three parts for clarity,
but it could all be in a single source file.

### Build architecture

The bootstrap stages are in separate git branches called `stage-n`;
i.e. `stage-0-c99` holds the bootstrap implementation written in C,
and each successive stage uses the `eval` executable compiled from the
source code of the previous stage.

During the build the bootstrap stages are `git checkout`'ed into `build/stage-n`,
and they are built there. A new stage needs to be opened when you want to use a new feature
of the language in the code implementing the language itself.
The `master` branch holds the upcoming next bootstrap stage ("symlinked" by `git symbolic-ref`).

## Who

Initially written by [Ian Piumarta](https://www.piumarta.com/software/maru/).

This repo is maintained by [attila@lendvai.name](mailto:attila@lendvai.name).

## Why

* Programming badly needs better foundations, and Maru is part of this exploration.

* Maru is very small: in about 1700 lines of code it can self-host (with about 2300 LoC of C for stage 0).

* Ian seems to have stopped working on Maru, but it's an interesting piece of code that deserves
a repo and a maintainer.

## History

Maru was developed as part of Alan Kay's *Fundamentals of New Computing* project,
by the *[Viewpoints Research Institute](https://web.archive.org/web/20111002111856/http://www.viewpointsresearch.org/fonc_wiki/index.php/Idst)*.
The goal of the project was to implement an entirely new, self-hosting computing system, with GUI, in 20.000 lines of code.

Their annual reports:
[2007](http://www.vpri.org/pdf/tr2007008_steps.pdf),
[2008](http://www.vpri.org/pdf/tr2008004_steps08.pdf),
[2009](http://www.vpri.org/pdf/tr2009016_steps09.pdf),
[2010](http://www.vpri.org/pdf/tr2010004_steps10.pdf),
[2011](http://www.vpri.org/pdf/tr2011004_steps11.pdf),
[2012](http://www.vpri.org/pdf/tr2012001_steps.pdf).
