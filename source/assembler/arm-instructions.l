;;;
;;; Run-time assembler for aarch64
;;;

(define asmfail error)

(with-forms
    ((define-numbered-constants ((prefix start count)
         (let ((index -1))
           `(begin
             ,@(let ((result ())
                     (i start))
                 (while (<= i count)
                   (push result
                         `(define-constant ,(string->symbol
                                             (concat-string prefix (number->string i)))
                              ,i))
                   (incr i))
                 result))))))

  ;; Registers X0..X31
  (define-numbered-constants "X" 0 31))

;; some aliases
(define FP X29)    ; frame pointer
(define LP X30)    ; link register
(define SP X31)    ; stack pointer
(define XZR X31)   ; always zero register in some opcodes

;; shift field constants for ADD/SUB immediate (sh bit 22)
(define-constant LSL0  0)   ; LSL#0: imm12 used as-is
(define-constant LSL12 1)   ; LSL#12: imm12 << 12

;; hw field constants for move-wide (bits 22-21)
(define-constant LSL16 1)   ; shift left by 16 bits
(define-constant LSL32 2)   ; shift left by 32 bits
(define-constant LSL48 3)   ; shift left by 48 bits

;; shift type constants for register ops (bits 23-22)
(define-constant LSL 0)     ; logical left shift
(define-constant LSR 1)     ; logical right shift
(define-constant ASR 2)     ; arithmetic right shift

(define-form define-instruction (name args . body)
  `(define-function ,name ,args ,@body))

(define-form define-instruction/no-operand (name machine-code)
  `(define-instruction ,name () (emit-u32 ,machine-code)))

(define-form define-instructions/no-operand entries
  `(begin
     ,@(map (lambda (entry)
              `(define-instruction/no-operand ,(first entry) ,(second entry)))
            entries)))

(define-instructions/no-operand
  (NOP   0xD503201F)
  (YIELD 0xD503203F)
  (WFE   0xD503205F)
  (WFI   0xD503207F)
  (SEV   0xD503209F)
  (SEVL  0xD50320BF)
  (ISB   0xD5033FDF)
  (RET   0xD65F03C0)
  (ERET  0xD69F03E0))

;;;
;;; Move wide immediate: MOVZ, MOVN, MOVK
;;;   sf | opc | 1 0 0 1 0 1 | hw | imm16 | Rd
;;;   opc: 10=MOVZ 00=MOVN 11=MOVK
;;;   hw: shift/16 (0..3)
;;;

(define-function %emit-move-wide (sf opc hw imm16 Rd)
  (emit-u32 (bitwise-or (bitwise-shift sf 31)
                        (bitwise-shift opc 29)
                        0x12800000
                        (bitwise-shift hw 21)
                        (bitwise-shift imm16 5)
                        Rd)))

(define-instruction MOVZ (Rd imm16 hw)
  (%emit-move-wide 1 2 hw imm16 Rd))

(define-instruction MOVZW (Rd imm16 hw)
  (%emit-move-wide 0 2 hw imm16 Rd))

(define-instruction MOVN (Rd imm16 hw)
  (%emit-move-wide 1 0 hw imm16 Rd))

(define-instruction MOVNW (Rd imm16 hw)
  (%emit-move-wide 0 0 hw imm16 Rd))

(define-instruction MOVK (Rd imm16 hw)
  (%emit-move-wide 1 3 hw imm16 Rd))

(define-instruction MOVKW (Rd imm16 hw)
  (%emit-move-wide 0 3 hw imm16 Rd))

;;;
;;; ADD/SUB immediate
;;;   sf | 0 0 1 0 0 0 0 1 | sh | imm12 | Rn | Rd
;;;   sh=0 for LSL#0, sh=1 for LSL#12
;;;

(define-function %emit-add-sub-imm (sf is-sub sh imm12 Rn Rd)
  (let ((base (bitwise-or (bitwise-shift sf 31)
                          (if (= is-sub 1) 0x51000000 0x11000000))))
    (emit-u32 (bitwise-or base
                          (bitwise-shift sh 22)
                          (bitwise-shift imm12 10)
                          (bitwise-shift Rn 5)
                          Rd))))

(define-instruction ADDXimm (Rd Rn imm12)
  (%emit-add-sub-imm 1 0 LSL0 imm12 Rn Rd))

