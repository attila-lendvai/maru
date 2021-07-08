# Maru (stage 10; written in C)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reason for this stage

After having wandered through stage 1 to stage 10, the semantics of
stage 10 is once again rather close to that of the initial `eval.c`
written by Piumarta. Due to this it is worth working on `eval.c` a
little to bring its semantics close enough to `maru.10` that it can
once again bootstrap `eval.l` in the `maru.10` stage.

Once it's done it will be possible to bootstrap `maru.10` from
`maru.9` (and recursively all the way from `maru.0.c99`), **and** in
one step from `maru.10.c99`.

## Status: WIP

It's work in progress. It requires complex enough work in C that I
became uninterested in it for now. I'd much rather work on
`maru.10.common-lisp` instead.

The TODO is **at least** the following:

- introduce the `[set-]current-globals` primitive functions

- fix `expand`; see the bug documented in `eval/expand/bug/1` in
  `tests/evaluator-tests.l`. To run the tests you can use:
  `make TEST_EVAL=../maru.10.c99/eval test-evaluator`

- look through `tests/evaluator-tests.l` and fix tests that turn out
  to be essential for a successful bootstrap
  (e.g. `eval/closures/bug/1`?). Hopefully not all of those are
  essential, because some of the fixes are non-trivial that then need
  to be backported into the C code, which has substantial differences
  from `eval.l` in the `maru.10` branch. Consider copying the maru
  sources into `maru.10.c99`, including the compiler, and patch the
  maru code with some kludges, instead of backporting non-trivial
  fixes from `eval.l` into `eval.c`. Whichever is less headache,
  because `maru.10.c99` is throwaway code.
