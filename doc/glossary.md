# Glossary

 - *vm*: Virtual Machine, i.e. a universe capable of executing code,
   encoded some way. It has its own set of laws that are accepted as
   axioms.

 - *host*: The Maru vm animating the bootstrap process.

 - *target*: The target vm of the "level-shift" operation (e.g. an x86
    CPU, LLVM bitcode, etc; plus some runtime environment,
    e.g. *libc*, or the Linux Kernel, etc).

 - *kernel*: the part of the codebase that runs in the target vm, and
    implements the evaluator.

 - *slave*: The Maru VM that is being bootstrapped and that will
   spring to life once the result of the level-shift (the compilation)
   gets executed in the target VM. Its name comes from the idea that,
   having a dynamic compiler, the host could start up the slave VM
   under its full supervision.

 - *oop*: Ordinary Object Pointer, a managed pointer pointing to a
    valid Maru value. Note that sometimes the pointee can be
    packed/encoded right into the machine word (that is supposedly
    pointing to a heap object, but not in this case). Such "pointers"
    are marked by their least significant bits. We can do this because
    pointers to machine words must be aligned, so the 3 least
    significant zero bits of 32 bit pointers are zero, while 64 bit
    pointers have 4 such bits. It makes sense to use those bits to
    encode 8-16 types, like a small-integer, right into the pointer.

 - *word*: the natural data size the target architecture; e.g. 64 bits
    for `x86_64`. Must be equal to the size of a pointer.

 - *long*: a signed integer of the size of a *word* in the target.

 - *oop-at*: pointer dereferencing primitive

 - *level shift*: aka compilation; a semantics-preserving "level
   shift" from s-expressions to machine code, letting the metacircular
   evaluator in `eval.l` escape from the "infinite metacircular
   regression" to a language grounded in hardware.

 - `*foo*` is a global variable
 - `+foo+` is a constant
 - `-foo-` is a variable that comes implicitly from the lexical scope
 - `<foo>` is a type
