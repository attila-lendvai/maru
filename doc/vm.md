# Maru's VM, aka the runtime

## Overview

The Maru Virtuam Machine (VM) is a machine that can execute Maru
programs. It is implemented in terms of a set of axiomatic primitives
provided by the *target* VM, aka the *platform* upon which the Maru
VM's implementation is running.

## Implementation strategies

 - *size* means bytes; if not, then it should be indicated in its name.

### Boxing/Unboxing

In the kernel code (i.e. the code that implements the Maru VM), all values
should be passed and returned as boxed OOP's, except:

 - `<long>` is always expected and returned as an unboxed
   integer.

`define-primitive-function` automatically unboxes `<long>` and
`<target-vm-pointer>`, unless otherwise requested.
