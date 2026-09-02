# Maru

Self-hosting Lisp dialect with a metacircular evaluator, compiler
backends (x86-64 ELF, aarch64 ELF, LLVM IR), runtime assemblers
(x86-64, aarch64), and three platform targets (libc, posix, linux).

## Build & Test

- `./build.sh bootstrap x86 linux` / `./build.sh bootstrap llvm posix` — full bootstrap (eval0 -> eval1 -> eval2)
- `./build.sh test` — runs all tests appropriate for the current platform
- `./build.sh test-evaluator` — uses default-backend/default-platform
- `./build.sh test-assembler-arm` / `test-assembler-x86` / `test-assembler` — assembler encoding tests vs clang references
- `./build.sh test-compiler <backend> <platform>` — compiled standalone executable tests
- `./build.sh test-standalone <backend> <platform>` — the standalone ET_DYN emission of the elf
  backends: compiles the compiler tests into an ld.so-loaded image and runs it
- `./build.sh repl <backend> <platform>` — launch interactive REPL

Cross-building aarch64 linux on an x86_64 host (runs via qemu-user +
binfmt_misc, needs `qemu-user-static` and the
`gcc-aarch64-linux-gnu` sysroot):

- `./build.sh target/arch=aarch64 bootstrap arm linux`
- `./build.sh target/arch=aarch64 test-evaluator` etc.

Key=value CLI args set variables in build.l's globals (e.g.
`target/arch=aarch64`, `eval0-phase=false`, `ld.so=...`,
`default-backend=arm`, `default-platform=linux`,
`C-obj-emission-type=`, `C-obj-link-type=`). The aarch64 binaries
embed the canonical `/lib/ld-linux-aarch64.so.1` and run transparently
through binfmt_misc.

## Final verification

Match the verification to the blast radius of the change. A localized
change only needs the targets that exercise it (see the narrow gate
below); run the full gate before declaring a wide-reaching change
done -- anything touching the compiler, the assembler, build.l,
boot.l, or the platform layers. When in doubt, the narrow gate plus
one `bootstrap` is the minimum.

The full gate is what CI runs (.github/workflows/ci.yaml), plus what
CI only gets for free on a clean checkout:

