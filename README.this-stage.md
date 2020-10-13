# Maru (stage 6)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Assorted smaller changes
 - separate the expand-time definitions from the definitions that are meant to be level-shifted into the target.
   this enables us to redefine e.g. the `cons` subr in the target with a function that will then be compiled into the
   target.
 - bring the code that implements the evaluator (the code in `eval.l`) much closer to the code that the evaluator
   understands. no more `k/eval`, it's simply `(define-function eval ...)` now. this kind of source-level
   compatibility will enable us to have files that can be loaded/used verbatim both in the evaluator, and in the
   *implementation* of the evaluator. one such example could be `buffer.l` eventually, but we are not there yet.

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
