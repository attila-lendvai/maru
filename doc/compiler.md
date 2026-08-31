# Maru's compiler

## Overview

Maru, the language, is implemented as an evaluator (aka an interpreter, a
VM). But Maru is also self-hosting, which means that the
implementation language of this evaluator is also Maru... (although only
a subset of the full language).

The compiler can compile a list of named definitions (an *environment*) to the
target language; i.e. to the language of the foundational [platform](platforms.md)
that was chosen to build the Maru VM on top of (e.g. x86 machine code,
LLVM, libc, the Linux kernel, etc).

This subset of Maru is basically a list of toplevel definitions
collected into the target environment and then level-shifted to the
target arch (see `compile-definition`).

Backends:
 - **LLVM**: currently emits a .ll text file, and as such it depends
   on a C toolchain and LLVM. Future plan is to link to the LLVM libs
   and generate .bc into a memory buffer, and then emit binaries
   without exec'ing external binaries.

 - **x86**, **arm**: they emit ELF64: by default a relocatable
   object (ET_REL, the c-obj) that the C toolchain links; they can
   also emit a self-contained image. See below.


## Literal values understood by the compiler

 - `()`, i.e. `nil`, which is compiled to the `<undefined>` value in
   the target, which is the integer zero to keep our sanity with
   comparisons in the lower realm.

 - `<long>` literals, compiled to word-sized untagged integers in the
   lower

 - `<string>` literals are compiled into full `<string>` objects
   (i.e. with a (partial) GC header prior to the OOP), but in the
   read-only segment instead of the normal heap

 - `<target-function>`s are used for introducing functions in the
   upper that are implemented by code emitted into the lower. Usually
   these are called primitive functions.

 - `<selector>`s; i.e. functions that dispatch on the type of their
   first parameter (they are used for streams, and may be used later
   in `expand`, `encode`, and in a possible PEG generated sexp parser
   replacing the handwritten one).

 - `<expr>`s; i.e. toplevel first-class functions (without variable
   capturing, the compiler does not support closures yet). Their body
   in `encode`ed form (see below) is a nested tree of these objects
   (see `compile`).

Additionally, the body forms of functions may also contain these:

 - `<variable>` objects; i.e. resolved variable references

 - `<pair>`s; i.e. cons cells that can form a tree of lisp call forms

This seems rather limited at first sight, but keep in mind that the
meta level that is assembling this environment can use the full Maru
language (as brought to life by the Maru evaluator that is hosting the
bootstrap process).


## Literals as full heap objects

For some literal values the compiler emits valid heap objects into the
read-only segment of the lower realm. These objects have a type and
flags prefix, but the GC ignores, and writing to them results in a
`sigsegv`. See `emit-object/<string>` and friends.

The reason for this is that when we construct heap objects, it's a
headache if some of their slots are themselves not valid heap objects
(e.g. just a pointer to a null terminated C string without any GC
header prefixing it).

This also introduces a possibility for more runtime type checks, and
decreases the boxing/unboxing friction between the upper (Maru) and
the lower VM; e.g. the lower can call the pretty-printing
infrastructure of the upper, including using streams to print to
e.g. the `*debug-output*`.

Without this feature, we would need a way to specify which slot of
heap objects are to be walked by the GC and which should be ignored
(as opposed to the current machinery of marking an entire heap object
opaque for the GC). And Maru code messing around with those slots --
some of them untagged -- would lead to crashes.

The price we pay is +1 (partial) GC header for each literal object
emitted this way (i.e. only the ones that have a non-tagged-immediate
representation). Currently this means +2 words: `flags` and `type`;
the rest of the GC header slots (`next` and `chunk-size`) are not
emitted/needed.


## Peculiarities of the compiler

i.e. peculiarities of the subset of Maru that the compiler can
level-shift to machine code; you can also read it as a TODO list:

 - `=` is simple integer equality, i.e. it's very different from the
   `=` in the VM that does e.g. string comparison

 - lambda's cannot capture variables

 - no support for variable number of args for functions

 - special-operators can only take two arguments; i.e. arithmetics,
   comparators, etc (and the error message is obscure)

 - more, TODO


## Compile-time phases: `expand` and `encode`

Maru's compile-time has two phases: `expand` and `encode`. The former
is a usual lisp macroexpand, from sexp forms to sexp forms, i.e. no
surprises there.

The `encode` phase makes sure that all variable references in the
expanded code get resolved to either full <variable> objects, or to
some primitives (i.e. a `let` symbol will be resolved to the `<fixed>`
that is stored in the global variable called `let`, which in turn
contains the code that implements the semantics of `let` at evaluation
time).

This results in a code representation that is rather fast to evaluate,
because each variable is preassigned a fixed index at compile time,
that is then used at runtime to index an execution context to get hold
of the value.

When the code is being evaluated, then this context is a `<context>`
object that holds an `<array>` of places. Global variable values are
stored directly in the `value` slot of `<variable>` objects.

