# Platforms

A *platform* is a "holding universe" or "holding environment" (aka
Virtual Machine) in which Maru itself is brought to life. IOW, it's a
computing model that is accepted as axiomatic, and is used to
implement another VM, or computing system, that is called Maru.

List of platforms:

- [libc, aka C99](#libc)
- [Linux](#linux)
- [Metacircular](#metacircular)

## libc

Assumes a CPU and memory ala the [von Neumann
architecture](https://en.wikipedia.org/wiki/Von_Neumann_architecture)
and the standard library of the C language (aka
[libc](https://en.wikipedia.org/wiki/Libc)).

## Linux

Similar to libc, but it only assumes the Linux kernel as axiomatic,
i.e. nothing about libc, and for that matter about the C language. For
all intents and purposes, the Linux kernel could be implemented in
assembly, and Maru's Linux platform wouldn't change one bit.

Linux passes `argc`, `argv`, and the `env` variables on the CPU stack,
and we parse them from there. All communication with the "holding
universe" is done through the Linux kernel's `syscall` mechanism.

## Metacircular

Assumes that our "holding universe" is another instance of us.

The metacircular platform is still very much WIP.
