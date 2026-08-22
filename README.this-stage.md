# Maru (stage 11)

> **NOTE:** This readme focuses on the aspects of this stage only.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reasons for opening this stage

The new x86-64 backend, that directly generates Elf binaries, cannot
easily be integrated into the makefile-based build system. But to have
the build rewritten in Maru, we need a previous stage with enough
features to animate it (e.g. we need a working `run-program`).

Another reason is to open up the possibility for a `maru.10.c99`,
i.e. an updated C implementation that can bootstrap `maru.11`,
skipping the earlier evolutionary stages. Stage 10 is the first one
without any leftovers from the superfluous `<module>` abstraction.

## Assorted changes

 - A new `build.l` finally supersedes the ugly `Makefile`.

 - The x86 backend directly generates x86-64 Elf binary files in a
   single pass. The text-assembler based x86 backend has been removed,
   but may be reinstated now that we have a more bearable build
   system.

 - Adds support for `aarch64` Darwin. The LLVM backend can now
   bootstrap on Apple silicon.

## Stats

TODO
