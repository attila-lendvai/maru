# Maru (stage 10; written in C)

> **NOTE:** This readme focuses on the aspects of this stage that are
> relevant for bootstrapping maru.10. The full README.md file can be
> found in the git branch of the [latest
> stage](https://github.com/attila-lendvai/maru/).

## Reason for this stage

After having wandered through stage 1 to stage 10, the semantics of
`maru.10` is once again rather close to that of the initial `eval.c`
written by Piumarta. Given that it is worth bringing `eval.c` close
enough to `maru.10` so that it can once again bootstrap the `maru.10`
stage.

Once it's done it will be possible to bootstrap `maru.10` from
`maru.1.c99` (and recursively all the way from the initial `eval.c`),
**and** also in one step from `maru.10.c99`.

## Strategy

This branch is the bottom of the bootstrap chain, so it holds only the
C implementation of the VM. The lisp that the VM animates (`boot.l`,
the type system, the compiler, the platform layer, cgrov) is *not*
copied here on purpose; it is taken from a `maru.10` checkout. Hence:

  - the C VM must implement exactly what maru.10's compiled `eval`
    implements: the reader, the heap/GC, `expand`/`encode`/`eval`/
    `apply`, and the primitives of
    `source/evaluator/vm-functions.l`
  - host and slave may use different type ids, `source/types.l` maps
    them (`%type-id-map/host->slave`), but the object layout of the
    types the host instantiates must match the slave's
  - the C code mirrors the shape of the corresponding lisp, function by
    function, so that the two can be read side by side

## Status

It bootstraps. With the C `eval` installed in a `maru.10` checkout as
`./eval`:

    cd ../maru.10
    make PLATFORM=linux PREVIOUS_STAGE=maru.10.c99 EVAL0_PHASE=1 \
         DIFF=diff test-bootstrap-x86

The C host compiles eval0 (and generates the cgrov constants), eval0
compiles eval1, eval1 compiles eval2, and eval1 and eval2 are byte
identical. Note that `DIFF` defaults to `:`, i.e. no comparison.

x86/linux came first because its target pipeline has no C FFI.

Still missing: the llvm and libc/posix targets (they need the
`C-function` machinery), i686/aarch64, the profiler, and
`make test-bootstrap` in the wider sense.

See `doc/agent/maru-10-c99.txt` for the plan, the porting checklist and
the debugging notes.

## Usage

    make                                        # builds ./eval
    make test-evaluator MARU10=/path/to/maru.10

`make test-evaluator` runs maru.10's evaluator tests with this eval,
and is the semantic gate while porting.
