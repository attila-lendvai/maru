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

;; prefix0=offset, prefix1=offset+1, ..., prefixN=offset+count
(define-form define-offset-numbered-constants (prefix offset count)
  `(begin
    ,@(let ((result ()) (i 0))
        (while (<= i count)
          (push result
                `(define-constant ,(string->symbol
                                    (concat-string prefix (number->string i)))
                     ,(+ offset i)))
          (incr i))
        result)))

;; X registers (sf-bit=1): X0=32..X31=63
(define-offset-numbered-constants "X" 32 31)

;; W registers (sf-bit=0): W0=0..W31=31
(define-offset-numbered-constants "W" 0 31)

;; some aliases
(define FP X29)    ; frame pointer
(define LP X30)    ; link register
(define SP X31)    ; stack pointer
(define XZR X31)   ; always zero register in 64-bit opcodes
(define WZR W31)   ; always zero register in 32-bit opcodes

;; helpers for width encoding in register values
(define-function rindex (r) (bitwise-and r 31))
(define-function sf-bit (r) (bitwise-shift r -5))
(define-function reg-size (r) (if (= (sf-bit r) 1) 3 2))

(define-function sf-check regs
  (let ((w (sf-bit (car regs))))
    (set regs (cdr regs))
    (while regs
      (assert (= w (sf-bit (car regs)))
        "width mismatch: " (car regs))
      (set regs (cdr regs)))
    w))

(define-function assert-X-reg regs
  (while regs
    (assert (= 1 (sf-bit (car regs)))
      (car regs) " must be an X register")
    (set regs (cdr regs))))

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

(define-function %emit-move-wide (opc hw imm16 rd)
  (emit-u32 (bitwise-or (bitwise-shift (sf-bit rd) 31)
                        (bitwise-shift opc 29)
                        0x12800000
                        (bitwise-shift hw 21)
                        (bitwise-shift imm16 5)
                        (rindex rd))))

(define-instruction MOVZ (rd imm16 hw)
  (%emit-move-wide 2 hw imm16 rd))

(define-instruction MOVN (rd imm16 hw)
  (%emit-move-wide 0 hw imm16 rd))

(define-instruction MOVK (rd imm16 hw)
  (%emit-move-wide 3 hw imm16 rd))

;;;
;;; ADD/SUB immediate
;;;   sf | op | S | 1 0 0 0 1 | sh | imm12 | Rn | Rd
;;;   op=0 for ADD, op=1 for SUB; S=1 sets flags
;;;   sh=0 for LSL#0, sh=1 for LSL#12
;;;

(define-function %emit-add-sub-imm (is-sub set-flags sh imm12 rs rd)
  (emit-u32 (bitwise-or (bitwise-shift (sf-check rd rs) 31)
                        (bitwise-shift is-sub 30)
                        (bitwise-shift set-flags 29)
                        0x11000000
                        (bitwise-shift sh 22)
                        (bitwise-shift imm12 10)
                        (bitwise-shift (rindex rs) 5)
                        (rindex rd))))

(define-instruction ADDi (rd rs imm12)
  (%emit-add-sub-imm 0 0 LSL0 imm12 rs rd))

(define-instruction SUBi (rd rs imm12)
  (%emit-add-sub-imm 1 0 LSL0 imm12 rs rd))

(define-instruction ADDSi (rd rs imm12)
  (%emit-add-sub-imm 0 1 LSL0 imm12 rs rd))

(define-instruction SUBSi (rd rs imm12)
  (%emit-add-sub-imm 1 1 LSL0 imm12 rs rd))

;;;
;;; Compare immediate alias: CMP Xn/Wn, #imm = SUBS XZR, Xn/Wn, #imm
;;;
(define-instruction CMPi (rs imm12)
  (SUBSi (bitwise-or WZR (bitwise-shift (sf-bit rs) 5)) rs imm12))

