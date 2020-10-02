# Maru (stage 6)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Assorted smaller changes
 - TODO

## Stats

This stage started out with:
```
Backend x86:

cat boot.l source/emit-early.l source/emit-x86.l source/emit-late.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1629
cat source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1744
cat boot.l source/emit-early.l source/emit-x86.l source/emit-late.l source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3342

Backend llvm:

cat boot.l source/emit-early.l source/emit-llvm.l source/emit-late.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1820
cat source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1744
cat boot.l source/emit-early.l source/emit-llvm.l source/emit-late.l source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3530
```
