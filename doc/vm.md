# Maru's VM

## Overview

The Maru Virtual Machine (VM) is a machine that can execute Maru
programs. It's an implementation detail that currently it's an
interpreter.

It is implemented in terms of a set of axiomatic primitives provided
by the *target* domain, aka the [*platform*](platforms.md) upon which
the Maru VM's implementation is running. A platform is something like
the Linux kernel running on x86_64 hardware, or libc on an aarch64
machine.

The codebase that is running in the target domain is also called the
*kernel*.

### Eval pipeline

There are 3 phases in which a sexp turns into a value:

  1) `expand` is a macroexpand: it looks up and runs any
  user-specified macros. Macros are functions/transformers that can
  return any sexp to be placed instead of their invocation forms. Not
  many surprises here relative to other lisps.

  2) `encode` is a phase where the sexp is transformed into an
  internal data structure that can be easily evaluated (it's just a
  thinly annotated sexp). This process is mostly about instantiating
  `<env>` and `<variable>` objects, and allocating unique indices for
  the variables to be used for addressing the bindings arrays at eval
  time. At read-time all unquoted forms are expanded and encoded.

  3) `eval` runs an encoded form to yield a value at run-time.

`apply` is their cousine that can execute the code captured into a
lambda/closure.

### Data structures

TODO, WARNING: this may be inaccurate, limited by my current understanding.

 - `<env>` is a key-value store that holds `<variable>` objects as
   values; it's the current lexical scope. `*globals*` is a variable
   that holds the toplevel lexical scope.

   - `parent`: no surprises here, variable lookup is delegated upwards.
   - `level`: this is **not** the level in the parent chain. `level`
     is incremented when crossing lambda boundaries. It is needed for
     the implementation of closures capturing variables from their
     lexical environment.

 - `<context>` is a where the variable values are held at evaluation
   time.

   - `bindings` is an array that holds the values. It's indexed
     according to the variable allocation in the `<env>`s that are
     calculated at `encode` time.

Closures capture the `<context>` where they are instantiated and this
is how they share variables with other closures.

## Implementation strategies

 - *size* means bytes; if not, then it should be indicated in its name.

### Boxing/Unboxing

TODO this needs some pondering and may change...

Inside the kernel code (i.e. the code that implements the Maru VM),
all values should be passed and returned as boxed OOP's, except:

 - `<long>` is always expected and returned as an unboxed
   integer.

Unless otherwise requested (using `nounbox`), the
`define-exposed-function` macro automatically unboxes the types that
have an unboxer specified in `*primitive-function-type-accessors*`;
currently these are:
  - `<long>`
  - `<target-vm-pointer>`

The unboxing of other types must be done by a case-by-case basis to
handle their more complex internal structure.

### Value representations

Here's a table of how some special values are represented inside the
VM and the target:

- *false*
  - VM: (), i.e. the empty list. The `false` symbol is bound to it.

  - target: the 0 integer. While bootstrapping, in the target
    namespace `'false` is bound to 0. This means that wherever `false`
    is used the compiler will emit a literal zero integer (i.e. it's
    untagged, it's really just a zero in the target domain).

- *true*
  - VM: The `true` symbol is bound to itself; i.e. writing `true` in
    the lisp code will resolve to the `true` symbol.

  - target: `true` is bound to 1.

This allows us to have a *true* and *false* global binding in both
domains, and in the target *false* can be put as-is in the slots of
heap objects (because 0 = (), i.e. it's a valid Lisp object on the VM
side).