;;;
;;; ADD/SUB shifted register
;;;   sf | op | S | 0 1 0 1 1 | shift | 0 | Rm | imm6 | Rn | Rd
;;;   op=0 for ADD, op=1 for SUB; S=1 sets flags
;;;   shift: 00=LSL 01=LSR 10=ASR
;;;

(define-function %emit-add-sub-reg (is-sub set-flags shift rs2 rs1 rd)
  (emit-u32 (bitwise-or (bitwise-shift (sf-check rd rs1 rs2) 31)
                        (bitwise-shift is-sub 30)
                        (bitwise-shift set-flags 29)
                        0x0B000000
                        (bitwise-shift shift 22)
                        (bitwise-shift (rindex rs2) 16)
                        (bitwise-shift (rindex rs1) 5)
                        (rindex rd))))

(define-instruction ADDr (rd rs1 rs2)
  (%emit-add-sub-reg 0 0 LSL rs2 rs1 rd))

(define-instruction SUBr (rd rs1 rs2)
  (%emit-add-sub-reg 1 0 LSL rs2 rs1 rd))

(define-instruction ADDSr (rd rs1 rs2)
  (%emit-add-sub-reg 0 1 LSL rs2 rs1 rd))

(define-instruction SUBSr (rd rs1 rs2)
  (%emit-add-sub-reg 1 1 LSL rs2 rs1 rd))

;;;
;;; Compare register alias: CMP Xn/Wn, Xm/Wm = SUBS XZR, Xn/Wn, Xm/Wm
;;; Negate alias: NEG Xd/Wd, Xm/Wm = SUB Xd/Wd, XZR, Xm/Wm
;;;
(define-instruction CMPr (rs1 rs2)
  (SUBSr (bitwise-or WZR (bitwise-shift (sf-bit rs1) 5)) rs1 rs2))

(define-instruction NEG (rd rs)
  (SUBr rd XZR rs))

;;;
;;; Logical shifted register: AND, ORR, EOR, ANDS
;;;   sf | opc | 0 1 0 1 0 | shift N | Rm | 0 0 0 0 0 0 | Rn | Rd
;;;   opc: 00=AND 01=ORR 10=EOR 11=ANDS
;;;

(define-function %emit-logical-reg (opc shift rs2 rs1 rd)
  (let ((base (bitwise-or (bitwise-shift (sf-check rd rs1 rs2) 31)
                          (bitwise-shift opc 29)
                          0x0A000000)))
    (emit-u32 (bitwise-or base
                          (bitwise-shift shift 22)
                          (bitwise-shift (rindex rs2) 16)
                          (bitwise-shift (rindex rs1) 5)
                          (rindex rd)))))

(define-instruction ANDr (rd rs1 rs2)
  (%emit-logical-reg 0 LSL rs2 rs1 rd))

(define-instruction ORRr (rd rs1 rs2)
  (%emit-logical-reg 1 LSL rs2 rs1 rd))

(define-instruction EORr (rd rs1 rs2)
  (%emit-logical-reg 2 LSL rs2 rs1 rd))

(define-instruction ANDSr (rd rs1 rs2)
  (%emit-logical-reg 3 LSL rs2 rs1 rd))

;;;
;;; ORN (inclusive OR NOT) -- shifted register
;;;   Same as ORR but with N=1 (bit 21)
;;;

(define-function %emit-orn (shift rs2 rs1 rd)
  (emit-u32 (bitwise-or (bitwise-shift (sf-check rd rs1 rs2) 31)
                        (bitwise-shift 1 29)      ; opc=01
                        0x0A000000
                        (bitwise-shift shift 22)
                        0x00200000                 ; N=1 (bit 21)
                        (bitwise-shift (rindex rs2) 16)
                        (bitwise-shift (rindex rs1) 5)
                        (rindex rd))))

(define-instruction ORNr (rd rs1 rs2)
  (%emit-orn LSL rs2 rs1 rd))

