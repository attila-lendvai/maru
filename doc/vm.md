# Maru's VM, aka the runtime

## Overview

The Maru Virtuam Machine (VM) is a machine that can execute Maru
programs. It is implemented in terms of a set of axiomatic primitives
provided by the *target* VM, aka the [*platform*](platforms.md)
on which the Maru VM's implementation is running.

## Implementation strategies

 - *size* means bytes; if not, then it should be indicated in its name.

### Boxing/Unboxing

In the kernel code (i.e. the code that implements the Maru VM), all values
should be passed and returned as boxed OOP's, except:

 - `<long>` is always expected and returned as an unboxed
   integer.

`define-primitive-function` automatically unboxes `<long>` and
`<target-vm-pointer>`, unless otherwise requested.

### Value representations

The *false* value on the Lisp side, i.e. the empty list, is
represented as the 0 integer on the target side. The *false* symbol in
the target namespace is bound to 0, while on the Lisp side it is bound
to (). This allows us to have a *true* and *false* global binding in
both worlds, and in the target *false* can be put in the slots of heap
objects (because 0 = (), i.e. it's a valid Lisp object).