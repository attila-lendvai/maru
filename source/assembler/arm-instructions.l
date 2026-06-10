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
;;;   sf | op | S | 1 0 0 0 1 | sh | imm12 | Rn | Rd
;;;   op=0 for ADD, op=1 for SUB; S=1 sets flags
;;;   sh=0 for LSL#0, sh=1 for LSL#12
;;;

(define-function %emit-add-sub-imm (sf is-sub set-flags sh imm12 Rn Rd)
  (emit-u32 (bitwise-or (bitwise-shift sf 31)
                        (bitwise-shift is-sub 30)
                        (bitwise-shift set-flags 29)
                        0x11000000
                        (bitwise-shift sh 22)
                        (bitwise-shift imm12 10)
                        (bitwise-shift Rn 5)
                        Rd)))

(define-instruction ADDXimm (Rd Rn imm12)
  (%emit-add-sub-imm 1 0 0 LSL0 imm12 Rn Rd))

(define-instruction ADDWimm (Rd Rn imm12)
  (%emit-add-sub-imm 0 0 0 LSL0 imm12 Rn Rd))

(define-instruction SUBXimm (Rd Rn imm12)
  (%emit-add-sub-imm 1 1 0 LSL0 imm12 Rn Rd))

(define-instruction SUBWimm (Rd Rn imm12)
  (%emit-add-sub-imm 0 1 0 LSL0 imm12 Rn Rd))

(define-instruction ADDSXimm (Rd Rn imm12)
  (%emit-add-sub-imm 1 0 1 LSL0 imm12 Rn Rd))

(define-instruction ADDSWimm (Rd Rn imm12)
  (%emit-add-sub-imm 0 0 1 LSL0 imm12 Rn Rd))

(define-instruction SUBSXimm (Rd Rn imm12)
  (%emit-add-sub-imm 1 1 1 LSL0 imm12 Rn Rd))

(define-instruction SUBSWimm (Rd Rn imm12)
  (%emit-add-sub-imm 0 1 1 LSL0 imm12 Rn Rd))

;;;
;;; Compare immediate aliases: CMP Xn, #imm = SUBS XZR, Xn, #imm
;;;
(define-instruction CMPXimm (Rn imm12)
  (SUBSXimm XZR Rn imm12))

(define-instruction CMPWimm (Rn imm12)
  (SUBSWimm XZR Rn imm12))

;;;
;;; ADD/SUB shifted register
;;;   sf | op | S | 0 1 0 1 1 | shift | 0 | Rm | imm6 | Rn | Rd
;;;   op=0 for ADD, op=1 for SUB; S=1 sets flags
;;;   shift: 00=LSL 01=LSR 10=ASR
;;;

(define-function %emit-add-sub-reg (sf is-sub set-flags shift Rm Rn Rd)
  (emit-u32 (bitwise-or (bitwise-shift sf 31)
                        (bitwise-shift is-sub 30)
                        (bitwise-shift set-flags 29)
                        0x0B000000
                        (bitwise-shift shift 22)
                        (bitwise-shift Rm 16)
                        (bitwise-shift Rn 5)
                        Rd)))

(define-instruction ADDXreg (Rd Rn Rm)
  (%emit-add-sub-reg 1 0 0 LSL Rm Rn Rd))

(define-instruction ADDWreg (Rd Rn Rm)
  (%emit-add-sub-reg 0 0 0 LSL Rm Rn Rd))

(define-instruction SUBXreg (Rd Rn Rm)
  (%emit-add-sub-reg 1 1 0 LSL Rm Rn Rd))

(define-instruction SUBWreg (Rd Rn Rm)
  (%emit-add-sub-reg 0 1 0 LSL Rm Rn Rd))

(define-instruction ADDSXreg (Rd Rn Rm)
  (%emit-add-sub-reg 1 0 1 LSL Rm Rn Rd))

(define-instruction ADDSWreg (Rd Rn Rm)
  (%emit-add-sub-reg 0 0 1 LSL Rm Rn Rd))