;;;
;;; Logical aliases: MOV Xd/Wd, Xm/Wm = ORR Xd/Wd, XZR, Xm/Wm
;;;                    MVN Xd/Wd, Xm/Wm = ORN Xd/Wd, XZR, Xm/Wm
;;;
(define-instruction MOVr (rd rs)
  (ORRr rd XZR rs))

(define-instruction MVN (rd rs)
  (ORNr rd XZR rs))

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
                          (bitwise-shift (rindex Rn) 5)
                          (rindex Rt)))))

(define-instruction LDR (rd raddr imm12)
  (assert-X-reg raddr)
  (%emit-ldst-unsigned (reg-size rd) 1 imm12 raddr rd))

(define-instruction STR (rs raddr imm12)
  (assert-X-reg raddr)
  (%emit-ldst-unsigned (reg-size rs) 0 imm12 raddr rs))

(define-instruction LDRB (rd raddr imm12)
  (assert (= 0 (sf-bit rd)) "rt must be a W register")
  (assert-X-reg raddr)
  (%emit-ldst-unsigned 0 1 imm12 raddr rd))

(define-instruction STRB (rs raddr imm12)
  (assert (= 0 (sf-bit rs)) "rt must be a W register")
  (assert-X-reg raddr)
  (%emit-ldst-unsigned 0 0 imm12 raddr rs))

(define-instruction LDRH (rd raddr imm12)
  (assert (= 0 (sf-bit rd)) "rt must be a W register")
  (assert-X-reg raddr)
  (%emit-ldst-unsigned 1 1 imm12 raddr rd))

(define-instruction STRH (rs raddr imm12)
  (assert (= 0 (sf-bit rs)) "rt must be a W register")
  (assert-X-reg raddr)
  (%emit-ldst-unsigned 1 0 imm12 raddr rs))

(define-instruction LDRSW (rd raddr imm12)
  (assert-X-reg rd raddr)
  (%emit-ldst-unsigned 2 2 imm12 raddr rd))

;;;
;;; Store/Load Pair: STP, LDP
;;;   opc | 1 0 1 0 0 1 | mode | L | imm7 | Rt2 | Rn | Rt
;;;   opc=10 for 64-bit, 00 for 32-bit
;;;   mode bits (24-23): 10=offset 11=pre-index 01=post-index
;;;   L=0 for STP, L=1 for LDP
;;;   imm7: signed offset / scale (scale=8 for 64-bit, 4 for 32-bit)
;;;

(define-function %emit-stp-ldp (mode is-load imm7 Rt2 Rn Rt)
  (emit-u32 (bitwise-or (bitwise-shift (sf-check Rt2 Rn Rt) 31)
                        0x28000000
                        (bitwise-shift mode 23)
                        (bitwise-shift is-load 22)
                        (bitwise-shift (bitwise-and imm7 0x7F) 15)
                        (bitwise-shift (rindex Rt2) 10)
                        (bitwise-shift (rindex Rn) 5)
                        (rindex Rt))))

(define-instruction STP (rs1 rs2 raddr imm7)
  (%emit-stp-ldp 2 0 imm7 rs2 raddr rs1))

(define-instruction LDP (rd1 rd2 raddr imm7)
  (%emit-stp-ldp 2 1 imm7 rd2 raddr rd1))

(define-instruction STPpre (rs1 rs2 raddr imm7)
  (%emit-stp-ldp 3 0 imm7 rs2 raddr rs1))

(define-instruction LDPpre (rd1 rd2 raddr imm7)
  (%emit-stp-ldp 3 1 imm7 rd2 raddr rd1))

(define-instruction STPpost (rs1 rs2 raddr imm7)
  (%emit-stp-ldp 1 0 imm7 rs2 raddr rs1))

(define-instruction LDPpost (rd1 rd2 raddr imm7)
  (%emit-stp-ldp 1 1 imm7 rd2 raddr rd1))

;;;
;;; Branch to register: BR, BLR
;;;   1 1 0 1 0 1 1 0 | op1 | 1 1 1 1 1 | 0 0 0 0 0 0 0 0 0 0 0 1 | Rn | 0 0 0 0 0
;;;

