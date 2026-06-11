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
    (ADDi W0 W1 42)
    (ADDi X2 X3 42)
    (SUBi W4 W5 100)
    (SUBi X6 X7 255)
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
    (ADDr W10 W11 W12)
    (ADDr X13 X14 X15)
    (SUBr W16 W17 W18)
    (SUBr X19 X20 X21)
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
    (MOVZ  W10 0x1234 LSL0)
    (MOVZ  X11 0x5678 LSL0)
    (MOVZ  X12 0xABCD LSL16)
    (MOVN  W13 0x1234 LSL0)
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
    (ANDr W0 W1 W2)
    (ANDr X3 X4 X5)
    (ORRr W6 W7 W8)
    (ORRr X9 X10 X11)
    (EORr W12 W13 W14)
    (EORr X15 X16 X17)
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
    (LDR   X0 X1 1)    ; offset 8 (imm12=1, scaled by 8)
    (STR   X2 X3 2)    ; offset 16
    (LDR   W4 X5 3)    ; offset 12 (imm12=3, scaled by 4)
    (STR   W6 X7 4)    ; offset 16
    (LDRB  W15 X16 8)
    (LDRH  W17 X18 8)
    (STRB  W19 X20 24)
    (STRH  W21 X22 16)
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
    (STP  X8 X9 X10 6)  ; offset 48 (imm7=6, scaled by 8)
    (LDP  X11 X12 X13 8) ; offset 64
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

;; ============================================================================
;; ADDS/SUBS immediate
;; ============================================================================

(define-test adds-subs-immediate ()
  (with-assembling ((code))
    (ADDSi W0 W1 42)
    (ADDSi X2 X3 42)
    (SUBSi W4 W5 100)
    (SUBSi X6 X7 255)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-adds-subs-imm.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    adds w0, w1, #42\n"
       "    adds x2, x3, #42\n"
       "    subs w4, w5, #100\n"
       "    subs x6, x7, #255\n"
       ))))

;; ============================================================================
;; ADDS/SUBS register
;; ============================================================================

(define-test adds-subs-register ()
  (with-assembling ((code))
    (ADDSr W10 W11 W12)
    (ADDSr X13 X14 X15)
    (SUBSr W16 W17 W18)
    (SUBSr X19 X20 X21)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-adds-subs-reg.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    adds w10, w11, w12\n"
       "    adds x13, x14, x15\n"
       "    subs w16, w17, w18\n"
       "    subs x19, x20, x21\n"
       ))))

;; ============================================================================
;; CMP immediate and register
;; ============================================================================

(define-test cmp ()
  (with-assembling ((code))
    (CMPi W10 42)
    (CMPi X11 100)
    (CMPr W12 W13)
    (CMPr X14 X15)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-cmp.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    cmp w10, #42\n"
       "    cmp x11, #100\n"
       "    cmp w12, w13\n"
       "    cmp x14, x15\n"
       ))))

;; ============================================================================
;; NEG
;; ============================================================================

(define-test neg ()
  (with-assembling ((code))
    (NEG X0 X1)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-neg.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    neg x0, x1\n"
       ))))

;; ============================================================================
;; ORN, MOVr, MVN
;; ============================================================================

(define-test orn ()
  (with-assembling ((code))
    (ORNr X0 X1 X2)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-orn.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    orn x0, x1, x2\n"
       ))))

(define-test mov-reg ()
  (with-assembling ((code))
    (MOVr X3 X4)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-mov-reg.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    mov x3, x4\n"
       ))))

(define-test mvn ()
  (with-assembling ((code))
    (MVN X5 X6)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-mvn.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    mvn x5, x6\n"
       ))))

;; ============================================================================
;; MUL, UDIV
;; ============================================================================

(define-test mul ()
  (with-assembling ((code))
    (MUL X0 X1 X2)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-mul.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    mul x0, x1, x2\n"
       ))))

(define-test udiv ()
  (with-assembling ((code))
    (UDIV X3 X4 X5)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-udiv.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    udiv x3, x4, x5\n"
       ))))

;; ============================================================================
;; Variable shift: LSLV, LSRV, ASRV
;; ============================================================================

(define-test var-shift ()
  (with-assembling ((code))
    (LSLV X0 X1 X2)
    (LSRV X3 X4 X5)
    (ASRV X6 X7 X8)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-var-shift.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    lslv x0, x1, x2\n"
       "    lsrv x3, x4, x5\n"
       "    asrv x6, x7, x8\n"
       ))))

;; ============================================================================
;; CSET: conditional set
;; ============================================================================

