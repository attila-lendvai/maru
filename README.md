# Maru (stage 7)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reason for this stage

To introduce the short lived `*syntax-module*` feature that can be
used in the next stage to isolate the slave and the target namespaces.

## Assorted smaller changes
 - new subrs: load, eval-encoded

 - introduced (the short lived) `*syntax-module*` that is consulted by
   `expand` while looking up `<form>`s. this didn't work out that
   well, and got simplified away in the next stage.

 - makefile: reduced the 3-step bootstrap into a 2-step one. in the
   future i'll try resolve any issues first by working in the
   different branches in parallel. i think this is not always
   possible.

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

And finished with:
```
Backend x86:

cat boot.l source/emit-early.l source/emit-x86.l source/emit-late.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1635
cat source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1781
cat boot.l source/emit-early.l source/emit-x86.l source/emit-late.l source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3388

Backend llvm:

cat boot.l source/emit-early.l source/emit-llvm.l source/emit-late.l			| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1821
cat source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1781
cat boot.l source/emit-early.l source/emit-llvm.l source/emit-late.l source/evaluator/buffer.l source/evaluator/eval.l source/evaluator/gc.l source/evaluator/printer.l source/evaluator/reader.l source/evaluator/subrs.l source/evaluator/arrays.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3572
```