When the code is being compiled, then the `value` slot of `<variable>`
objects is used to store the CPU stack offset that is assigned as the
place that holds the variable's value when the compiled code is
executed. Global variables are placed at fixed memory addresses.

TODO: it would be nice to merge the anomaly between the treatment of
global and local variables. Aren't global variables simply the
captured variables of an imaginary extra lambda that encapsulates all
the toplevel definitions? IOW, for a lambda a captured variable is
basically a global=external=outside variable.

This could come together with the introduction of nested local
`define`s, too.


## ELF-emitting backends

The `x86` and `arm` backends run a single compile pass that emits
definitions into segments (code, ro-data, data, bss) and records a
fixup for every hole whose resolution is deferred. One ledger, three
shapes of output, selected by `C-obj-emission-type` (default per
platform: `c-obj` on the C-based platforms, `standalone` on the linux
bootstrap; the `C-obj-emission-type=` build key overrides it):

```
             compile-env (one pass)
  env --> definitions into segments
      +-> fixups: (segment, hole, target, role)
                   |
     +-------------+--------------------+
     v             v                    v
   c-obj        standalone           ET_EXEC
   (ET_REL)     (ET_DYN)             (linux bootstrap)
   .rela.*      .rela.dyn, dynsym    ledger ignored: all holes
   symtab       GOT cells,           back-patched at fixed
   main, _start trampolines, _start  addresses
     |
     v
   clang -o exe exe.o libc.o
```

 - **c-obj**: a plain relocatable object linked by the C toolchain
   (the link phase in `build.l`) with the platform's C support files
   (e.g. `libc.c`). This is our admission ticket into the C universe:
   foreign calls go out as `PLT32`/`CALL26` relocations against
   undefined symbols, resolved by ld.
 - **standalone**: a self-contained image with its own
   `.dynsym`/`.rela.dyn`; ld.so resolves the externals at load time
   (a GOT cell per external, filled via `GLOB_DAT`, and a code
   trampoline jumping through it).

The ET_DYN complexity (cross-segment references, relocation info)
stems from ASLR: if the segments are not loaded at fixed addresses,
every absolute word needs a relocation. E.g. the `code` slot of a
`<target-function>` points from `data` into `text`.


### The fixup ledger

Fixups are recorded where the holes are born, in the instruction
encoders (`source/assembler/single-pass*.l`): only there is the
encoding geometry known (field offset, width, pc-relative or
absolute). The roles are arch-agnostic (`pc32`, `jump26`,
`adr-prel-lo21`, `abs64`, ...); `reloc-number` in
`source/compiler/relocatable-elf.l` maps them to the target's
relocation numbers.

The type of the reference decides what happens:

 - `<label>` (internal): the assembler back-patches the hole when the
   label is defined, and records it; the c-obj writer emits it into
   `.rela.*` against the section symbols, because ld does the final
   layout. Pc-relative encodings are position-independent, so the
   standalone image needs no dynamic fixup for them.
 - `<reloc-symbol>` (undefined external, i.e. FFI): never
   self-patchable; always recorded, placeholder emitted.
 - raw `<long>`: carries no referential intent; nothing recorded.

Only the absolute data words (`abs64`) need dynamic fixup in the
standalone image (`R_*_RELATIVE`); in the c-obj they become `R_*_64`
against section symbols.

Module-internal symbols are `STB_LOCAL` in the c-obj symtab (the env
holds shadowed bindings, e.g. two `cdr.code`, which ld would reject);
only `main`, `_start` and the UND externals are global.

The link alone is not reproducible: the linker records the input
file names as `STT_FILE` symbols (eval1.o vs eval2.o). So the c-obj
is linked into an `.unstripped` binary, and `llvm-strip` cuts the
final artifact -- like the llvm backend -- and the bootstrap's
fixed-point check (eval1 = eval2) compares the stripped binaries.


## Compilation of types

Maru is dinamically typed, and currently there's no static
typechecking in its compilation. This will hopefully change.

Unsurprisingly, types are represented in the target by their *type
id*'s, i.e. by word-sized integers. The `<undefined>` type doesn't
necessarily need to be assigned the zero type id, but its single valid
value is the zero word in the target, and `()`, aka `false` in the
evaluator.

TODO: Much needs to be worked out regarding the level-shifting of
types. Currently, the very same `boot.l` needs to be loaded when we
want to use our `eval.exe` that was used while compiling it -- at
least regarding the types defined in the chaing of files that get
loaded. Ideally, the compiler should emit enough this-and-that that
the `eval.exe` recreates all the type related heap objects as part of
its startup code. This could either be done by the usual way of having
a separate exe and a heap image file, or by emitting objects into the
static space, or having also a dynamic space that is relocated into
the heap at startup.


## Knowledge base

 - [stack red-zone](https://en.wikipedia.org/wiki/Red_zone_%28computing%29)
 - [x86 position indepenedent code](https://www.technovelty.org/c/position-independent-code-and-x86-64-libraries.html)
 - [GCC and Bare Metal Programming](https://cs107e.github.io/guides/gcc/)