- `./build.sh bootstrap llvm libc` / `llvm posix` / `llvm linux` / `x86 linux`
- `./build.sh ld.so=/lib/ld-musl-x86_64.so.1 bootstrap x86 linux` (needs musl installed)
- `./build.sh profiler=1 bootstrap llvm posix` / `profiler=1 bootstrap llvm linux`
- `./build.sh test`
- CI's safety=3 build: sed `*safety*` 1 -> 3 in boot.l, `bootstrap
  llvm linux` and `bootstrap x86 linux`, revert boot.l
- `eval0-phase=false bootstrap x86 linux` (and x86 libc): a clean
  checkout compiles eval0 from scratch; the local eval0 cache skips
  that path and can mask stage-0 breakage. `rm -rf build/eval0`
  simulates a fresh clone with the cache machinery on.
- the cross arm targets (CI runs arm natively):
  `target/arch=aarch64 bootstrap arm linux`,
  `target/arch=aarch64 test-compiler arm libc`, etc.
- `./build.sh C-obj-link-type=static test-compiler x86 libc`

The narrow gate picks the targets that exercise the change:

- assembler encodings: `./build.sh test-assembler` (or `-x86` / `-arm`)
- a backend's emission and FFI: `./build.sh test-compiler <backend> <platform>`
- the evaluator: `./build.sh test-evaluator`
- the ET_EXEC bootstrap bytes: `./build.sh bootstrap x86 linux`
  (carries the fixed-point check implicitly)

The `bootstrap` targets carry the fixed-point check (eval1 must be
byte-identical to eval2) implicitly; no separate step needed.

## Project Structure

- `boot.l` — minimal standard library loaded at bootstrap (~300 lines)
- `source/evaluator/` — the Maru VM (eval.l, gc.l, vm.l, reader.l, etc.)
- `source/compiler/` — compiler backends (emit-x86.l, emit-arm.l, emit-llvm.l)
- `source/compiler/relocatable-elf.l` — the elf writers (c-obj ET_REL, standalone ET_DYN) and the relocation serializer
- `source/assembler/` — runtime assemblers (x86-single-pass.l, x86-instructions.l, arm-instructions.l)
- `source/platforms/` — libc/posix/linux platform layers
- `tests/` — test files (infra.l, assembler-infra.l, test-assembler-x86.l, evaluator-tests.l, etc.)

## Coding Conventions

- Files start with `;;; -*- mode: lisp; coding: us-ascii -*-`
- Source files are ASCII only -- no Unicode in comments or strings
- `define-function` for named functions, `define-form` for macros
- `define-test` + `test-assert` + `run-tests()` for interpreted tests
- Predicates end with `?`, globals in `*...*`. The `%` prefix marks internal helpers that
  exist solely in service of another definition; a function that a reader needs to follow
  the code -- shared across call sites, part of a subsystem's surface -- is not prefixed
  (e.g. `emit-elf-header`), even if it is called from only one place.
- Record/type names in angle brackets: `<segment>`, `<label>`
- 2-space indentation, closing parens on same line (stacked: `))`)

- In ARM assembly, prefer register aliases (FP, LP, SP, XZR, WZR) over
  raw register names (X29, X30, X31) to increase readability

## Testing Patterns

- When writing something intended for human consumption, (comment, commit message, reply to prompt) use as few words as possible. Pick every word meticulously to reduce the volume to a strict minimum. Be down to the point. Less is more.

- Avoid superlatives and praise. Stop telling me I am absolutely right. Give me the cold hard truth.

- Avoid magic numbers and strings by extracting recurring or meaningful values into descriptive constants (const) or enums. Keep self-explanatory, one-off values inline to avoid clutter. If a value comes from a spec (e.g. HTTP 200 OK), use a constant regardless.

- Let the reader of the code breathe. Add empty lines between logical blocks of code.

- Comments should only be added when there is (hidden) complexity, or when external context greatly helps code readability. When this holds, then add a small, to the point, comment to explain the *why*; i.e. the decisions made, relevant constraints, kludges, etc. Use examples when possible. Propose ASCII drawings to explain complete systems.

- Program to levels of abstraction. Lower-level mechanics (e.g., raw hardware I/O, sector parsing, direct socket streams) must be encapsulated in a dedicated driver/abstraction layer. Expose clean, high-level APIs to the rest of the application so calling code works with domain concepts, not raw implementation details.

- Don't touch blocks of code unrelated to the feature you implement. e.g. Don't add comments to a block of code if you did not create it or modify it. As much as possible try to minimize the number of changed lines when implementing a feature.

- Strictly adhere to the layered boundary hierarchy: each layer may only communicate with its immediate neighbor directly below it. Never "punch holes" through layers (e.g., controllers or UI components must never directly call database queries, raw hardware drivers, or low-level network clients; always route through the intermediate service/abstraction layer).

- If the prompt indicates that a bug is being fixed, don't write the fix right away. First write the test. Observe it failing. Then write the fix. And observe the test passing.

- When you write a commit message, follow these 7 rules:
 1) Separate the subject line from the body with a single blank line.

 2) Limit the subject line to 50 characters (72 is the absolute hard limit).

 3) Capitalize the first letter of the subject line.

 4) Do not end the subject line with a period.

 5) Use the following prefixes when appropriate:
   - CI:
   - build:
   - tests:
   - x86:
   - arm:
   - housekeeping - changes that do not change semantics, just readme, comments, code reordering. IOW, changes that do not change the behavior.

 6) Wrap the body text manually at 72 characters to prevent Git formatting issues.

 7) Use the body to explain what and why, not the how. Assume the code explains the how; the message must explain the context and reasoning.

- Tests require `tests/infra.l` (or `tests/assembler-infra.l`) and end with `(run-tests)`

- Assembler tests use `verify-encoding` which compares emitted bytes against clang-built references byte-for-byte

- Compiler tests define their own `define-test` framework inline (compiled to standalone binary)

## Key Gotchas

- `true`/`false` for booleans, NOT `t`/`nil`; `()` is `false`.

- Don't confuse the evolutionary stages (the `maru.9`, `maru.10`,
  `maru.11`... git branches, snapshots of the implementation) with the
  bootstrap stages (`eval0 -> eval1 -> eval2`, the fixed-point ladder
  built within one evolutionary stage; success means eval1 and eval2
  are byte identical). The previous evolutionary stage is materialized
  as a git worktree at `build/maru.[n-1]` and its evaluator ("the host
  binary") animates our whole build: it runs build.l itself, animates
  the compiler, and executes the cgrov machinery from its own tree,
  parsing our `.cgrov` sources by absolute path.

- `eval0` is just a cache, or a convenience: it's compiled from the
  committed maru.11 branch once by the host, and later on it's reused
  until `eval0-phase=false` is specified, or `./build.sh update-eval0`
  is issued, or `build/eval0` is deleted.

- The evaluator's `define-test` registers into `*tests*` at macro-expand time; `run-tests` evals each name

- JIT tests set base to `0xdeadbeef` to verify position-independence

- The `bootstrapping?` flag controls conditional compilation paths

- Register names: `RAX`, `RBX`, `RCX`, `RDX`, `R8`–`R15`, `ESP`, `EAX`, `AL`, etc.

- aarch64 register names: `X0`–`X30`, `W0`–`W30`, `SP`, `XZR`/`WZR`; the sf bit of data processing instructions comes from register width (`sf-check`)

- `gc/read-only-object?` assumes all heap memory lies above the static image — heap chunks acquired via mmap must never be mapped below it (see `platform/acquire-memory`)

- With the default `eval0-phase=true`, test targets compile their eval0 from the committed `build/eval0` checkout, not from the working tree — use `eval0-phase=false` when testing uncommitted fixes

- `define-constant` substitutes at macroexpand-time (like `#define`); `define` is a runtime binding. Use `define-constant` whenever a name must be available during macro expansion (e.g. inside `define-instruction` bodies).

