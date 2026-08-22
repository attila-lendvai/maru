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

 - The x86 backend directly generates x86-64 Elf binary file.

 - Adds support for `aarch64`.

 - A new `build.l` finally supersedes the ugly `Makefile`.

 - Drops the text-assembler based x86 backend to move forward. It may
   be reinstated now that we have a more reasonable build system.

## Stats

TODO
