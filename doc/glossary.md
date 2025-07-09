# Glossary

 - *VM*: Virtual Machine, i.e. a universe capable of evaluating
   program code to yield literals. It has its own set of laws that are
   treated as axioms to build upon.

 - *host*: The Maru VM animating/hosting the bootstrap process.

 - *level-shift*: aka compilation; a semantics-preserving "level
   shift" from s-expressions to machine code, letting the metacircular
   evaluator in `eval.l` escape from the "infinite metacircular
   regression" to a language grounded in hardware.

 - *target*: The target VM of the "level-shift" operation. Examples
   are: the 32 bit x86 CPU arch, LLVM bitcode, C99, etc. Additionally
   it also provides some services in its runtime environment:
    - *libc* provides `dlopen`; the stdlib functions; malloc/free
      based memory management, etc.
    - the Linux Kernel provides `syscall`s for input/output; memory
      management through the `brk` syscall; killing the unix process
      that was started to animate us, etc.

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
