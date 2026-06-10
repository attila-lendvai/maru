;;; -*- mode: lisp; coding: us-ascii -*-

;;; Tests for the aarch64 assembler instruction emitters.
;;; Each test emits machine code, then compares it against a reference
;;; binary produced by clang -target aarch64 assembling equivalent assembly source.

(require "source/assembler/single-pass-arm.l")
(require "tests/assembler-infra.l")

;; ============================================================================
;; ADD/SUB immediate
;; ============================================================================

(define-test add-sub-immediate ()
  (with-assembling ((code))
    (ADDWimm X0 X1 42)
    (ADDXimm X2 X3 42)
    (SUBWimm X4 X5 100)
    (SUBXimm X6 X7 255)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-add-sub-imm.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    add w0, w1, #42\n"
       "    add x2, x3, #42\n"
       "    sub w4, w5, #100\n"
       "    sub x6, x7, #255\n"
       ))))

;; ============================================================================
;; ADD/SUB register
;; ============================================================================

(define-test add-sub-register ()
  (with-assembling ((code))
    (ADDWreg X10 X11 X12)
    (ADDXreg X13 X14 X15)
    (SUBWreg X16 X17 X18)
    (SUBXreg X19 X20 X21)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-add-sub-reg.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    add w10, w11, w12\n"
       "    add x13, x14, x15\n"
       "    sub w16, w17, w18\n"
       "    sub x19, x20, x21\n"
       ))))

;; ============================================================================
;; MOV immediate (MOVZ, MOVN, MOVK)
;; ============================================================================

(define-test mov-immediate ()
  (with-assembling ((code))
    (MOVZW X10 0x1234 LSL0)
    (MOVZ  X11 0x5678 LSL0)
    (MOVZ  X12 0xABCD LSL16)
    (MOVNW X13 0x1234 LSL0)
    (MOVN  X14 0x5678 LSL0)
    (MOVK  X15 0x9ABC LSL48)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-mov-imm.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    movz w10, #0x1234\n"
       "    movz x11, #0x5678\n"
       "    movz x12, #0xABCD, lsl #16\n"
       "    movn w13, #0x1234\n"
       "    movn x14, #0x5678\n"
       "    movk x15, #0x9ABC, lsl #48\n"
       ))))

;; ============================================================================
;; Logical register (AND, ORR, EOR)
;; ============================================================================

(define-test logical-register ()
  (with-assembling ((code))
    (ANDWreg X0 X1 X2)
    (ANDXreg X3 X4 X5)
    (ORRWreg X6 X7 X8)
    (ORRXreg X9 X10 X11)
    (EORWreg X12 X13 X14)
    (EORXreg X15 X16 X17)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-logical-reg.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    and w0, w1, w2\n"
       "    and x3, x4, x5\n"
       "    orr w6, w7, w8\n"
       "    orr x9, x10, x11\n"
       "    eor w12, w13, w14\n"
       "    eor x15, x16, x17\n"
       ))))

;; ============================================================================
;; Load/Store unsigned offset
;; ============================================================================

(define-test load-store-unsigned ()
  (with-assembling ((code))
    (LDRX  X0 X1 1)    ; offset 8 (imm12=1, scaled by 8)
    (STRX  X2 X3 2)    ; offset 16
    (LDRW  X4 X5 3)    ; offset 12 (imm12=3, scaled by 4)
    (STRW  X6 X7 4)    ; offset 16
    (LDRB  X15 X16 8)
    (LDRH  X17 X18 8)
    (STRB  X19 X20 24)
    (STRH  X21 X22 16)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-ldst-uns.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    ldr x0, [x1, #8]\n"
       "    str x2, [x3, #16]\n"
       "    ldr w4, [x5, #12]\n"
       "    str w6, [x7, #16]\n"
       "    ldrb w15, [x16, #8]\n"
       "    ldrh w17, [x18, #16]\n"
       "    strb w19, [x20, #24]\n"
       "    strh w21, [x22, #32]\n"
       ))))

;; ============================================================================
;; LDRSW (sign-extending word load)
;; ============================================================================

(define-test load-signed-word ()
  (with-assembling ((code))
    (LDRSW X23 X24 10)   ; offset 40 (imm12=5, scaled by 8)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-ldrsw.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    ldrsw x23, [x24, #40]\n"
       ))))

;; ============================================================================
;; STP/LDP (store/load pair)
;; ============================================================================

(define-test stp-ldp ()
  (with-assembling ((code))
    (STPX  X8 X9 X10 6)  ; offset 48 (imm7=6, scaled by 8)
    (LDPX  X11 X12 X13 8) ; offset 64
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-stp-ldp.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    stp x8, x9, [x10, #48]\n"
       "    ldp x11, x12, [x13, #64]\n"
       ))))

;; ============================================================================
;; BR/BLR (branch to register)
;; ============================================================================

(define-test br-blr ()
  (with-assembling ((code))
    (BR  X14)
    (BLR X15)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-br-blr.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    br x14\n"
       "    blr x15\n"
       ))))

;; ============================================================================
;; SVC (supervisor call)
;; ============================================================================

(define-test svc ()
  (with-assembling ((code))
    (SVC 0)
    (SVC 0x1234)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-svc.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    svc #0\n"
       "    svc #0x1234\n"
       ))))

;; ============================================================================
;; No-operand instructions
;; ============================================================================

(define-test no-operand ()
  (with-assembling ((code))
    (NOP)
    (RET)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-no-op.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    nop\n"
       "    ret\n"
       ))))

(run-tests)
