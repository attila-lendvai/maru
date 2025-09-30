# Maru's VM, aka the runtime

## Overview

The Maru Virtual Machine (VM) is a machine that can execute Maru
programs. It's an implementation detail that currently it's an
interpreter.

It is implemented in terms of a set of axiomatic primitives provided
by the *target* domain, aka the [*platform*](platforms.md) upon which
the Maru VM's implementation is running. Think of something like the
Linux kernel running on x86_64, or libc on an aarch64 machine.

The code running in the target domain is also called the *kernel*.

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
