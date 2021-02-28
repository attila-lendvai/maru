# Maru (stage 9)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reason for the new stage

Important `let` bugs were fixed in the previous stage, and a lot of
other goodies also accumulated that helps debugging. When I realized
that some of these bugs are the reason that I cannot implement the new
slave/target isolation, then I just opened a new stage.


## Assorted changes

 - [Switch](commit/7b4c52e730d5a7f0054e827097c9707b57fac1d6) compiled
   literal string representation to full objects: they used to be
   compiled into zero terminated cstrings, but now they are just like
   full heap <string>'s, except that they are emitted into the
   read-only segment, and the GC leaves them alone. This greatly

 - Rework the [slave-target
   isolation](commit/6b486df42e9bc7975049e84ea16f5029133879f7) so that
   once again there are only two modules (`host` and `slave`), and the
   target is just a nested environment that delegates to the slave
   module's `*globals*`. This paved the way to continue working on the
   compilation of `<slector>`'s, which paved the way for the
   introduction of streams in the target code.

 - Introduced *platforms*, and [added the *Linux*
   platform](commit/03bdd99ab25d855b7255b583d1162f823f8378b7) that
   builds into a static executable that directly communicates with the
   Linux kernel through syscalls. The *libc* platform is almost
   completely factored out from the rest of the codebase.

 - Fix build thinko: the host's `boot.l` `require`'d the slave's files
   because of the previously missing/ignored concept of the *working
   directory*.

 - The compiler can now emit full heap objects into the read-only
   segment. The GC ignores them, and writing them results in a
   `sigsegv`. See `emit-object/<string>` and friends.

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