(define-instruction ADDWimm (Rd Rn imm12)
  (%emit-add-sub-imm 0 0 LSL0 imm12 Rn Rd))

(define-instruction SUBXimm (Rd Rn imm12)
  (%emit-add-sub-imm 1 1 LSL0 imm12 Rn Rd))

(define-instruction SUBWimm (Rd Rn imm12)
  (%emit-add-sub-imm 0 1 LSL0 imm12 Rn Rd))

;;;
;;; ADD/SUB shifted register
;;;   sf | 0 0 1 0 1 0 1 1 | shift N | Rm | 0 0 0 0 0 0 | Rn | Rd
;;;   shift: 00=LSL 01=LSR 10=ASR
;;;

(define-function %emit-add-sub-reg (sf is-sub shift Rm Rn Rd)
  (let ((base (if (= is-sub 1) 0x4B000000 0x0B000000)))
    (emit-u32 (bitwise-or (bitwise-shift sf 31)
                          base
                          (bitwise-shift shift 22)
                          (bitwise-shift Rm 16)
                          (bitwise-shift Rn 5)
                          Rd))))

(define-instruction ADDXreg (Rd Rn Rm)
  (%emit-add-sub-reg 1 0 LSL Rm Rn Rd))

(define-instruction ADDWreg (Rd Rn Rm)
  (%emit-add-sub-reg 0 0 LSL Rm Rn Rd))

(define-instruction SUBXreg (Rd Rn Rm)
  (%emit-add-sub-reg 1 1 LSL Rm Rn Rd))

(define-instruction SUBWreg (Rd Rn Rm)
  (%emit-add-sub-reg 0 1 LSL Rm Rn Rd))

;;;
;;; Logical shifted register: AND, ORR, EOR, ANDS
;;;   sf | opc | 0 1 0 1 0 | shift N | Rm | 0 0 0 0 0 0 | Rn | Rd
;;;   opc: 00=AND 01=ORR 10=EOR 11=ANDS
;;;

(define-function %emit-logical-reg (sf opc shift Rm Rn Rd)
  (let ((base (bitwise-or (bitwise-shift sf 31)
                          (bitwise-shift opc 29)
                          0x0A000000)))
    (emit-u32 (bitwise-or base
                          (bitwise-shift shift 22)
                          (bitwise-shift Rm 16)
                          (bitwise-shift Rn 5)
                          Rd))))

(define-instruction ANDXreg (Rd Rn Rm)
  (%emit-logical-reg 1 0 LSL Rm Rn Rd))

(define-instruction ANDWreg (Rd Rn Rm)
  (%emit-logical-reg 0 0 LSL Rm Rn Rd))

(define-instruction ORRXreg (Rd Rn Rm)
  (%emit-logical-reg 1 1 LSL Rm Rn Rd))

(define-instruction ORRWreg (Rd Rn Rm)
  (%emit-logical-reg 0 1 LSL Rm Rn Rd))

(define-instruction EORXreg (Rd Rn Rm)
  (%emit-logical-reg 1 2 LSL Rm Rn Rd))

(define-instruction EORWreg (Rd Rn Rm)
  (%emit-logical-reg 0 2 LSL Rm Rn Rd))

(define-instruction ANDSXreg (Rd Rn Rm)
  (%emit-logical-reg 1 3 LSL Rm Rn Rd))

(define-instruction ANDSWreg (Rd Rn Rm)
  (%emit-logical-reg 0 3 LSL Rm Rn Rd))

;;;
;;; Load/Store unsigned offset
;;;   size | 1 1 1 0 0 1 | opc | imm12 | Rn | Rt
;;;   size=11 for X, 10 for W, 01 for H, 00 for B
;;;   opc (bits 23-22): 00=STR 01=LDR 10=LDRSW
;;;

(define-function %emit-ldst-unsigned (size opc imm12 Rn Rt)
  (let ((base (bitwise-or (bitwise-shift size 30)
                          0x39000000)))
    (emit-u32 (bitwise-or base
                          (bitwise-shift opc 22)
                          (bitwise-shift imm12 10)
                          (bitwise-shift Rn 5)
                          Rt))))

(define-instruction LDRX (Rt Rn imm12)
  (%emit-ldst-unsigned 3 1 imm12 Rn Rt))

