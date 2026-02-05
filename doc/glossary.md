# Glossary

 - *VM*: Virtual Machine, i.e. a *realm* capable of evaluating program
   code to yield values for an *upper*/encompassing/supervising
   realm. It has its own set of laws that are treated as axioms when
   building upon them.

 - *host*: The Maru VM animating/hosting the bootstrap process (note
   that this is different from the GNU build-host-target
   nomenclature).

 - *level-shift*: aka compilation; a semantics-preserving "level
   shift" operation turning s-expressions to machine code, letting the
   metacircular evaluator in `eval.l` escape from the "infinite
   metacircular regression" to a language grounded in hardware. An
   operation that turns abstractions in the *upper* realm into
   corresponding implementations in the *lower* or *target* realm.

 - *upper*/*lower*: the two sides of a *level-shift* operation.

 - *target*: The target realm of the "level-shift" operation. It has
   two important components:
    1. one that provides the execution semantics, and
    2. one that provides services to interface with the outside world.

   Some example targets are:

    - 32 bit x86 CPU machine code + the Linux kernel (i.e. using
      kernel `syscall`s for input/output; memory management using the
      `brk` syscall; killing the unix process in which we are being
      animated)

    - C99 semantics as execution engine; and *libc* providing the
      services (the stdlib functions for IO; `malloc`/`free` based
      memory management, etc)

    - LLVM bitcode compiled to some (!) 64 bit arch + *libc* (*libc*
      itself is independent of the specific arch, it (mostly) only
      depends on the word size of the target)

    - 32 bit C99 code; and the Linux kernel

    - 32 bit x86 CPU; and reading/writing hardware registers (for IO
      through a serial port, or accessing some storage device, etc).

 - *kernel*: the part of the codebase that runs in the target VM, and
   implements the evaluator building on the target's axioms.

 - *slave*: The Maru codebase that is being bootstrapped (i.e. being
   loaded into the host in an isolated namespace and then compiled),
   and that will spring to life once the result of the level-shift
   eventually gets executed in the target VM. Its name comes from the
   idea that -- having a dynamic compiler --, the host could start up
   the slave VM under its full supervision. (Will be renamed to
   something like *replica*, *child*, *buildee*, *intermediate*,
   because it's not running under the authority/supervision of the
   host)

 - *oop*: Ordinary Object Pointer, a managed pointer pointing to a
   valid value in the Maru VM. Note that in case of
   *<immediate-type>*s the pointee is packed/encoded right into the
   machine word itself that is otherwise pointing to another address
   in the heap. Such "pointers" are marked by their least significant
   bits. We can do this because pointers to machine words must be
   aligned, so the 3 least significant bits of 32 bit pointers are
   zero, while 64 bit pointers have 4 such bits. It makes sense to use
   those bits to encode 8-16 types (e.g a fixed bit integer, or the
   *<undefined>* marker), right into the pointer.

 - *word*: the natural data size the target architecture; e.g. 64 bits
   for `x86_64`. Must be equal to the size of a pointer.

 - *long*: a signed integer of the size of a *word* in the target.

 - *oop-at*: pointer dereferencing primitive

 - `*foo*` is a global variable
 - `+foo+` is a constant
 - `-foo-` is a variable that comes implicitly from the lexical scope
 - `<foo>` is a type