(define-function %emit-br (op1 raddr)
  (assert-X-reg raddr)
  (emit-u32 (bitwise-or 0xD6000000
                        (bitwise-shift op1 16)
                        (bitwise-shift (rindex raddr) 5))))

(define-instruction BR (raddr)
  (%emit-br 0x1F raddr))

(define-instruction BLR (raddr)
  (%emit-br 0x3F raddr))

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

(define-function %emit-mul (rs2 rs1 rd)
  (emit-u32 (bitwise-or (bitwise-shift (sf-check rd rs1 rs2) 31)
                        0x1B007C00
                        (bitwise-shift (rindex rs2) 16)
                        (bitwise-shift (rindex rs1) 5)
                        (rindex rd))))

(define-instruction MUL (rd rs1 rs2)
  (%emit-mul rs2 rs1 rd))

;;;
;;; Unsigned divide: UDIV Xd, Xn, Xm
;;;   2-source DP: opcode2 = 000010
;;;

(define-function %emit-2source (opcode2 rs2 rs1 rd)
  (emit-u32 (bitwise-or (bitwise-shift (sf-check rd rs1 rs2) 31)
                        0x9AC00000
                        (bitwise-shift opcode2 10)
                        (bitwise-shift (rindex rs2) 16)
                        (bitwise-shift (rindex rs1) 5)
                        (rindex rd))))

(define-instruction UDIV (rd rs1 rs2)
  (%emit-2source 2 rs2 rs1 rd))

;;;
;;; Variable shift: LSLV, LSRV, ASRV
;;;   2-source DP: opcode2 = 001000 (LSLV), 001001 (LSRV), 001010 (ASRV)
;;;

(define-instruction LSLV (rd rs1 rs2)
  (%emit-2source 8 rs2 rs1 rd))

(define-instruction LSRV (rd rs1 rs2)
  (%emit-2source 9 rs2 rs1 rd))

(define-instruction ASRV (rd rs1 rs2)
  (%emit-2source 10 rs2 rs1 rd))

;;;
;;; Conditional set: CSET Xd, cond
;;;   = CSINC Xd, XZR, XZR, inv(cond)
;;;   cond: 0=EQ 1=NE 10=GE 11=LT 12=GT 13=LE
;;;

(define-instruction CSET (rd cond)
  (assert-X-reg rd)
  (emit-u32 (bitwise-or 0x9A9F07E0
                        (bitwise-shift (bitwise-xor cond 1) 12)
                        (rindex rd))))

;;;
;;; Sign extend word: SXTW Xd, Xn
;;;   SBFM: sf=1, opc=00, N=1, immr=0, imms=0
;;;

(define-instruction SXTW (rd rs)
  (assert-X-reg rd rs)
  (emit-u32 (bitwise-or 0x93407C00
                        (bitwise-shift (rindex rs) 5)
                        (rindex rd))))

;;;
;;; PC-relative address: ADR Xd, label
;;;   0 | 1 0 0 0 0 | immhi | immlo | Rd
;;;   offset is a 21-bit signed byte offset (not divided by 4)
;;;   enc: immlo = offset[1:0], immhi = offset[20:2]
;;;

(define-function %emit-adr (rd offset)
  (assert-X-reg rd)
  (let ((immlo (bitwise-and offset 3))
        (immhi (bitwise-shift offset -2)))
    (emit-u32 (bitwise-or 0x10000000
                          (bitwise-shift immlo 29)
                          (bitwise-shift (bitwise-and immhi 0x7FFFF) 5)
                          (rindex rd)))))

(define-instruction ADR (rd designator)
  (typecase designator
    (<long>   (%emit-adr rd designator))
    (<label>  (emit-label designator
                          (lambda (v) (%emit-adr rd v))
                          4 (- 0 (current-laddress))))
    (<symbol> (ADR rd (%ensure-label designator)))
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
