# Maru (stage 10)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reason for the new stage

To eliminate modules. This opens up the possibility to relatively
easily bootstral this stage using `eval.c` with a few additions like
the `--define` command line argument.

## Assorted changes

 - Deleted the *module* abstraction. It was a mistake to introduce it
   because what i used them for can be done using env's chained the
   right way.

## Stats

This stage started out with (after the deletion of modules):
```
Backend x86:

Compiler LoC: 2050
Files: source/emit-late.l source/emit-x86.l source/conversion.l source/emit-early.l source/generic.l source/printing.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l

Evaluator LoC: 2762
Files: source/types.l source/generic.l source/selector.l source/evaluator/primitive-functions.l source/evaluator/vm-late.l source/evaluator/vm-with-file-support.l source/platforms/libc/streams.l source/evaluator/printer.l source/streams-min.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/conversion-min.l source/evaluator/arrays.l source/list-min.l source/evaluator/types.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/vm-early.l source/platforms/libc/eval.l source/platforms/platform-common.l source/platforms/platform-c-based.l source/platforms/libc/libc.l

Alltogether LoC: 4384
Files: source/evaluator/primitive-functions.l source/evaluator/vm-late.l source/evaluator/vm-with-file-support.l source/platforms/libc/streams.l source/evaluator/printer.l source/streams-min.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/conversion-min.l source/evaluator/arrays.l source/evaluator/types.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/vm-early.l source/platforms/libc/eval.l source/platforms/platform-common.l source/platforms/platform-c-based.l source/platforms/libc/libc.l source/emit-late.l source/emit-x86.l source/conversion.l source/emit-early.l source/generic.l source/printing.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l


Backend llvm:

Compiler LoC: 2357
Files: source/emit-late.l source/emit-llvm.l source/conversion.l source/emit-early.l source/generic.l source/printing.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l

Evaluator LoC: 2762
Files: source/types.l source/generic.l source/selector.l source/evaluator/primitive-functions.l source/evaluator/vm-late.l source/evaluator/vm-with-file-support.l source/platforms/libc/streams.l source/evaluator/printer.l source/streams-min.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/conversion-min.l source/evaluator/arrays.l source/list-min.l source/evaluator/types.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/vm-early.l source/platforms/libc/eval.l source/platforms/platform-common.l source/platforms/platform-c-based.l source/platforms/libc/libc.l

Alltogether LoC: 4691
Files: source/evaluator/primitive-functions.l source/evaluator/vm-late.l source/evaluator/vm-with-file-support.l source/platforms/libc/streams.l source/evaluator/printer.l source/streams-min.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/conversion-min.l source/evaluator/arrays.l source/evaluator/types.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/vm-early.l source/platforms/libc/eval.l source/platforms/platform-common.l source/platforms/platform-c-based.l source/platforms/libc/libc.l source/emit-late.l source/emit-llvm.l source/conversion.l source/emit-early.l source/generic.l source/printing.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l
```