(define-instruction STRX (Rt Rn imm12)
  (%emit-ldst-unsigned 3 0 imm12 Rn Rt))

(define-instruction LDRW (Rt Rn imm12)
  (%emit-ldst-unsigned 2 1 imm12 Rn Rt))

(define-instruction STRW (Rt Rn imm12)
  (%emit-ldst-unsigned 2 0 imm12 Rn Rt))

(define-instruction LDRB (Rt Rn imm12)
  (%emit-ldst-unsigned 0 1 imm12 Rn Rt))

(define-instruction STRB (Rt Rn imm12)
  (%emit-ldst-unsigned 0 0 imm12 Rn Rt))

(define-instruction LDRH (Rt Rn imm12)
  (%emit-ldst-unsigned 1 1 imm12 Rn Rt))

(define-instruction STRH (Rt Rn imm12)
  (%emit-ldst-unsigned 1 0 imm12 Rn Rt))

(define-instruction LDRSW (Rt Rn imm12)
  (%emit-ldst-unsigned 2 2 imm12 Rn Rt))

;;;
;;; Store/Load Pair: STP, LDP
;;;   opc | 1 0 1 0 0 1 | mode | L | imm7 | Rt2 | Rn | Rt
;;;   opc=10 for 64-bit, 00 for 32-bit
;;;   mode bits (24-23): 10=offset 11=pre-index 01=post-index
;;;   L=0 for STP, L=1 for LDP
;;;   imm7: signed offset / scale (scale=8 for 64-bit, 4 for 32-bit)
;;;

(define-function %emit-stp-ldp (opc mode is-load imm7 Rt2 Rn Rt)
  (let ((base (bitwise-or (bitwise-shift opc 30)
                          0x28000000
                          (bitwise-shift mode 23)
                          (bitwise-shift is-load 22))))
    (emit-u32 (bitwise-or base
                          (bitwise-shift (bitwise-and imm7 0x7F) 15)
                          (bitwise-shift Rt2 10)
                          (bitwise-shift Rn 5)
                          Rt))))

(define-instruction STPX (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 2 2 0 imm7 Rt2 Rn Rt1))

(define-instruction STPW (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 0 2 0 imm7 Rt2 Rn Rt1))

(define-instruction LDPX (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 2 2 1 imm7 Rt2 Rn Rt1))

(define-instruction LDPW (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 0 2 1 imm7 Rt2 Rn Rt1))

(define-instruction STPXpre (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 2 3 0 imm7 Rt2 Rn Rt1))

(define-instruction STPWpre (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 0 3 0 imm7 Rt2 Rn Rt1))

(define-instruction LDPXpre (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 2 3 1 imm7 Rt2 Rn Rt1))

(define-instruction LDPWpre (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 0 3 1 imm7 Rt2 Rn Rt1))

(define-instruction STPXpost (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 2 1 0 imm7 Rt2 Rn Rt1))

(define-instruction STPWpost (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 0 1 0 imm7 Rt2 Rn Rt1))

(define-instruction LDPXpost (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 2 1 1 imm7 Rt2 Rn Rt1))

(define-instruction LDPWpost (Rt1 Rt2 Rn imm7)
  (%emit-stp-ldp 0 1 1 imm7 Rt2 Rn Rt1))

;;;
;;; Branch to register: BR, BLR
;;;   1 1 0 1 0 1 1 0 | op1 | 1 1 1 1 1 | 0 0 0 0 0 0 0 0 0 0 0 1 | Rn | 0 0 0 0 0
;;;

(define-function %emit-br (op1 Rn)
  (emit-u32 (bitwise-or 0xD6000000
                        (bitwise-shift op1 16)
                        (bitwise-shift Rn 5))))

(define-instruction BR (Rn)
  (%emit-br 0x1F Rn))

(define-instruction BLR (Rn)
  (%emit-br 0x3F Rn))

;;;
;;; Supervisor Call: SVC
;;;   1 1 0 1 0 1 0 0 | 0 0 0 0 0 0 0 0 | imm16 | 0 0 0 0 1
;;;

(define-instruction SVC (imm16)
  (emit-u32 (bitwise-or 0xD4000000
                        (bitwise-shift imm16 5)
                        0x00000001)))
