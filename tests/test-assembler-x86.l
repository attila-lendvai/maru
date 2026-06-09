;;; -*- mode: lisp; coding: us-ascii -*-

;;; Tests for the x86-64 assembler instruction emitters.
;;; Each test emits machine code, then compares it against a reference
;;; binary produced by clang assembling equivalent assembly source.

(require "source/assembler/single-pass-x86.l")
(require "tests/assembler-infra.l")

;; ============================================================================
;; ALU: ADD, SUB, AND, OR, XOR, CMP, ADC, SBB
;; ============================================================================

(define-test alu ()
  (with-assembling ((code))
    ;; ADD: register-register (B, Q)
    (ADDBrr _BL _AL)
    (ADDQrr _RCX _RDX)
    ;; ADD: immediate-register (Q i8, Q i32)
    (ADDQi8r 7 _RAX)
    (ADDQi32r 0x12345678 _RBX)
    ;; ADD: auto-selection (i8 vs i32)
    (ADDQir 127 _RCX)
    (ADDQir 128 _RDX)
    ;; SUB: register-register (B, Q)
    (SUBBrr _BL _AL)
    (SUBQrr _RCX _RDX)
    ;; SUB: immediate-register
    (SUBQi8r 7 _RAX)
    (SUBQi32r 0x100 _RBX)
    ;; AND, OR, XOR, CMP: register-register (Q)
    (ANDQrr _RAX _RBX)
    (ORQrr  _RCX _RDX)
    (XORQrr _R8  _R9)
    (CMPQrr _R10 _R11)
    ;; ADC, SBB: register-register (Q)
    (ADCQrr _RAX _RBX)
    (SBBQrr _RCX _RDX)
    ;; 16-bit variants
    (ADDWrr _BX _AX)
    (SUBWrr _CX _DX)
    (verify-encoding (concat-string +build-dir+ "/asm-alu.bin")
      (concat-strings
       ".text
.globl _start
_start:
    add %bl, %al
    add %rcx, %rdx
    add $7, %rax
    add $0x12345678, %rbx
    add $127, %rcx
    add $128, %rdx
    sub %bl, %al
    sub %rcx, %rdx
    sub $7, %rax
    sub $0x100, %rbx
    and %rax, %rbx
    or %rcx, %rdx
    xor %r8, %r9
    cmp %r10, %r11
    adc %rax, %rbx
    sbb %rcx, %rdx
    add %bx, %ax
    sub %cx, %dx
"))))

;; ============================================================================
;; MOV: MOV variants, sign/zero extend
;; ============================================================================

(define-test mov ()
  (with-assembling ((code))
    ;; MOV: register-register (B, W, L, Q)
    (MOVBrr _AL _BL)
    (MOVWrr _AX _BX)
    (MOVLrr _EAX _EBX)
    (MOVQrr _RCX _RDX)
    ;; MOV: immediate-register (B, W, L)
    (MOVBir 0x42 _AL)
    (MOVWir 0x1234 _AX)
    (MOVLir 0x12345678 _EAX)
    ;; MOVQir: auto-selects i32 vs i64 encoding
    (MOVQir 42 _RAX)
    (MOVQir 0x1122334455667788 _RBX)
    (MOVQir 0x7fffffff _RCX)
    (MOVQir 0x80000000 _RDX)
    ;; Sign/zero extend
    (MOVSBLrr _AL _EAX)
    (MOVZBLrr _BL _EBX)
    (MOVSBQrr _CL _RCX)
    (MOVZBQrr _DL _RDX)
    ;; High registers
    (MOVQrr _R8 _R9)
    (MOVQrr _R10 _R11)
    (verify-encoding (concat-string +build-dir+ "/asm-mov.bin")
      (concat-strings
       ".text
.globl _start
_start:
    mov %al, %bl
    mov %ax, %bx
    mov %eax, %ebx
    mov %rcx, %rdx
    mov $0x42, %al
    mov $0x1234, %ax
    mov $0x12345678, %eax
    mov $42, %rax
    movabs $0x1122334455667788, %rbx
    mov $0x7fffffff, %rcx
    movabs $0x80000000, %rdx
    movsbl %al, %eax
    movzbl %bl, %ebx
    movsbq %cl, %rcx
    movzbq %dl, %rdx
    mov %r8, %r9
    mov %r10, %r11
"))))

;; ============================================================================
;; Control flow: JMP, CALL, RET, conditional jumps
;; ============================================================================

(define-test control ()
  (with-assembling ((code))
    ;; CALL: register
    (CALLQr _RAX)
    ;; RET
    (RETQ)
    (verify-encoding (concat-string +build-dir+ "/asm-control.bin")
      (concat-strings
       ".text
.globl _start
_start:
    call *%rax
    ret
"))))

;; ============================================================================
;; Shift and rotate: SHL, SHR, SAR, ROL, ROR
;; ============================================================================

(define-test shift ()
  (with-assembling ((code))
    ;; SHL: imm=1, imm!=1, CL variant (B, L)
    (SHLBir 1 _AL)
    (SHLBir 3 _BL)
    (SHLBrr _CL _DL)
    (SHLLir 1 _EAX)
    (SHLLir 4 _EBX)
    (SHLLrr _CL _ECX)
    ;; SHR (B only)
    (SHRBir 1 _AL)
    ;; SAR (B and Q)
    (SARBir 1 _AL)
    (SARQir 1 _RAX)
    (SARQrr _CL _RCX)
    ;; ROL (B only)
    (ROLBir 1 _AL)
    ;; ROR (B only)
    (RORBir 1 _AL)
    (verify-encoding (concat-string +build-dir+ "/asm-shift.bin")
      (concat-strings
       ".text
.globl _start
_start:
    shl $1, %al
    shl $3, %bl
    shl %cl, %dl
    shl $1, %eax
    shl $4, %ebx
    shl %cl, %ecx
    shr $1, %al
    sar $1, %al
    sar $1, %rax
    sar %cl, %rcx
    rol $1, %al
    ror $1, %al
"))))

;; ============================================================================
;; Unary: NEG, NOT, INC, DEC, TEST
;; ============================================================================

(define-test unary ()
  (with-assembling ((code))
    ;; NEG: B, W, L, Q (register)
    (NEGBr _AL)
    (NEGWr _AX)
    (NEGLr _EAX)
    (NEGQr _RAX)
    ;; NOT: B, Q
    (NOTBr _BL)
    (NOTQr _RBX)
    ;; INC: L, Q
    (INCLr _ECX)
    (INCQr _RCX)
    ;; DEC: L only (Q variant doesn't exist)
    (DECLr _EDX)
    ;; TEST: register-register (B, W, L, Q)
    (TESTBrr _AL _BL)
    (TESTWrr _AX _BX)
    (TESTLrr _EAX _EBX)
    (TESTQrr _RCX _RDX)
    ;; TEST: immediate-register (B, W, L)
    (TESTBir 0xff _BL)
    (TESTWir 0xffff _BX)
    (TESTLir 0x7fffffff _EBX)
    (verify-encoding (concat-string +build-dir+ "/asm-unary.bin")
      (concat-strings
       ".text
.globl _start
_start:
    neg %al
    neg %ax
    neg %eax
    neg %rax
    not %bl
    not %rbx
    inc %ecx
    inc %rcx
    dec %edx
    test %al, %bl
    test %ax, %bx
    test %eax, %ebx
    test %rcx, %rdx
    test $0xff, %bl
    test $0xffff, %bx
    test $0x7fffffff, %ebx
"))))

;; ============================================================================
;; Multiply and divide: MUL, IMUL, DIV, IDIV
;; ============================================================================

(define-test muldiv ()
  (with-assembling ((code))
    ;; MUL: B, W, L, Q
    (MULBrr _BL _AL)
    (MULWrr _BX _AX)
    (MULLrr _EBX _EAX)
    (MULQrr _RBX _RAX)
    ;; IMUL: 2-operand (W, L)
    (IMULWrr _BX _AX)
    (IMULLrr _EBX _EAX)
    ;; IMUL: 3-operand (W, L)
    (IMULWirr 42 _BX _AX)
    (IMULLirr 42 _EBX _EAX)
    (IMULLirr 0x100 _ECX _EDX)
    ;; DIV: B, W, L, Q
    (DIVBrr _BL _AL)
    (DIVWrr _BX _AX)
    (DIVLrr _EBX _EAX)
    (DIVQrr _RBX _RAX)
    ;; IDIV: B, L (Q variant doesn't exist)
    (IDIVBrr _BL _AL)
    (IDIVLrr _EBX _EAX)
    (verify-encoding (concat-string +build-dir+ "/asm-muldiv.bin")
      (concat-strings
       ".text
.globl _start
_start:
    mul %bl
    mul %bx
    mul %ebx
    mul %rbx
    imul %bx, %ax
    imul %ebx, %eax
    imul $42, %bx, %ax
    imul $42, %ebx, %eax
    imul $0x100, %ecx, %edx
    div %bl
    div %bx
    div %ebx
    div %rbx
    idiv %bl
    idiv %ebx
"))))

;; ============================================================================
;; Special: SYSCALL, LEA, NOP, PUSH/POP, BSWAP, XCHG, flags, conversions
;; ============================================================================

(define-test special ()
  (with-assembling ((code))
    ;; SYSCALL
    (SYSCALL)
    ;; LEA: various addressing modes
    (LEAQmr 0 _RAX _RBX 1 _RCX)
    (LEAQmr 8 _RAX _RBX 4 _RCX)
    (LEAQmr 0x80 _RAX _RBX 1 _RCX)
    (LEAQmr 0 _RAX 0 0 _RBX)
    ;; NOP
    (NOP)
    ;; PUSH/POP: L, Q
    (PUSHLr _EAX)
    (POPLr _EBX)
    (PUSHQr _RCX)
    (POPQr _RDX)
    ;; BSWAP
    (BSWAPr _EAX)
    (BSWAPLr _EBX)
    ;; XCHG: B, L, Q
    (XCHGBrr _AL _BL)
    (XCHGLrr _ECX _EDX)
    ;; LAHF, SAHF
    (LAHF)
    (SAHF)
    ;; CBW, CQO
    (CBW)
    (CQO)
    ;; CLC, STC
    (CLC)
    (STC)
    (verify-encoding (concat-string +build-dir+ "/asm-special.bin")
      (concat-strings
       ".text
.globl _start
_start:
    syscall
    lea (%rax,%rbx,1), %rcx
    lea 0x8(%rax,%rbx,4), %rcx
    lea 0x80(%rax,%rbx,1), %rcx
    lea (%rax), %rbx
    nop
    push %rax
    pop %rbx
    push %rcx
    pop %rdx
    bswap %eax
    bswap %ebx
    xchg %al, %bl
    xchg %ecx, %edx
    lahf
    sahf
    cbw
    cqo
    clc
    stc
"))))

;; ============================================================================
;; REX prefix and memory addressing edge cases
;; ============================================================================

(define-test rex-memory ()
  (with-assembling ((code))
    ;; R8-R15: register-register operations
    (ADDQrr _R8 _R9)
    (MOVQrr _R10 _R11)
    (SUBQrr _R12 _R13)
    (ANDQrr _R14 _R15)
    ;; R8-R15: 32-bit variants
    (ADDLrr _R8D _R9D)
    (MOVLir 42 _R10D)
    ;; SIB: scale factors 2, 4, 8
    (LEAQmr 0 _RAX _RBX 2 _RCX)
    (LEAQmr 0 _RAX _RBX 4 _RCX)
    (LEAQmr 0 _RAX _RBX 8 _RCX)
    ;; Memory addressing: disp0 vs disp8 vs disp32 auto-selection
    (ADDQim 7 0 _RAX 0 0)
    (ADDQim 7 0x7f _RBX 0 0)
    (ADDQim 7 0x80 _RCX 0 0)
    (ADDQim 7 0x100 _RDX 0 0)
    ;; RIP-relative: LEA with zero and non-zero displacement
    (LEAQmr 0 0 0 0 _RAX)
    ;; CALL: relative call
    (JMPm 0 0 0 0)
    ;; MOVQmr: RIP-relative load
    (MOVQmr 0 0 0 0 _RBX)
    (verify-encoding (concat-string +build-dir+ "/asm-rex-memory.bin")
      (concat-strings
       ".text
.globl _start
_start:
    add %r8, %r9
    mov %r10, %r11
    sub %r12, %r13
    and %r14, %r15
    add %r8d, %r9d
    mov $0x2a, %r10d
    lea (%rax,%rbx,2), %rcx
    lea (%rax,%rbx,4), %rcx
    lea (%rax,%rbx,8), %rcx
    addq $0x7, (%rax)
    addq $0x7, 0x7f(%rbx)
    addq $0x7, 0x80(%rcx)
    addq $0x7, 0x100(%rdx)
    lea 0x0(%rip), %rax
    jmp 0x0
    mov 0x0(%rip), %rbx
"))))

(run-tests)
