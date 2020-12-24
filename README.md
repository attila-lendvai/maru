# Maru (stage 8)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reason for this stage

Use the `*syntax-module*` feature of the previous stage to isolate the
slave and the target namespaces. This felt hackish and wasn't
satisfactory, so it got replaced by another scheme that used three
separate modules for the host, slave, target namespaces. This also
turned out to be more complexity than necessary, and got replaced in
the next stage with a simpler and more flexible setup.

## Assorted smaller changes

 - separate the expand-time definitions from the definitions that are
   meant to be level-shifted/compiled into the target. IOW, we now
   have a separate namespace for the syntax-level stuff. this enables
   us to name the implementation of e.g `cons` the same as the `cons`
   that is being used by the macros that are evaluated by the host,
   and that build up the set of definitions that should be compiled.

 - use this isolation to bring the code that implements the evaluator
   (the code in `eval.l`) much closer to the code that the evaluator
   understands. no more `k/eval`, it's simply `(define-function eval
   ...)` now. this kind of source-level compatibility will enable us
   to have files that can be loaded/used verbatim both in the
   evaluator, and in the *implementation* of the evaluator. one such
   example could be `buffer.l` eventually, but we are not there yet.
   this also enables us to later on to load the interpreter into
   another instance of the interpreter (metacircularity).

 - `expand` now considers any `set-foo` on the way down while
   recursively expanding the form. this enables us to define a custom
   `set-slot-value` hook in eval.l and thus eliminate the `get/put`
   protocol alltogether

 - introduce platforms: platform-libc.l first, platform-metacircular.l
   later. this also paves the way for compiling Maru directly to a
   barebone hardware platform without any operating system, e.g. to an
   Arduino or a Raspberry Pi.

 - better backtraces. it's more error tolerant now.

 - `dump` now errors instead of printing unreadable stuff

 - introduce `<boxed-type>` and the `box`/`unbox` protocol

 - some simple peephole optimizations for the x86 backend

 - fixed some longstanding `let` bugs

 - fixed `expand` not to mindlessly expand stuff like the parameters of
   a lambda form

 - rework the slave-target isolation to use 3 separate modules. this
   enables us to eliminate `*syntax-module*` from eval.l

 - introduce `[set-]char-at`

 - `<subr>` got renamed to `<primitive-function>`

 - started splitting out definitions from boot.l into separate files
   so that they can also be loaded into the level-shifted code.

 - added `define-symbol-form`

 - made `encode` idempotent: calling `encode` on an already encoded
   form will just return it. with this eliminate `eval-encoded`.

 - fix the escaping of target entities: properly isolate the maru and
   the libc namespace in the target

 - added `define-primitive-function`: using this macro you can
   straight away export a function as a `<primitive-function>` in the
   evaluator

 - added `\e` to the reader, first only as a hex code. in the next
   stage this hex code will be "encoded/bootstrapped into the exe",
   and can be simplified away.

 - multimethods allow nil as type dispatch, and now consider
   inheritance, too

 - added `<C-variable>` and use it to deal with `stdout` &co.

 - added `case`

## Stats

This stage started out with:
```
Backend x86:

cat boot.l source/emit-early.l source/emit-x86.l source/emit-late.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1612
cat source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1770
cat boot.l source/emit-early.l source/emit-x86.l source/emit-late.l source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3354

Backend llvm:

cat boot.l source/emit-early.l source/emit-llvm.l source/emit-late.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1798
cat source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1770
cat boot.l source/emit-early.l source/emit-llvm.l source/emit-late.l source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3538
```

And finished with:
```
Backend x86:

Compiler LoC: 1931
Files: source/emit-late.l source/emit-x86.l source/env-min.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l

Evaluator LoC: 2555
Files: source/types.l source/generic.l source/selector.l source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/list-min.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l

Alltogether LoC: 4032
Files: source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l source/emit-late.l source/emit-x86.l source/env-min.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l


Backend llvm:

Compiler LoC: 2153
Files: source/emit-late.l source/emit-llvm.l source/env-min.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l

Evaluator LoC: 2555
Files: source/types.l source/generic.l source/selector.l source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/env-min.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/list-min.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l

Alltogether LoC: 4254
Files: source/evaluator/primitive-functions.l source/evaluator/printer.l source/evaluator/reader.l source/sequences-min.l source/evaluator/buffer.l source/evaluator/arrays.l source/evaluator/gc.l source/evaluator/eval.l source/evaluator/platform.l source/evaluator/platform-libc.l source/emit-late.l source/emit-llvm.l source/env-min.l source/emit-early.l source/generic.l source/selector.l source/types.l source/sequences-basic.l source/iteration-min.l source/destructuring.l source/list-basic.l source/control-structures.l source/list-min.l boot.l
```
