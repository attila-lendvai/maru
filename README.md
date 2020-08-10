# Maru (stage 5)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Assorted smaller changes
 - `define-structure` -> `define-record`
 - `define-type`
 - `--call` and `--define` command line arguments (until we finally grow a read-from-string to be able to implement --eval)
 - `times-do`
 - make test-compiler-[llvn,x86] test-interpreter

## LLVM backend

Added an LLVM backend that is capable enough to bootstrap itself through both 32 and 64 bit targets.

It's a large-ish commit with plenty of cleanups all around, the x86 backend included.

## Types got bootstrapped

Types in the level-shifted code are represented as integers, but nothing prevents
the Maru version of `type-of` from returning complex objects.

```
$ rlwrap ./build/llvm/x86_64-pc-linux-gnu/eval2 boot.l -
.(type-of <type>)
<type:2>
.(type-of <record>)
<type:2>
.(type-of <string>)
<type:2>
.(type-of (type-of <string>))
<type:2>
.(type-of (type-of (type-of <string>)))
<type:2>
.(<type>-name (type-of <string>))
<record>
.(<type>-id (type-of <string>))
2
.(<record>-effective-slots (type-of <string>))
(id name super direct-slots effective-slots)
.
```

## Stats

This stage finished off with:
```
Backend x86:

cat boot.l emit-early.l emit-x86.l emit-late.l		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1453
cat eval.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1586
cat boot.l emit-early.l emit-x86.l emit-late.l eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3010

Backend llvm:

cat boot.l emit-early.l emit-llvm.l emit-late.l		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1703
cat eval.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1586
cat boot.l emit-early.l emit-llvm.l emit-late.l eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3257
```
