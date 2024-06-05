# Maru's architecture

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
In other words, `eval.l` implements a
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
this case). More details are available in [the compiler's doc](compiler.md).

* `boot.l` contains some basic data structures, algorithms, and paradigms that are needed by
`emit.l`; it's written in the s-expression language.
