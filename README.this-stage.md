# Maru (stage 11)

> **NOTE:** This readme focuses on the aspects of this stage only.
> The full README.md file can be found in the git branch of the [latest stage](https://github.com/attila-lendvai/maru/).

## Reasons for opening this stage

The new x86-64 backend, that directly generates Elf binaries, cannot
easily be integrated into the current makefile-based build system
(which is a mess, waiting to be rewritten in Maru, hopefully in this
stage). The new stage drops the text-assembler based x86 backends to
move forward. They will be reinstated once we have a more reasonable
build system.

## Assorted changes

 - the x86 backend directly generates x86-64 Elf binary file

## Stats

TODO
