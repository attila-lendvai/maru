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
    (verify-encoding/arm
     "asm-aarch64-add-sub-imm.bin"
     ".text
.globl _start
_start:
    add w0, w1, #42
    add x2, x3, #42
    sub w4, w5, #100
    sub x6, x7, #255
")))

;; ============================================================================
;; ADD/SUB register
;; ============================================================================

(define-test add-sub-register ()
  (with-assembling ((code))
    (ADDr W10 W11 W12)
    (ADDr X13 X14 X15)
    (SUBr W16 W17 W18)
    (SUBr X19 X20 X21)
    (verify-encoding/arm
     "asm-aarch64-add-sub-reg.bin"
     ".text
.globl _start
_start:
     add w10, w11, w12
     add x13, x14, x15
     sub w16, w17, w18
     sub x19, x20, x21
")))

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
    (verify-encoding/arm
     "asm-aarch64-mov-imm.bin"
     ".text
.globl _start
_start:
     movz w10, #0x1234
     movz x11, #0x5678
     movz x12, #0xABCD, lsl #16
     movn w13, #0x1234
     movn x14, #0x5678
     movk x15, #0x9ABC, lsl #48
")))

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
    (verify-encoding/arm
     "asm-aarch64-logical-reg.bin"
     ".text
.globl _start
_start:
     and w0, w1, w2
     and x3, x4, x5
     orr w6, w7, w8
     orr x9, x10, x11
     eor w12, w13, w14
     eor x15, x16, x17
")))

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
    (verify-encoding/arm
     "asm-aarch64-ldst-uns.bin"
     ".text
.globl _start
_start:
     ldr x0, [x1, #8]
     str x2, [x3, #16]
     ldr w4, [x5, #12]
     str w6, [x7, #16]
     ldrb w15, [x16, #8]
     ldrh w17, [x18, #16]
     strb w19, [x20, #24]
     strh w21, [x22, #32]
")))

;; ============================================================================
;; LDRSW (sign-extending word load)
;; ============================================================================

(define-test load-signed-word ()
  (with-assembling ((code))
    (LDRSW X23 X24 10)   ; offset 40 (imm12=5, scaled by 8)
    (verify-encoding/arm
     "asm-aarch64-ldrsw.bin"
     ".text
.globl _start
_start:
     ldrsw x23, [x24, #40]
")))

;; ============================================================================
;; STP/LDP (store/load pair)
;; ============================================================================

(define-test stp-ldp ()
  (with-assembling ((code))
    (STP  X8 X9 X10 6)  ; offset 48 (imm7=6, scaled by 8)
    (LDP  X11 X12 X13 8) ; offset 64
    (verify-encoding/arm
     "asm-aarch64-stp-ldp.bin"
     ".text
.globl _start
_start:
     stp x8, x9, [x10, #48]
     ldp x11, x12, [x13, #64]
")))

;; ============================================================================
;; BR/BLR (branch to register)
;; ============================================================================

(define-test br-blr ()
  (with-assembling ((code))
    (BR  X14)
    (BLR X15)
    (verify-encoding/arm
     "asm-aarch64-br-blr.bin"
     ".text
.globl _start
_start:
     br x14
     blr x15
")))

;; ============================================================================
;; SVC (supervisor call)
;; ============================================================================

(define-test svc ()
  (with-assembling ((code))
    (SVC 0)
    (SVC 0x1234)
    (verify-encoding/arm
     "asm-aarch64-svc.bin"
     ".text
.globl _start
_start:
     svc #0
     svc #0x1234
")))

;; ============================================================================
;; No-operand instructions
;; ============================================================================

(define-test no-operand ()
  (with-assembling ((code))
    (NOP)
    (RET)
    (verify-encoding/arm
     "asm-aarch64-no-op.bin"
     ".text
.globl _start
_start:
     nop
     ret
")))

;; ============================================================================
;; ADDS/SUBS immediate
;; ============================================================================

(define-test adds-subs-immediate ()
  (with-assembling ((code))
    (ADDSi W0 W1 42)
    (ADDSi X2 X3 42)
    (SUBSi W4 W5 100)
    (SUBSi X6 X7 255)
    (verify-encoding/arm
     "asm-aarch64-adds-subs-imm.bin"
     ".text
.globl _start
_start:
     adds w0, w1, #42
     adds x2, x3, #42
     subs w4, w5, #100
     subs x6, x7, #255
")))

;; ============================================================================
;; ADDS/SUBS register
;; ============================================================================

(define-test adds-subs-register ()
  (with-assembling ((code))
    (ADDSr W10 W11 W12)
    (ADDSr X13 X14 X15)
    (SUBSr W16 W17 W18)
    (SUBSr X19 X20 X21)
    (verify-encoding/arm
     "asm-aarch64-adds-subs-reg.bin"
     ".text
.globl _start
_start:
     adds w10, w11, w12
     adds x13, x14, x15
     subs w16, w17, w18
     subs x19, x20, x21
")))

;; ============================================================================
;; CMP immediate and register
;; ============================================================================

(define-test cmp ()
  (with-assembling ((code))
    (CMPi W10 42)
    (CMPi X11 100)
    (CMPr W12 W13)
    (CMPr X14 X15)
    (verify-encoding/arm
     "asm-aarch64-cmp.bin"
     ".text
.globl _start
_start:
     cmp w10, #42
     cmp x11, #100
     cmp w12, w13
     cmp x14, x15
")))

;; ============================================================================
;; NEG
;; ============================================================================

(define-test neg ()
  (with-assembling ((code))
    (NEG X0 X1)
    (verify-encoding/arm
     "asm-aarch64-neg.bin"
     ".text
.globl _start
_start:
     neg x0, x1
")))

;; ============================================================================
;; ORN, MOVr, MVN
;; ============================================================================

(define-test orn ()
  (with-assembling ((code))
    (ORNr X0 X1 X2)
    (verify-encoding/arm
     "asm-aarch64-orn.bin"
     ".text
.globl _start
_start:
     orn x0, x1, x2
")))

(define-test mov-reg ()
  (with-assembling ((code))
    (MOVr X3 X4)
    (verify-encoding/arm
     "asm-aarch64-mov-reg.bin"
     ".text
.globl _start
_start:
     mov x3, x4
")))

(define-test mvn ()
  (with-assembling ((code))
    (MVN X5 X6)
    (verify-encoding/arm
     "asm-aarch64-mvn.bin"
     ".text
.globl _start
_start:
     mvn x5, x6
")))

;; ============================================================================
;; MUL, UDIV
;; ============================================================================

(define-test mul ()
  (with-assembling ((code))
    (MUL X0 X1 X2)
    (verify-encoding/arm
     "asm-aarch64-mul.bin"
     ".text
.globl _start
_start:
     mul x0, x1, x2
")))

(define-test udiv ()
  (with-assembling ((code))
    (UDIV X3 X4 X5)
    (verify-encoding/arm
     "asm-aarch64-udiv.bin"
     ".text
.globl _start
_start:
     udiv x3, x4, x5
")))

;; ============================================================================
;; Variable shift: LSLV, LSRV, ASRV
;; ============================================================================

(define-test var-shift ()
  (with-assembling ((code))
    (LSLV X0 X1 X2)
    (LSRV X3 X4 X5)
    (ASRV X6 X7 X8)
    (verify-encoding/arm
     "asm-aarch64-var-shift.bin"
     ".text
.globl _start
_start:
     lslv x0, x1, x2
     lsrv x3, x4, x5
     asrv x6, x7, x8
")))

;; ============================================================================
;; CSET: conditional set
;; ============================================================================

(define-test cset ()
  (with-assembling ((code))
    (CSET X0 0)    ; CSET X0, EQ
    (CSET X1 1)    ; CSET X1, NE
    (CSET X2 13)   ; CSET X2, LE
    (verify-encoding/arm
     "asm-aarch64-cset.bin"
     ".text
.globl _start
_start:
     cset x0, eq
     cset x1, ne
     cset x2, le
")))

;; ============================================================================
;; SXTW: sign-extend word
;; ============================================================================

(define-test sxtw ()
  (with-assembling ((code))
    (SXTW X0 W1)
    (verify-encoding/arm
     "asm-aarch64-sxtw.bin"
     ".text
.globl _start
_start:
     sxtw x0, w1
")))

;; ============================================================================
;; ADR: PC-relative address
;; ============================================================================

(define-test adr ()
  (with-assembling ((code))
    (ADR X0 0x1000)
    (ADR X1 -0x1000)
    (ADR X2 0x4)
    (verify-encoding/arm
     "asm-aarch64-adr.bin"
     ".text
.globl _start
_start:
     adr x0, #0x1000
     adr x1, #-0x1000
     adr x2, #4
")))

;; ============================================================================
;; B/BL: PC-relative branch (immediate literal)
;; ============================================================================

(define-test b-bl ()
  (with-assembling ((code))
    (B   0x100)
    (BL  -0x100)
    (B   0x4)
    (verify-encoding/arm
     "asm-aarch64-b-bl.bin"
     ".text
.globl _start
_start:
     b #0x100
     bl #-0x100
     b #4
")))

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
    (verify-encoding/arm
     "asm-aarch64-bcond.bin"
     ".text
.globl _start
_start:
     b.eq #0x100
     b.ne #0x100
     b.ge #0x100
     b.lt #0x100
     b.gt #0x100
     b.le #0x100
")))

(define-test bcond-wrappers ()
  (with-assembling ((code))
    (BEQ  0x100)
    (BNE  0x100)
    (BGE  0x100)
    (BLT  0x100)
    (BGT  0x100)
    (BLE  0x100)
    (verify-encoding/arm
     "asm-aarch64-bcond-wrap.bin"
     ".text
.globl _start
_start:
     b.eq #0x100
     b.ne #0x100
     b.ge #0x100
     b.lt #0x100
     b.gt #0x100
     b.le #0x100
")))

;; ============================================================================
;; Label-based B/BL/BCOND/ADR (forward and backward references)
;; ============================================================================

(define-test branch-forward ()
  (with-assembling ((code))
    (B 'skip)
    (NOP)
    (label! 'skip)
    (NOP)
    (verify-encoding/arm
     "asm-aarch64-branch-forward.bin"
     ".text
.globl _start
_start:
     b skip
     nop
 skip:
     nop
")))

(define-test branch-backward ()
  (with-assembling ((code))
    (label! 'loop)
    (NOP)
    (B 'loop)
    (verify-encoding/arm
     "asm-aarch64-branch-backward.bin"
     ".text
.globl _start
_start:
 loop:
     nop
     b loop
")))

(define-test branch-link-forward ()
  (with-assembling ((code))
    (BL 'func)
    (NOP)
    (label! 'func)
    (RET)
    (verify-encoding/arm
     "asm-aarch64-branch-link-forward.bin"
     ".text
.globl _start
_start:
     bl func
     nop
 func:
     ret
")))

(define-test bcond-forward ()
  (with-assembling ((code))
    (BCOND 'taken 0)   ; B.EQ forward
    (NOP)
    (NOP)
    (NOP)
    (label! 'taken)
    (NOP)
    (verify-encoding/arm
     "asm-aarch64-bcond-forward.bin"
     ".text
.globl _start
_start:
     b.eq taken
     nop
     nop
     nop
 taken:
     nop
")))

(define-test bcond-backward ()
  (with-assembling ((code))
    (label! 'loop)
    (NOP)
    (BEQ 'loop)
    (verify-encoding/arm
     "asm-aarch64-bcond-backward.bin"
     ".text
.globl _start
_start:
 loop:
     nop
     beq loop
")))

(define-test adr-data-label ()
  (with-assembling ((code))
    (ADR X0 'msg)
    (B 'skip)
    (label! 'msg)
    (.i64 0xDEADBEEF)
    (label! 'skip)
    (NOP)
    (verify-encoding/arm
     "asm-aarch64-adr-data-label.bin"
     ".text
.globl _start
_start:
    adr x0, msg
    b skip
msg:
    .xword 0xDEADBEEF
skip:
    nop
")))

(run-tests)
