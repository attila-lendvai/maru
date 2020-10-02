# Maru (stage 6)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Assorted smaller changes
 - more detailed backtraces
 - the symbol true now evaluates to itself. it was just too much hassle not to have a self-evaluating true value.
 - first successful LLVM (cross)compile to Darwin.
 - added very basic constant propagation for the x86 backend, yet it nicely yielded around 10% speedup with the bootstrap.
 - symbols are once again in a single global namespace (i.e. not module-specific anymore). this was an unnecessary complexity, it's enough for modules to have isolated bindings.

## Stats

This stage started out with:
```
Backend x86:

cat boot.l emit-early.l emit-x86.l emit-late.l		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1445
cat eval.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1571
cat boot.l emit-early.l emit-x86.l emit-late.l eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
2988

Backend llvm:

cat boot.l emit-early.l emit-llvm.l emit-late.l		| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1695
cat eval.l				| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
1571
cat boot.l emit-early.l emit-llvm.l emit-late.l eval.l	| sed 's/.*debug.*//;s/;.*//' | sort -u | wc -l
3235
```
