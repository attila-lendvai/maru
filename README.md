# Maru (stage 10; written in C)

> **NOTE:** This readme focuses on the aspects of this stage that are relevant for bootstrapping the next stage.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

This is the stripped down version of the *piumarta* branch to only contain the
`eval.c` code, and extended/modified to be able to bootstrap the `maru.10`
branch.

## Status

Requires complex enough work in C that I became uninterested for
now. I'd much rather work on `maru.10.common-lisp` instead.

## TODO

A most probably partial list of things that are still needed:

- fix `expand`, it needs to recognize and treat things like `let` and `define` specially
