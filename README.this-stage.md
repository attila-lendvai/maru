# Maru (stage 9)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reason for the new stage

Important `let` bugs were fixed in the previous stage, and a lot of
other goodies also accumulated that helps debugging. When I realized
that the reason I cannot implement the new slave-target isolation is
some of these bugs, then I just opened a new stage.


## Assorted smaller changes

 - rework the slave-target isolation so that there are only two
   modules now (`host` and `slave`), and the target is just a nested
   environment that delegates to the slave modules `*globals*`. this
   paves the way, hopefully, to continue working on the compilation of
   `<slector>`'s, which paves the way for streams in the target.

## Stats

This stage started out with:
```
Backend x86:

Compiler LoC: 1821
Files: source/emit-late.l source/emit-x86.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l

Evaluator LoC: 2542
Files: source/types.l source/generic.l source/selector.l source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/list-min.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l

Alltogether LoC: 3946
Files: source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l source/emit-late.l source/emit-x86.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l


Backend llvm:

Compiler LoC: 2041
Files: source/emit-late.l source/emit-llvm.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l

Evaluator LoC: 2542
Files: source/types.l source/generic.l source/selector.l source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/list-min.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l

Alltogether LoC: 4166
Files: source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l source/emit-late.l source/emit-llvm.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l
```