(define-test cset ()
  (with-assembling ((code))
    (CSET X0 0)    ; CSET X0, EQ
    (CSET X1 1)    ; CSET X1, NE
    (CSET X2 13)   ; CSET X2, LE
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-cset.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    cset x0, eq\n"
       "    cset x1, ne\n"
       "    cset x2, le\n"
       ))))

;; ============================================================================
;; SXTW: sign-extend word
;; ============================================================================

(define-test sxtw ()
  (with-assembling ((code))
    (SXTW X0 X1)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-sxtw.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    sxtw x0, w1\n"
       ))))

;; ============================================================================
;; ADR: PC-relative address
;; ============================================================================

(define-test adr ()
  (with-assembling ((code))
    (ADR X0 0x1000)
    (ADR X1 -0x1000)
    (ADR X2 0x4)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-adr.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    adr x0, #0x1000\n"
       "    adr x1, #-0x1000\n"
       "    adr x2, #4\n"
       ))))

;; ============================================================================
;; B/BL: PC-relative branch (immediate literal)
;; ============================================================================

(define-test b-bl ()
  (with-assembling ((code))
    (B   0x100)
    (BL  -0x100)
    (B   0x4)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-b-bl.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    b #0x100\n"
       "    bl #-0x100\n"
       "    b #4\n"
       ))))

;; ============================================================================
;; BCOND / B.cond convenience wrappers
;; ============================================================================

(define-test bcond ()
  (with-assembling ((code))
    (BCOND 0x100 0)    ; B.EQ +0x100
    (BCOND 0x100 1)    ; B.NE +0x100
    (BCOND 0x100 10)   ; B.GE +0x100
    (BCOND 0x100 11)   ; B.LT +0x100
    (BCOND 0x100 12)   ; B.GT +0x100
    (BCOND 0x100 13)   ; B.LE +0x100
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-bcond.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    b.eq #0x100\n"
       "    b.ne #0x100\n"
       "    b.ge #0x100\n"
       "    b.lt #0x100\n"
       "    b.gt #0x100\n"
       "    b.le #0x100\n"
       ))))

(define-test bcond-wrappers ()
  (with-assembling ((code))
    (BEQ  0x100)
    (BNE  0x100)
    (BGE  0x100)
    (BLT  0x100)
    (BGT  0x100)
    (BLE  0x100)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-bcond-wrap.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    b.eq #0x100\n"
       "    b.ne #0x100\n"
       "    b.ge #0x100\n"
       "    b.lt #0x100\n"
       "    b.gt #0x100\n"
       "    b.le #0x100\n"
       ))))

;; ============================================================================
;; Label-based B/BL/BCOND/ADR (forward and backward references)
;; ============================================================================

(define-test branch-forward ()
  (with-assembling ((code))
    (B 'skip)
    (NOP)
    (label! 'skip)
    (NOP)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-branch-forward.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    b skip\n"
       "    nop\n"
       "skip:\n"
       "    nop\n"
       ))))

(define-test branch-backward ()
  (with-assembling ((code))
    (label! 'loop)
    (NOP)
    (B 'loop)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-branch-backward.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "loop:\n"
       "    nop\n"
       "    b loop\n"
       ))))

(define-test branch-link-forward ()
  (with-assembling ((code))
    (BL 'func)
    (NOP)
    (label! 'func)
    (RET)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-branch-link-forward.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    bl func\n"
       "    nop\n"
       "func:\n"
       "    ret\n"
       ))))

(define-test bcond-forward ()
  (with-assembling ((code))
    (BCOND 'taken 0)   ; B.EQ forward
    (NOP)
    (NOP)
    (NOP)
    (label! 'taken)
    (NOP)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-bcond-forward.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    b.eq taken\n"
       "    nop\n"
       "    nop\n"
       "    nop\n"
       "taken:\n"
       "    nop\n"
       ))))

(define-test bcond-backward ()
  (with-assembling ((code))
    (label! 'loop)
    (NOP)
    (BEQ 'loop)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-bcond-backward.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "loop:\n"
       "    nop\n"
       "    beq loop\n"
       ))))

(define-test adr-data-label ()
  (with-assembling ((code))
    (ADR X0 'msg)
    (B 'skip)
    (label! 'msg)
    (.i64 0xDEADBEEF)
    (label! 'skip)
    (NOP)
    (verify-encoding-aarch64 (concat-string +build-dir+ "/asm-aarch64-adr-data-label.bin")
      (concat-strings
       ".text\n"
       ".globl _start\n"
       "_start:\n"
       "    adr x0, msg\n"
       "    b skip\n"
       "msg:\n"
       "    .xword 0xDEADBEEF\n"
       "skip:\n"
       "    nop\n"
       ))))

(run-tests)
