# Maru's architecture

Maru's architecture is described in Ian Piumarta's paper:
[Open, extensible composition models](https://www.piumarta.com/freeco11/freeco11-piumarta-oecm.pdf).

> it is a sketch of how Maru's generalised eval works,
> which is entirely accurate in intent and approach,
> if a little different in some implementation details (Ian Piumarta)

### The Parts - an overview

* `eval.c` (in branch `maru.0.c99`) contains a reader and
[evaluator](https://en.wikipedia.org/wiki/Interpreter_(computing))
(interpreter) for an s-expression language, written in C (more
specifically in [C99](https://en.wikipedia.org/wiki/C99)).

* `eval.l` (in branches `maru.1` and up) contains the same evaluator, written in
(a subset of) this s-expression language that can be compiled to machine code.
In other words, `eval.l` implements a
[metacircular evaluator](https://en.wikipedia.org/wiki/Meta-circular_evaluator)
for the language it is written in.

* `emit.l` contains a compiler from s-expressions to
[IA-32](https://en.wikipedia.org/wiki/IA-32) (x86) assembly (and [LLVM](https://llvm.org/) IR),
written in the s-expression language. This compiler can be thought of
as a semantics-preserving "level shift" from s-expressions to machine code, letting
the metacircular evaluator in `eval.l` escape from the "infinite metacircular regression"
to a language grounded in hardware. A possible metaphor of this is a "target universe"
implemented by some electric circuits (i.e. transistors wired to each other in a CPU)
that provide you a set of axiomatic foundations to build upon while compiling the
abstract to the concrete; while implementing your new universe (the Maru language in
this case). More details are available in [the compiler's doc](compiler.md).

* `boot.l` contains some basic data structures, algorithms, and paradigms that are needed by
`emit.l`; it's written in the s-expression language.

### Self-hosting on `aarch64` Linux (cross-built from x86_64)

The `arm` backend (source/compiler/emit-arm.l) can fully bootstrap on
`aarch64` `linux`.

Even on an x86_64 host through qemu-user with binfmt misc:

```
apt install qemu-user-static gcc-aarch64-linux-gnu
./build.sh target/arch=aarch64 bootstrap arm linux
```

Binaries built for a foreign architecture embed the canonical ELF
interpreter path of the target system, e.g.
`/lib/ld-linux-aarch64.so.1` (overridable with `build.sh ld.so=...`).
This way they can be copied over and run on a real aarch64 Linux
unmodified. When running them under qemu-user instead, `build.sh`
exports `QEMU_LD_PREFIX=/usr/aarch64-linux-gnu`, which makes qemu
resolve that path within the cross toolchain's sysroot.

A note on running under qemu-user with a guest `ld.so`: it loads us high
up in the mmap area where the `brk` cannot grow anymore (even glibc
silently falls back to mmap in this setup), while maru's heap relies
on `brk`. Instead of runtime workarounds we require `QEMU_RESERVED_VA=4G`
(exported by build.sh): it makes qemu pre-allocate a private guest
virtual address region, within which `brk` behaves like on native Linux.
This also keeps the invariant of `gc/read-only-object?` intact, i.e. all
heap memory lying above the static image.

### Self-hosting `i686` Linux on an `x86_64` host

There is no native IA-32 assembler backend, so we must use the `llvm`
backend:

```
apt install clang gcc-multilib
./build.sh target/arch=i686 bootstrap llvm linux
```

No emulator is involved: the Linux kernel runs 32-bit ELF binaries
natively on x86_64 hosts.