(define-instruction SUBSXreg (Rd Rn Rm)
  (%emit-add-sub-reg 1 1 1 LSL Rm Rn Rd))

(define-instruction SUBSWreg (Rd Rn Rm)
  (%emit-add-sub-reg 0 1 1 LSL Rm Rn Rd))

;;;
;;; Compare register aliases: CMP Xn, Xm = SUBS XZR, Xn, Xm
;;; Negate alias: NEG Xd, Xm = SUB Xd, XZR, Xm
;;;
(define-instruction CMPXreg (Rn Rm)
  (SUBSXreg XZR Rn Rm))

(define-instruction CMPWreg (Rn Rm)
  (SUBSWreg XZR Rn Rm))

(define-instruction NEG (Xd Xm)
  (SUBXreg Xd XZR Xm))

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
;;; ORN (inclusive OR NOT) -- shifted register
;;;   Same as ORR but with N=1 (bit 21)
;;;

(define-function %emit-orn (sf shift Rm Rn Rd)
  (emit-u32 (bitwise-or (bitwise-shift sf 31)
                        (bitwise-shift 1 29)      ; opc=01
                        0x0A000000
                        (bitwise-shift shift 22)
                        0x00200000                 ; N=1 (bit 21)
                        (bitwise-shift Rm 16)
                        (bitwise-shift Rn 5)
                        Rd)))

(define-instruction ORNXreg (Xd Xn Xm)
  (%emit-orn 1 LSL Xm Xn Xd))

;;;
;;; Logical aliases: MOV Xd, Xm = ORR Xd, XZR, Xm
;;;                    MVN Xd, Xm = ORN Xd, XZR, Xm
;;;
(define-instruction MOVreg (Xd Xm)
  (ORRXreg Xd XZR Xm))

(define-instruction MVN (Xd Xm)
  (ORNXreg Xd XZR Xm))

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

;;;
;;; Multiply: MUL Xd, Xn, Xm
;;;   sf | 0 0 1 1 0 | 1 1 | Rm | 0 | 1 1 1 1 1 | Rn | Rd
;;;

(define-function %emit-mul (sf Rm Rn Rd)
  (emit-u32 (bitwise-or (bitwise-shift sf 31)
                        0x1B007C00
                        (bitwise-shift Rm 16)
                        (bitwise-shift Rn 5)
                        Rd)))

(define-instruction MUL (Xd Xn Xm)
  (%emit-mul 1 Xm Xn Xd))

;;;
;;; Unsigned divide: UDIV Xd, Xn, Xm
;;;   2-source DP: opcode2 = 000010
;;;

(define-function %emit-2source (sf opcode2 Rm Rn Rd)
  (emit-u32 (bitwise-or (bitwise-shift sf 31)
                        0x9AC00000
                        (bitwise-shift opcode2 10)
                        (bitwise-shift Rm 16)
                        (bitwise-shift Rn 5)
                        Rd)))

(define-instruction UDIV (Xd Xn Xm)
  (%emit-2source 1 2 Xm Xn Xd))

;;;
;;; Variable shift: LSLV, LSRV, ASRV
;;;   2-source DP: opcode2 = 001000 (LSLV), 001001 (LSRV), 001010 (ASRV)
;;;

(define-instruction LSLV (Xd Xn Xm)
  (%emit-2source 1 8 Xm Xn Xd))

(define-instruction LSRV (Xd Xn Xm)
  (%emit-2source 1 9 Xm Xn Xd))

(define-instruction ASRV (Xd Xn Xm)
  (%emit-2source 1 10 Xm Xn Xd))

;;;
;;; Conditional set: CSET Xd, cond
;;;   = CSINC Xd, XZR, XZR, inv(cond)
;;;   cond: 0=EQ 1=NE 10=GE 11=LT 12=GT 13=LE
;;;

