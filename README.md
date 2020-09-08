# Maru (stage 0)

> **NOTE:** This readme only covers this specific stage of Maru.
> The full README.md file can be found in the git branch of the latest stage.

This is the first stage of Maru, written in C. The `eval.c` in this branch brings to life the first iteration of the Maru universe.

This C code may be thrown away once `eval.l` in the next stage is first successfully compiled to asm
and an eval executable is produced that is functional enough to run the compiler and reproduce itself.

There are some reasons to keep this around, though:
- didactics
- if we lose all the executables then we can bootstrap from C once again
- language experimentation; branching off into a different direction from here
