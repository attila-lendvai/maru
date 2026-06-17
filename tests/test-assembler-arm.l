;;; -*- mode: lisp; coding: us-ascii -*-

;;; Tests for the aarch64 assembler instruction emitters.
;;; Each test emits machine code, then compares it against a reference
;;; binary produced by clang -target aarch64 assembling equivalent assembly source.

(require "source/assembler/single-pass-arm.l")
(require "tests/assembler-infra.l")

(define-form define-asm-test (name asm . instructions)
  `(define-test ,name ()
     (with-assembling ((code))
       ,@instructions

       (verify-encoding/arm
        ,(symbol->string name)
        ,(concat-string ".text
.globl _start
_start:
" asm)))))

;; ============================================================================
;; ADD/SUB immediate and register
;; ============================================================================

(define-asm-test add-sub
  "add w0, w1, #42
   add x2, x3, #42
   sub w4, w5, #100
   sub x6, x7, #255
   add w10, w11, w12
   add x13, x14, x15
   sub w16, w17, w18
   sub x19, x20, x21
"
  (ADDi W0 W1 42)
  (ADDi X2 X3 42)
  (SUBi W4 W5 100)
  (SUBi X6 X7 255)
  (ADDr W10 W11 W12)
  (ADDr X13 X14 X15)
  (SUBr W16 W17 W18)
  (SUBr X19 X20 X21)
  )

;; ============================================================================
;; MOV immediate (MOVZ, MOVN, MOVK)
;; ============================================================================

(define-asm-test mov-immediate
  "movz w10, #0x1234
   movz x11, #0x5678
   movz x12, #0xABCD, lsl #16
   movn w13, #0x1234
   movn x14, #0x5678
   movk x15, #0x9ABC, lsl #48
"
  (MOVZ  W10 0x1234 LSL0)
  (MOVZ  X11 0x5678 LSL0)
  (MOVZ  X12 0xABCD LSL16)
  (MOVN  W13 0x1234 LSL0)
  (MOVN  X14 0x5678 LSL0)
  (MOVK  X15 0x9ABC LSL48)
  )

;; ============================================================================
;; Logical register (AND, ORR, EOR)
;; ============================================================================

(define-asm-test logical-register
  "and w0, w1, w2
   and x3, x4, x5
   orr w6, w7, w8
   orr x9, x10, x11
   eor w12, w13, w14
   eor x15, x16, x17
"
  (ANDr W0 W1 W2)
  (ANDr X3 X4 X5)
  (ORRr W6 W7 W8)
  (ORRr X9 X10 X11)
  (EORr W12 W13 W14)
  (EORr X15 X16 X17)
  )

;; ============================================================================
;; Load/Store unsigned offset
;; ============================================================================

(define-asm-test load-store-unsigned
  "ldr x0, [x1, #8]
   str x2, [x3, #16]
   ldr w4, [x5, #12]
   str w6, [x7, #16]
   ldrb w15, [x16, #8]
   ldrh w17, [x18, #16]
   strb w19, [x20, #24]
   strh w21, [x22, #32]
"
  (LDR   X0 X1 1)                 ; offset 8 (imm12=1, scaled by 8)
  (STR   X2 X3 2)                 ; offset 16
  (LDR   W4 X5 3)                 ; offset 12 (imm12=3, scaled by 4)
  (STR   W6 X7 4)                 ; offset 16
  (LDRB  W15 X16 8)
  (LDRH  W17 X18 8)
  (STRB  W19 X20 24)
  (STRH  W21 X22 16)
  )

;; ============================================================================
;; LDRSW, STP/LDP
;; ============================================================================

(define-asm-test load-store-more
  "ldrsw x23, [x24, #40]
   stp x8, x9, [x10, #48]
   ldp x11, x12, [x13, #64]
"
  (LDRSW X23 X24 10)              ; offset 40 (imm12=5, scaled by 8)
  (STP  X8 X9 X10 6)               ; offset 48 (imm7=6, scaled by 8)
  (LDP  X11 X12 X13 8)             ; offset 64
  )

;; ============================================================================
;; BR/BLR, SVC, NOP, RET
;; ============================================================================

(define-asm-test misc-instructions
  "br x14
   blr x15
   svc #0
   svc #0x1234
   nop
   ret
"
  (BR  X14)
  (BLR X15)
  (SVC 0)
  (SVC 0x1234)
  (NOP)
  (RET)
  )

;; ============================================================================
;; ADDS/SUBS immediate/register, CMP
;; ============================================================================

(define-asm-test adds-subs-cmp
  "adds w0, w1, #42
   adds x2, x3, #42
   subs w4, w5, #100
   subs x6, x7, #255
   adds w10, w11, w12
   adds x13, x14, x15
   subs w16, w17, w18
   subs x19, x20, x21
   cmp w10, #42
   cmp x11, #100
   cmp w12, w13
   cmp x14, x15
"
  (ADDSi W0 W1 42)
  (ADDSi X2 X3 42)
  (SUBSi W4 W5 100)
  (SUBSi X6 X7 255)
  (ADDSr W10 W11 W12)
  (ADDSr X13 X14 X15)
  (SUBSr W16 W17 W18)
  (SUBSr X19 X20 X21)
  (CMPi W10 42)
  (CMPi X11 100)
  (CMPr W12 W13)
  (CMPr X14 X15)
  )

;; ============================================================================
;; Misc ALU: NEG, ORN, MOVr, MVN, SXTW
;; ============================================================================

(define-asm-test misc-alu
  "neg x0, x1
   orn x0, x1, x2
   mov x3, x4
   mvn x5, x6
   sxtw x0, w1
"
  (NEG X0 X1)
  (ORNr X0 X1 X2)
  (MOVr X3 X4)
  (MVN X5 X6)
  (SXTW X0 W1)
  )

;; ============================================================================
;; MUL, UDIV
;; ============================================================================

(define-asm-test mul-udiv
  "mul x0, x1, x2
   udiv x3, x4, x5
"
  (MUL X0 X1 X2)
  (UDIV X3 X4 X5)
  )

;; ============================================================================
;; Variable shift: LSLV, LSRV, ASRV
;; ============================================================================

(define-asm-test var-shift
  "lslv x0, x1, x2
   lsrv x3, x4, x5
   asrv x6, x7, x8
"
  (LSLV X0 X1 X2)
  (LSRV X3 X4 X5)
  (ASRV X6 X7 X8)
  )

;; ============================================================================
;; CSET: conditional set
;; ============================================================================

(define-asm-test cset
  "cset x0, eq
   cset x1, ne
   cset x2, le
"
  (CSET X0 0)                         ; CSET X0, EQ
  (CSET X1 1)                         ; CSET X1, NE
  (CSET X2 13)                        ; CSET X2, LE
  )

;; ============================================================================
;; ADR: PC-relative address
;; ============================================================================

(define-asm-test adr
  "adr x0, #0x1000
   adr x1, #-0x1000
   adr x2, #4
"
  (ADR X0 0x1000)
  (ADR X1 -0x1000)
  (ADR X2 0x4)
  )

;; ============================================================================
;; B/BL: PC-relative branch (immediate literal)
;; ============================================================================

(define-asm-test b-bl
  "b #0x100
   bl #-0x100
   b #4
"
  (B   0x100)
  (BL  -0x100)
  (B   0x4)
  )

;; ============================================================================
;; B.cond convenience wrappers
;; ============================================================================

(define-asm-test bcond
  "b.eq #0x100
   b.ne #0x100
   b.ge #0x100
   b.lt #0x100
   b.gt #0x100
   b.le #0x100
"
  (BEQ  0x100)
  (BNE  0x100)
  (BGE  0x100)
  (BLT  0x100)
  (BGT  0x100)
  (BLE  0x100)
  )

;; ============================================================================
;; Label-based B/BL/BCOND/ADR (forward and backward references)
;; ============================================================================

(define-asm-test branch-forward-all
  "b skip
   nop
skip:
   nop
   bl func
   nop
func:
   ret
   b.eq taken
   nop
   nop
   nop
taken:
   nop
"
  (B 'skip)
  (NOP)
  (label! 'skip)
  (NOP)
  (BL 'func)
  (NOP)
  (label! 'func)
  (RET)
  (BCOND 'taken 0)                    ; B.EQ forward
  (NOP)
  (NOP)
  (NOP)
  (label! 'taken)
  (NOP)
  )

(define-asm-test branch-backward
  "loop:
     nop
     b loop
"
  (label! 'loop)
  (NOP)
  (B 'loop)
  )

(define-asm-test bcond-backward
  "loop:
   nop
   beq loop
"
  (label! 'loop)
  (NOP)
  (BEQ 'loop)
  )

(define-asm-test adr-data-label
  "adr x0, msg
   b skip
msg:
   .xword 0xDEADBEEF
skip:
   nop
"
  (ADR X0 'msg)
  (B 'skip)
  (label! 'msg)
  (.i64 0xDEADBEEF)
  (label! 'skip)
  (NOP)
  )

(run-tests)
