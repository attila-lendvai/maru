;;; -*- mode: lisp; coding: us-ascii -*-

;;; Tests for the x86-64 assembler instruction emitters.
;;; Each test emits machine code, then compares it against a reference
;;; binary produced by clang assembling equivalent assembly source.

(require "source/assembler/single-pass-x86.l")
(require "tests/assembler-infra.l")

;; ============================================================================
;; ALU: ADD, SUB, AND, OR, XOR, CMP, ADC, SBB
;; ============================================================================

(define-form define-asm-test (name asm . instructions)
  `(define-test ,name ()
     (with-assembling ((code))
       ,@instructions

       (verify-encoding/x86
        ,(symbol->string name)
        ,(concat-string ".text
.globl _start
_start:
" asm)))))

(define-asm-test alu
  "
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
"
  ;; ADD: register-register (B, Q)
  (ADDBrr BL AL)
  (ADDQrr RCX RDX)
  ;; ADD: immediate-register (Q i8, Q i32)
  (ADDQi8r 7 RAX)
  (ADDQi32r 0x12345678 RBX)
  ;; ADD: auto-selection (i8 vs i32)
  (ADDQir 127 RCX)
  (ADDQir 128 RDX)
  ;; SUB: register-register (B, Q)
  (SUBBrr BL AL)
  (SUBQrr RCX RDX)
  ;; SUB: immediate-register
  (SUBQi8r 7 RAX)
  (SUBQi32r 0x100 RBX)
  ;; AND, OR, XOR, CMP: register-register (Q)
  (ANDQrr RAX RBX)
  (ORQrr  RCX RDX)
  (XORQrr R8  R9)
  (CMPQrr R10 R11)
  ;; ADC, SBB: register-register (Q)
  (ADCQrr RAX RBX)
  (SBBQrr RCX RDX)
  ;; 16-bit variants
  (ADDWrr BX AX)
  (SUBWrr CX DX)
  )

;; ============================================================================
;; MOV: MOV variants, sign/zero extend
;; ============================================================================

(define-asm-test mov
  "
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
"
  ;; MOV: register-register (B, W, L, Q)
  (MOVBrr AL BL)
  (MOVWrr AX BX)
  (MOVLrr EAX EBX)
  (MOVQrr RCX RDX)
  ;; MOV: immediate-register (B, W, L)
  (MOVBir 0x42 AL)
  (MOVWir 0x1234 AX)
  (MOVLir 0x12345678 EAX)
  ;; MOVQir: auto-selects i32 vs i64 encoding
  (MOVQir 42 RAX)
  (MOVQir 0x1122334455667788 RBX)
  (MOVQir 0x7fffffff RCX)
  (MOVQir 0x80000000 RDX)
  ;; Sign/zero extend
  (MOVSBLrr AL EAX)
  (MOVZBLrr BL EBX)
  (MOVSBQrr CL RCX)
  (MOVZBQrr DL RDX)
  ;; High registers
  (MOVQrr R8 R9)
  (MOVQrr R10 R11)
  )

;; ============================================================================
;; Control flow: JMP, CALL, RET, conditional jumps
;; ============================================================================

(define-asm-test control
  "
  call *%rax
  ret
"
  ;; CALL: register
  (CALLQr RAX)
  ;; RET
  (RETQ)
  )

;; ============================================================================
;; Relative and RIP-relative control transfer
;; ============================================================================

(define-asm-test relative-control
  "
  call 0x0
  jmp 0x0
  callq *0x0(%rip)
  callq *-4(%rip)
  callq *0x100(%rip)
  jmpq *0x0(%rip)
  jmpq *8(%rip)
  callq *(%rbx)
  callq *0x7f(%rbx)
  jmpq *0x100(%rcx)
  callq *8(%rbp)
  callq *8(%r13)
  jmpq *(%r12,%rbx,2)
  callq *0x0(,%r12,8)
"
  ;; direct relative calls/jumps
  (CALLQrel32 0)
  (JMPQrel32 0)
  ;; dispatcher: (D 0 0 0) selects rip+disp32
  (CALLQm 0 0 0 0)
  (CALLQm -4 0 0 0)
  ;; named rip forms
  (CALLQripm 0x100)
  (JMPQm 0 0 0 0)
  (JMPQripm 8)
  ;; base+disp, disp8/32 auto-selection
  (CALLQm 0 RBX 0 0)
  (CALLQm 0x7f RBX 0 0)
  (JMPQm 0x100 RCX 0 0)
  (CALLQm 8 RBP 0 0)
  ;; REX.B: high base register
  (CALLQm 8 R13 0 0)
  ;; SIB: index+scale, REX.B
  (JMPQm 0 R12 RBX 2)
  ;; SIB: index only + disp32, REX.X
  (CALLQm 0 0 R12 8)
  )

;; ============================================================================
;; Shift and rotate: SHL, SHR, SAR, ROL, ROR
;; ============================================================================

(define-asm-test shift
  "
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
"
  ;; SHL: imm=1, imm!=1, CL variant (B, L)
  (SHLBir 1 AL)
  (SHLBir 3 BL)
  (SHLBrr CL DL)
  (SHLLir 1 EAX)
  (SHLLir 4 EBX)
  (SHLLrr CL ECX)
  ;; SHR (B only)
  (SHRBir 1 AL)
  ;; SAR (B and Q)
  (SARBir 1 AL)
  (SARQir 1 RAX)
  (SARQrr CL RCX)
  ;; ROL (B only)
  (ROLBir 1 AL)
  ;; ROR (B only)
  (RORBir 1 AL)
  )

;; ============================================================================
;; Unary: NEG, NOT, INC, DEC, TEST
;; ============================================================================

(define-asm-test unary
  "
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
"
  ;; NEG: B, W, L, Q (register)
  (NEGBr AL)
  (NEGWr AX)
  (NEGLr EAX)
  (NEGQr RAX)
  ;; NOT: B, Q
  (NOTBr BL)
  (NOTQr RBX)
  ;; INC: L, Q
  (INCLr ECX)
  (INCQr RCX)
  ;; DEC: L only (Q variant doesn't exist)
  (DECLr EDX)
  ;; TEST: register-register (B, W, L, Q)
  (TESTBrr AL BL)
  (TESTWrr AX BX)
  (TESTLrr EAX EBX)
  (TESTQrr RCX RDX)
  ;; TEST: immediate-register (B, W, L)
  (TESTBir 0xff BL)
  (TESTWir 0xffff BX)
  (TESTLir 0x7fffffff EBX)
  )

;; ============================================================================
;; Multiply and divide: MUL, IMUL, DIV, IDIV
;; ============================================================================

(define-asm-test muldiv
  "
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
"
  ;; MUL: B, W, L, Q
  (MULBrr BL AL)
  (MULWrr BX AX)
  (MULLrr EBX EAX)
  (MULQrr RBX RAX)
  ;; IMUL: 2-operand (W, L)
  (IMULWrr BX AX)
  (IMULLrr EBX EAX)
  ;; IMUL: 3-operand (W, L)
  (IMULWirr 42 BX AX)
  (IMULLirr 42 EBX EAX)
  (IMULLirr 0x100 ECX EDX)
  ;; DIV: B, W, L, Q
  (DIVBrr BL AL)
  (DIVWrr BX AX)
  (DIVLrr EBX EAX)
  (DIVQrr RBX RAX)
  ;; IDIV: B, L (Q variant doesn't exist)
  (IDIVBrr BL AL)
  (IDIVLrr EBX EAX)
  )

;; ============================================================================
;; Special: SYSCALL, LEA, NOP, PUSH/POP, BSWAP, XCHG, flags, conversions
;; ============================================================================

(define-asm-test special
  "
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
"
  ;; SYSCALL
  (SYSCALL)
  ;; LEA: various addressing modes
  (LEAQmr 0 RAX RBX 1 RCX)
  (LEAQmr 8 RAX RBX 4 RCX)
  (LEAQmr 0x80 RAX RBX 1 RCX)
  (LEAQmr 0 RAX 0 0 RBX)
  ;; NOP
  (NOP)
  ;; PUSH/POP: L, Q
  (PUSHLr EAX)
  (POPLr EBX)
  (PUSHQr RCX)
  (POPQr RDX)
  ;; BSWAP
  (BSWAPr EAX)
  (BSWAPLr EBX)
  ;; XCHG: B, L, Q
  (XCHGBrr AL BL)
  (XCHGLrr ECX EDX)
  ;; LAHF, SAHF
  (LAHF)
  (SAHF)
  ;; CBW, CQO
  (CBW)
  (CQO)
  ;; CLC, STC
  (CLC)
  (STC)
  )

;; ============================================================================
;; REX prefix and memory addressing edge cases
;; ============================================================================

(define-asm-test rex-memory
  "
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
"
  ;; R8-R15: register-register operations
  (ADDQrr R8 R9)
  (MOVQrr R10 R11)
  (SUBQrr R12 R13)
  (ANDQrr R14 R15)
  ;; R8-R15: 32-bit variants
  (ADDLrr R8D R9D)
  (MOVLir 42 R10D)
  ;; SIB: scale factors 2, 4, 8
  (LEAQmr 0 RAX RBX 2 RCX)
  (LEAQmr 0 RAX RBX 4 RCX)
  (LEAQmr 0 RAX RBX 8 RCX)
  ;; Memory addressing: disp0 vs disp8 vs disp32 auto-selection
  (ADDQim 7 0 RAX 0 0)
  (ADDQim 7 0x7f RBX 0 0)
  (ADDQim 7 0x80 RCX 0 0)
  (ADDQim 7 0x100 RDX 0 0)
  ;; RIP-relative: LEA with zero and non-zero displacement
  (LEAQmr 0 0 0 0 RAX)
  ;; JMP: relative call
  (JMPQrel32 0)
  ;; MOVQmr: RIP-relative load
  (MOVQmr 0 0 0 0 RBX)
  )

(run-tests)