(define-instruction CSET (Xd cond)
  (emit-u32 (bitwise-or 0x9A9F07E0
                        (bitwise-shift (bitwise-xor cond 1) 12)
                        Xd)))

;;;
;;; Sign extend word: SXTW Xd, Xn
;;;   SBFM: sf=1, opc=00, N=1, immr=0, imms=0
;;;

(define-instruction SXTW (Xd Xn)
  (emit-u32 (bitwise-or 0x93407C00
                        (bitwise-shift Xn 5)
                        Xd)))

;;;
;;; PC-relative address: ADR Xd, label
;;;   0 | 1 0 0 0 0 | immhi | immlo | Rd
;;;   offset is a 21-bit signed byte offset (not divided by 4)
;;;   enc: immlo = offset[1:0], immhi = offset[20:2]
;;;

(define-function %emit-adr (Rd offset)
  (let ((immlo (bitwise-and offset 3))
        (immhi (bitwise-shift offset -2)))
    (emit-u32 (bitwise-or 0x10000000
                          (bitwise-shift immlo 29)
                          (bitwise-shift (bitwise-and immhi 0x7FFFF) 5)
                          Rd))))

(define-instruction ADR (Xd designator)
  (typecase designator
    (<long>   (%emit-adr Xd designator))
    (<label>  (emit-label designator
                          (lambda (v) (%emit-adr Xd v))
                          4 (- 0 (current-laddress))))
    (<symbol> (ADR Xd (%ensure-label designator)))
    (else     (error "ADR: unexpected: " designator))))

;;;
;;; Branch instructions (PC-relative)
;;;   B label:  offset/4 in imm26
;;;   BL label: offset/4 in imm26
;;;

(define-function %emit-b-imm26 (opcode offset)
  (emit-u32 (bitwise-or opcode
                        (bitwise-and (bitwise-shift offset -2)
                                     0x3FFFFFF))))

(define-instruction B (designator)
  (typecase designator
    (<long>   (%emit-b-imm26 0x14000000 designator))
    (<label>  (emit-label designator
                          (lambda (v) (%emit-b-imm26 0x14000000 v))
                          4 (- 0 (current-laddress))))
    (<symbol> (B (%ensure-label designator)))
    (else     (error "B: unexpected: " designator))))

(define-instruction BL (designator)
  (typecase designator
    (<long>   (%emit-b-imm26 0x94000000 designator))
    (<label>  (emit-label designator
                          (lambda (v) (%emit-b-imm26 0x94000000 v))
                          4 (- 0 (current-laddress))))
    (<symbol> (BL (%ensure-label designator)))
    (else     (error "BL: unexpected: " designator))))

;;;
;;; Conditional branch: B.cond label
;;;   0x54000000 | imm19<<5 | cond
;;;   imm19 = offset/4
;;;

(define-function %emit-b-imm19 (cond offset)
  (emit-u32 (bitwise-or 0x54000000
                        (bitwise-shift (bitwise-and (bitwise-shift offset -2) 0x7FFFF) 5)
                        cond)))

(define-instruction BCOND (designator cond)
  (typecase designator
    (<long>   (%emit-b-imm19 cond designator))
    (<label>  (emit-label designator
                          (lambda (v) (%emit-b-imm19 cond v))
                          4 (- 0 (current-laddress))))
    (<symbol> (BCOND (%ensure-label designator) cond))
    (else     (error "BCOND: unexpected: " designator))))

;;;
;;; Conditional branch convenience wrappers
;;;   ARM condition codes: EQ=0 NE=1 GE=10 LT=11 GT=12 LE=13
;;;

(define-instruction BEQ (designator) (BCOND designator 0))
(define-instruction BNE (designator) (BCOND designator 1))
(define-instruction BGE (designator) (BCOND designator 10))
(define-instruction BLT (designator) (BCOND designator 11))
(define-instruction BGT (designator) (BCOND designator 12))
(define-instruction BLE (designator) (BCOND designator 13))
