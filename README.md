# Maru (stage 1)

> **NOTE:** This readme focuses on the aspects of this stage that are
> relevant for bootstrapping the next stage. The full README.md file
> can be found in the git branch of the latest stage.

The `eval.l` file in this stage is the reimplementation of the
`eval.c` file in the `maru.1.c99` branch, but this time in Maru (well,
a subset of it that the compiler can level-shift to machine code).

The C and the Maru versions are mostly mirrors of each other, but
written in different languages. Unsurprisingly, the behavior of the
produced executables should be (mostly) the same.

`eval.c` is used as a host to run the necessary Maru code that
compiles `eval.l` to machine code, i.e. bootstraps it. When that
happens `eval.c` becomes obsolete. Nevertheless, it's kept for
historical reference, and to be able to rerun the bootstrap chain on
top of a C compiler.