- Prefer verifying through ./build.sh targets (bootstrap, test-*) over ad-hoc repro setups and manual artifact inspection. Stale or partially built trees and hand-rolled invocations mislead into chasing nonexistent bugs; rerun the canonical command clean before diagnosing any failure.

- Two `define-instruction` flavors: `elf-early.l`'s is factory-style (operand cases dispatch by type name, e.g. `((reloc-symbol) (CALLQrel32 $1))`; `%emit` calls it with `()` first to get the singleton); `arm-instructions.l`'s defines plain functions called directly (`(BL label)`). Routing an arm-style instruction through `(emit ...)` fails with "unexpected: ()" — wrap it (see `CALL` in `emit-arm.l`).

- Compiler-level `op/` registers are `<REGISTER>` records; emit-forms unwrap them via `(<REGISTER>-name $1)`. Raw arm instructions take the register symbols (`X16`, ...) whose value is the encoded number (X = 32+i, W = i).

- Function bodies encode when their define runs; a forward reference into a file loaded later dies with `encode/symbol: failed for X`. The require order in `elf-late.l` (cffi-late.l, then relocatable-elf.l) is load-bearing.

- Arch-specific code in the shared files (`cffi-late.l`, `elf-early.l`) must be guarded (`if-at-expand (= "x86" *compiler-backend*)`) or overridden per backend (e.g. `emit-entry-wrapper` in `emit-arm.l`).

- New build-behavior variables must land in `*input-variables-for-build*` (build.l), else toggling their key doesn't trigger rebuilds and stale artifacts mislead.

- `--define` values arrive as strings; dispatch with string `=`.

- The bootstrap fixed point compares the stripped binaries: the link alone is not reproducible (ld records the input file names as `STT_FILE`), so the final artifact is cut from the `.unstripped` by `strip-binary` (build.l). Details: `doc/compiler.md`, "The fixup ledger".

- Mysteriously-() definitions: suspect a compensating local paren imbalance — a missing close swallows the next define into the previous body while the file still balances file-wide. Verify with a per-form paren-delta scan, not a file-wide one.

- Emitted-artifact debugging: `cmp -l` the two binaries to locate the diverging bytes; diff the `.o` disassembly against the linked binary to attribute corruption (assembler encoding vs relocation application).

- `emit-label` protocol: `(label writer size . rest)` — rest carries an optional offset (a `<long>`) then an optional one-element reloc-type list; fixups without a reloc-type are never recorded.
