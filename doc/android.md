;;; -*- mode: lisp; coding: us-ascii -*-

# Cross-compiling Maru for Android (aarch64)

## What actually happens with and vanilla aarch64 linux binary

    $ /system/bin/linker64 /tmp/eval1

In this case the binary loads and starts executing. file(1) reports it as
linked against /lib/ld-musl-aarch64.so.1 (musl, not glibc or bionic).

Maru's error-prologue fires during VM initialization, before *symbols* and
*error-output* are set up, cascading to:

    WARNING: error-prologue was reached too early in init...
    NESTED ERROR 1, attempting to print a limited backtrace
    NESTED ERROR 2, giving up...

with exit code 19.

This means the ELF parsing, segment mapping, and entry point all work on
Android. The failure is inside Maru's initialization (likely platform/
syscalls or memory setup), not the linker itself.

## Proper Android support

### Build system (build.l)

- Add target/abi=android alongside the existing gnu ABI.
- effective-ld.so returns /system/bin/linker64 (API 18+) or
  /apex/com.android.runtime/bin/linker64 (API 30+).
- Target triple becomes aarch64-unknown-linux-android.
- Generate android-specific cgrov files against NDK headers.
  Most constants are identical to the gnu ones; some differ.

### ELF emission (source/compiler/emit-arm.l)

- Maybe replace PT_GNU_RELRO with PT_ANDROID_RELRO and add
  DT_ANDROID_RELRO / DT_ANDROID_RELRO_REL entries to .dynamic.
- Possibly adjust e_flags for Android-specific ELF flags.

### Platform layer

Two options:

(a) Add Android conditionals in the linux/ platform. The aarch64
    syscall ABI is identical between Linux and Android (unified
    syscall table, same register conventions). Raw syscalls work
    unchanged. Just need the RELRO and linker path fixes above.

(b) Add a new source/platforms/android/ layer. Cleaner but more
    code. Would use Bionic's libc (dlopen, mmap, etc.) instead
    of raw syscalls.

Option (a) is simpler. The linux platform already avoids glibc
entirely, which is the biggest difference between Linux and Android.

### SELinux and JIT

Android SELinux denies PROT_EXEC on anonymous mmap regions from
untrusted apps. The platform/acquire-memory path (SYS_brk then
SYS_mprotect with PROT_READ|PROT_WRITE|PROT_EXEC) will fail.

Fixes:
- Remove JIT for Android (interpret-only). Simplest, avoids the
  issue entirely.
- Use MAP_JIT (API 23+). Requires calling pthread_jit_write_protect_np
  around code patching.
- Build as a system binary with appropriate SELinux context. Requires
  the binary to live in /system/bin/ or /data/data/<pkg>/.

## What already works for free

- aarch64 syscall numbers are identical (unified table).
- AAPCS64 calling convention is the same.
- X18 is reserved on Android (Shadow Call Stack); Maru does not use it.
- Stack layout at _start() is the same.
- All assembler instructions are architecture-level, not OS-level.
- The linux platform avoids Bionic differences entirely.
