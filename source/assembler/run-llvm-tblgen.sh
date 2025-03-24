#$/usr/bin/env sh

# https://llvm.org/docs/TableGen/

# this emits a json output from the X86 tblgen files of llvm. this
# could be used to generate an assembler for maru that is more
# complete than what's available in gen-asm-x86.l.

# to run it you need to check out this dir:
# https://github.com/llvm/llvm-project/tree/main/llvm/lib/Target/X86
# hint: may use https://downgit.github.io to download only this dir.

LLVM=$(guix build llvm | sed -n '2p')

${LLVM}/bin/llvm-tblgen ./X86/X86.td -dump-json -I=${LLVM}/include/ -I=./X86 >x86.json
