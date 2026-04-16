;;;
;;; Run-time assembler for IA-32 and AMD64
;;;

;; Variable names:
;;  - L literal (immediate, but I is used for index)
;;  - D displacement
;;  - B base register
;;  - I index register
;;  - S scale

(define ASMFAIL error)

(with-forms
    ((x (args
         (let ((index -1))
           `(begin
             ,@(map (lambda (entry)
                      `(define-constant ,(first entry) ,(second entry)))
                    args))))))
  (x (_b00 0)
     (_b01 1)
     (_b10 2)
     (_b11 3)
     (_b000 0)
     (_b001 1)
     (_b010 2)
     (_b011 3)
     (_b100 4)
     (_b101 5)
     (_b110 6)
     (_b111 7)

     (_AL 16)
     (_CL 17)
     (_DL 18)
     (_BL 19)

     (_AH 20)
     (_CH 21)
     (_DH 22)
     (_BH 23)

     (_AX 32)
     (_CX 33)
     (_DX 34)
     (_BX 35)
     (_SP 36)
     (_BP 37)
     (_SI 38)
     (_DI 39)

     (_EAX 0x40)
     (_ECX 0x41)
     (_EDX 0x42)
     (_EBX 0x43)
     (_ESP 0x44)
     (_EBP 0x45)
     (_ESI 0x46)
     (_EDI 0x47))

  (x (_SIL  0x14)
     (_DIL  0x15)
     (_SPL  0x16)
     (_BPL  0x17)
     (_R8B  0x18)
     (_R9B  0x19)
     (_R10B 0x1a)
     (_R11B 0x1b)
     (_R12B 0x1c)
     (_R13B 0x1d)
     (_R14B 0x1e)
     (_R15B 0x1f)

     (_R8W  0x28)
     (_R9W  0x29)
     (_R10W 0x2a)
     (_R11W 0x2b)
     (_R12W 0x2c)
     (_R13W 0x2d)
     (_R14W 0x2e)
     (_R15W 0x2f)

     (_R8D  0x48)
     (_R9D  0x49)
     (_R10D 0x4a)
     (_R11D 0x4b)
     (_R12D 0x4c)
     (_R13D 0x4d)
     (_R14D 0x4e)
     (_R15D 0x4f)

     (_RAX  0x80)
     (_RCX  0x81)
     (_RDX  0x82)
     (_RBX  0x83)
     (_RSP  0x84)
     (_RBP  0x85)
     (_RSI  0x86)
     (_RDI  0x87)
     (_R8   0x88)
     (_R9   0x89)
     (_R10  0x8a)
     (_R11  0x8b)
     (_R12  0x8c)
     (_R13  0x8d)
     (_R14  0x8e)
     (_R15  0x8f)))

(define-function _rS (R)
  (bitwise-shift R -4))

(define-function _r1P (R)
  (= (_rS R) 1))

(define-function _r2P (R)
  (= (_rS R) 2))

(define-function _r4P (R)
  (= (_rS R) 4))

(define-function _rN (R)
  (bitwise-and R 7))

(define-function _r0P (R)
  (= R 0))

;; (define-function _rLP (R)
;;   (and (>= R _AL)
;;        (<= R _BL)))

;; (define-function _rHP (R)
;;   (and (>= R _AH)
;;        (<= R _BH)))

;; (define-function _rL (R)
;;   (if (_rLP R)
;;       (_rN R)
;;     (ASMFAIL "8-bit L register required")))

;; (define-function _rH (R)
;;   (if (_rHP R)
;;       (_rN R)
;;     (ASMFAIL "8-bit H register required")))

(define-function _r1 (R)
  (assert (_r1P R) "8-bit register required")
  (_rN R))

(define-function _r2 (R)
  (assert (_r2P R) "16-bit register required")
  (_rN R))

(define-function _r4 (R)
  (assert (_r4P R) "32-bit register required")
  (_rN R))

(define-function _rAL (R)
  (assert (= R _AL) "AL register required")
  (_rN R))

(define-function _rAX (R)
  (assert (= R _AX) "AX register required")
  (_rN R))

(define-function _rEAX (R)
  (assert (= R _EAX) "EAX register required")
  (_rN R))

;;; IMMEDIATES

(define-function _u1P (I)
  (= 0 (bitwise-and I -0x100)))

(define-function _u2P (I)
  (= 0 (bitwise-and I -0x10000)))

(define-function _s0P (I)
  (= I 0))

(define-function _s1P (I)
  (and (long? I)
       ;; -128 127
       (<= -0x80 I 0x7f)))

(define-function _s2P (I)
  (and (long? I)
       ;; -32768 32767
       (<= -0x8000 I 0x7fff)))

(define-function _s4P (I)
  (and (long? I)
       ;; -2147483648 2147483647
       (<= -0x80000000 I 0x7fffffff)))

(define-function _s1 (I)
  (assert (_s1P I) "out of range for 8-bit signed immediate: "I)
  I)

(define-function _s2 (I)
  (assert (_s2P I) "out of range for 16-bit signed immediate: "I)
  I)

(define-function _s4 (I)
  (assert (_s4P I) "out of range for 32-bit signed immediate: "I)
  I)

(define-function _u1 (I)
  (assert (_u1P I) "out of range for 8-bit unsigned immediate: "I)
  I)

(define-function _u2 (I)
  (assert (_u2P I) "out of range for 16-bit unsigned immediate: "I)
  I)

(define-function _d1 (I)
  (assert (_s1P I) "8-bit displacement out of range: "I)
  I)

(define-function _mod (M)
  (assert (<= M 3) "illegal mod: "M)
  M)

(define-function _reg (R)
  (assert (<= R 7) "illegal reg: "R)
  R)

(define-function _rm (M)
  (assert (<= M 7) "illegal r/m: "M)
  M)

(define-function _scale (S)
  (assert (<= S 3) "illegal memory scale: "S)
  S)

(define-function _index (I)
  (assert (<= I 7) "illegal memory index: "I)
  I)

(define-function _base (B)
  (assert (<= B 7) "illegal memory base: "B)
  B)

(define-function _Mrm (mod reg rm)
  (_B (bitwise-or (bitwise-shift (_mod mod) 6)
                  (bitwise-shift (_reg reg) 3)
                  (_rm rm))))

(define-function _SIB (Sc I B)
  (_B (bitwise-or (bitwise-shift (_scale Sc) 6)
                  (bitwise-shift (_index I) 3)
                  (_base B))))

(define-function _SCL (S)
  (cond
    ((= S 1) _b00)
    ((= S 2) _b01)
    ((= S 4) _b10)
    ((= S 8) _b11)
    (else (ASMFAIL "illegal scale: "S))))

;;;
;;; memory subformats
;;;

;; R: dest reg
;; D: displacement
;; B: base reg
;; I: index reg
;; S: scale
;;
;; _r_...:	reg + memory operand
;; _r_D:	rip + disp32; note: there's no mod=01/disp8 version of RIP-relative
;; _r_0B:	base only, no displacement
;; _r_1B:	base + 8-bit displacement
;; _r_4B:	base + 32-bit displacement
;; _r_DB:	Chooses automatically between _0B, _1B, _4B
;; _r_0BIS: base + index + scale, no displacement
;; _r_0DIS:

(define-function _r_D (R D)
  (_Mrm _b00 (_rN R) _b101)
  (emit_rip_disp32 D))

(define-function _r_0B (R B)
  (_Mrm _b00 (_rN R) (_r4 B)))

(define-function _r_0BIS (R B I S)
  (_Mrm _b00 (_rN R) _b100)
  (_SIB (_SCL S) (_r4 I) (_r4 B)))

(define-function _r_0DIS (R D I S)
  (_Mrm _b00 (_rN R) _b100)
  (_SIB (_SCL S) (_r4 I) 5)
  (_L D))

(define-function _r_1B (R D B)
  (_Mrm _b01 (_rN R) (_r4 B))
  (_B D))

(define-function _r_1BIS (R D B I S)
  (_Mrm _b01 (_rN R) _b100)
  (_SIB (_SCL S) (_r4 I) (_r4 B))
  (_B D))

(define-function _r_4B (R D B)
  (_Mrm _b10 (_rN R) (_r4 B))
  (_L D))

(define-function _r_4BIS (R D B I S)
  (_Mrm _b10 (_rN R) _b100)
  (_SIB (_SCL S) (_r4 I) (_r4 B))
  (_L D))

(define-function _r_DB (R D B)
  (cond
    ((_s0P D)	(_r_0B R B))
    ((_s1P D)	(_r_1B R D B))
    (else	(_r_4B R D B))))

(define-function _r_DBIS (R D B I S)
  (cond
    ((_s0P D)	(_r_0BIS R B I S))
    ((_s1P D)	(_r_1BIS R D B I S))
    (else	(_r_4BIS R D B I S))))

;; 32 bit version
;; (define-function _r_X (R D B I S)
;;   (if (_r0P I)
;;       (if (_r0P B)
;;           (_r_D R D)
;;         (if (= _ESP B)
;;             (_r_DBIS R D _ESP _ESP 1)
;;           (_r_DB R D B)))
;;     (if (_r0P B)
;;         (_r_0DIS R D I S)
;;       (if (!= I _ESP)
;;           (_r_DBIS R D B I S)
;;         (ASMFAIL "illegal index register: %esp")))))

;; 64 bit version
(define-function _r_X (R D B I S)
  (cond
    ((_r0P I)	(cond
                  ((_r0P B)	(_r_D R D))
                  ((= _ESP B)	(_r_DBIS R D _ESP _ESP 1))
                  (else		(_r_DB R D B))))
    ((_r0P B)	(_r_0DIS R D I S))
    (else	(_r_DBIS R D B I S))))

(define-function _rXP (R) (>= (bitwise-and R 15) 8))

(define-function _r8P (R) (= (_rS R) 8))

(define-function _r8 (R)
  (if (_r0P R)
      0
    (if (_r8P R)
        (+ 64 (_rN R))
      (ASMFAIL "64-bit register required"))))

(define-function _REX (W R X B)
  (let ((value (+ (if (_rXP R) 4 0)
                  (if (_rXP X) 2 0)
                  (if (_rXP B) 1 0)
                  (bitwise-shift W 3))))
    (unless (= 0 value)
      (_B (+ 0x40 value)))))

;;;
;;; instruction formats
;;;

;; Naming Convention:
;;
;; O		 8 bit opcode
;; OO      	16 bit opcode
;; Os		opcode + b10 when imm fits short (imm8)
;; Or		opcode + register
;; sW, sL		try short (imm8), revert to imm16 or imm32
;; X		dispatch on register, displ, base, index, scale and emit appropriate
;; imm		immediate value, usually postfixed with its size in bits
;; w prefix	emit with the 0x66 prefix; i.e. 16 bit operand size

(define-function _d16 ()
  (_B 0x66))

(define-function _O (OP)
  (_B OP))

(define-function _Or (OP R)
  (_B (bitwise-or OP (_reg R))))

(define-function _OO (OP)
  (_B (bitwise-shift OP -8))
  (_B (bitwise-and OP 0xff)))

(define-function _OOr (OP R)
  (_B (bitwise-shift OP -8))
  (_B (bitwise-or OP (_reg R))))

(define-function _Os (OP B)
  (if (and (long? B)
           (_s1P B))
      (_B (bitwise-or OP _b10))
    (_B OP)))

(define-function _sW (W)
  (if (_s1P W)
      (_B W)
    (_W W)))

(define-function _sL (L)
  (if (_s1P L)
      (_B L)
    (_L L)))

(define-function _O_W (OP W)
  (_O OP)
  (_W W))

(define-function _O_D1 (OP D)
  (_O OP)
  (_D1 D))

(define-function _O_D4 (OP D)
  (_O OP)
  (_D4 D))

(define-function _OO_D4 (OP D)
  (_OO OP)
  (_D4 D))

(define-function _Os_sW (OP W)
  (_Os OP W)
  (_sW W))

(define-function _Os_sL (OP L)
  (_Os OP L)
  (_sL L))

(define-function _O_W_B (OP W B)
  (_O OP)
  (_W W)
  (_B B))

(define-function _Or_B (OP R B)
  (_Or OP R)
  (_B B))

(define-function _Or_W (OP R W)
  (_Or OP R)
  (_W W))

(define-function _Or_L (OP R L)
  (_Or OP R)
  (_L L))

(define-function _Or_Q (OP R Q)
  (_Or OP R)
  (_Q Q))

(define-function _O_Mrm (OP MO R M)
  (_O OP)
  (_Mrm MO R M))

(define-function _OO_Mrm (OP MO R M)
  (_OO OP)
  (_Mrm MO R M))

(define-function _O_Mrm_B (OP MO R M B)
  (_O OP)
  (_Mrm MO R M)
  (_B B))

(define-function _O_Mrm_W (OP MO R M W)
  (_O OP)
  (_Mrm MO R M)
  (_W W))

(define-function _O_Mrm_L (OP MO R M L)
  (_O OP)
  (_Mrm MO R M)
  (_L L))

(define-function _OO_Mrm_B (OP MO R M B)
  (_OO OP)
  (_Mrm MO R M)
  (_B B))

(define-function _Os_Mrm_sW (OP MO R M W)
  (_Os OP W)
  (_Mrm MO R M)
  (_sW W))

(define-function _Os_Mrm_sL (OP MO R M L)
  (_Os OP L)
  (_Mrm MO R M)
  (_sL L))

(define-function _O_r_X (OP R D B I S)
  (_O OP)
  (_r_X R D B I S))

(define-function _OO_r_X (OP R MD MB MI MS)
  (_OO OP)
  (_r_X R MD MB MI MS))

(define-function _O_r_X_B (OP R MD MB MI MS B)
  (_O OP)
  (_r_X R MD MB MI MS)
  (_B B))

(define-function _O_r_X_W (OP R MD MB MI MS W)
  (_O OP)
  (_r_X R MD MB MI MS)
  (_W W))

(define-function _O_r_X_L (OP R MD MB MI MS L)
  (_O OP)
  (_r_X R MD MB MI MS)
  (_L L))

(define-function _OO_r_X_B (OP R MD MB MI MS B)
  (_OO OP)
  (_r_X R MD MB MI MS)
  (_B B))

(define-function _Os_r_X_sW (OP R MD MB MI MS W)
  (_Os OP W)
  (_r_X R MD MB MI MS)
  (_sW W))

(define-function _Os_r_X_sL (OP R MD MB MI MS L)
  (_Os OP L)
  (_r_X R MD MB MI MS)
  (_sL L))

(define-function _O_X_B (OP MD MB MI MS B) (_O_r_X_B OP 0 MD MB MI MS B))
(define-function _O_X_W (OP MD MB MI MS W) (_O_r_X_W OP 0 MD MB MI MS W))
(define-function _O_X_L (OP MD MB MI MS L) (_O_r_X_L OP 0 MD MB MI MS L))


;; TODO macrology for the _w prefix

(define-function _wO (OP)
  (_d16)
  (_O OP))

(define-function _wOr (OP R)
  (_d16)
  (_Or OP R))

(define-function _wOr_W (OP R W)
  (_d16)
  (_Or_W OP R W))

(define-function _wOs_sW (OP W)
  (_d16)
  (_Os_sW OP W))

(define-function _wO_Mrm (OP MO R M)
  (_d16)
  (_O_Mrm OP MO R M))

(define-function _wOO_Mrm (OP MO R M)
  (_d16)
  (_OO_Mrm OP MO R M))

(define-function _wO_Mrm_B (OP MO R M B)
  (_d16)
  (_O_Mrm_B OP MO R M B))

(define-function _wOO_Mrm_B (OP MO R M B)
  (_d16)
  (_OO_Mrm_B OP MO R M B))

(define-function _wO_Mrm_W (OP MO R M W)
  (_d16)
  (_O_Mrm_W OP MO R M W))

(define-function _wOs_Mrm_sW (OP MO R M W)
  (_d16)
  (_Os_Mrm_sW OP MO R M W))

(define-function _wO_X_W (OP MD MB MI MS W)
  (_d16)
  (_O_X_W OP MD MB MI MS W))

(define-function _wO_r_X (OP R MD MB MI MS)
  (_d16)
  (_O_r_X OP R MD MB MI MS))

(define-function _wOO_r_X (OP R MD MB MI MS)
  (_d16)
  (_OO_r_X OP R MD MB MI MS))

(define-function _wO_r_X_B (OP R MD MB MI MS B)
  (_d16)
  (_O_r_X_B OP R MD MB MI MS B))

(define-function _wOO_r_X_B (OP R MD MB MI MS B)
  (_d16)
  (_OO_r_X_B OP R MD MB MI MS B))

(define-function _wO_r_X_W (OP R MD MB MI MS W)
  (_d16)
  (_O_r_X_W OP R MD MB MI MS W))

(define-function _wOs_r_X_sW (OP R MD MB MI MS W)
  (_d16)
  (_Os_r_X_sW OP R MD MB MI MS W))



(define-function _to_r4 (R)
  (+ 0x40 (_rN R)))

(define-function _p67mr (D B I S R INST)
  (unless (or (_r8P B) (_r8P I))
    (_B 0x67))
  (INST D (_to_r4 B) (_to_r4 I) S R))

(define-function _p67rm (R D B I S INST)
  (unless (or (_r8P B) (_r8P I))
    (_B 0x67))
  (INST R D (_to_r4 B) (_to_r4 I) S))

(define-function _p67im (L D B I S INST)
  (unless (or (_r8P B) (_r8P I))
    (_B 0x67))
  (INST L D (_to_r4 B) (_to_r4 I) S))

;;;
;;; ALU “Group 1” (the most regular class)
;;;

(define-form define-alu-instruction (base-name op reg)
  (with-forms ((name ((suffix) `(concat-symbol base-name ',suffix))))
    `(begin
      ;; 8 bit
      (define-function ,(name Brr)	(RS RD)			(_O_Mrm		,op		_b11 (_r1 RS) (_r1 RD)					))
      (define-function ,(name Bmr)	(MD MB MI MS RD)	(_O_r_X		,(+ op 2)	(_r1 RD)		MD MB MI MS			))
      (define-function ,(name Brm)	(RS MD MB MI MS)	(_O_r_X		,op		(_r1 RS)		MD MB MI MS			))
      (define-function ,(name Bir)	(IM RD)			(_O_Mrm_B	0x80		_b11 ,reg (_r1 RD)			(_s1 IM)	))
      (define-function ,(name Bim)	(IM MD MB MI MS)	(_O_r_X_B	0x80		,reg			MD MB MI MS	(_s1 IM)	))

      ;; 16 bit
      (define-function ,(name Wrr)	(RS RD)			(_wO_Mrm	,(+ op 1)	_b11 (_r2 RS) (_r2 RD)					))
      (define-function ,(name Wmr)	(MD MB MI MS RD)	(_wO_r_X	,(+ op 3)	(_r2 RD)		MD MB MI MS			))
      (define-function ,(name Wrm)	(RS MD MB MI MS)	(_wO_r_X        ,(+ op 1)	(_r2 RS)		MD MB MI MS			))
      (define-function ,(name Wir)	(IM RD)			(_wOs_Mrm_sW	0x81		_b11 ,reg (_r2 RD)			(_s2 IM)	))
      (define-function ,(name Wim)	(IM MD MB MI MS)	(_wOs_r_X_sW	0x81		,reg			MD MB MI MS	(_s2 IM)	))

      ;; 32 bit
      (define-function ,(name Lrr)	(RS RD)			(_O_Mrm		,(+ op 1)	_b11 (_r4 RS) (_r4 RD)					))
      (define-function ,(name Lmr)	(MD MB MI MS RD)	(_O_r_X		,(+ op 3)	(_r4 RD)		MD MB MI MS			))
      (define-function ,(name Lrm)	(RS MD MB MI MS)	(_O_r_X		,(+ op 1)	(_r4 RS)		MD MB MI MS			))
      (define-function ,(name Li8r)	(IM RD)			(_O_Mrm_B	0x83		_b11 ,reg (_r4 RD)			IM		))
      (define-function ,(name Li32r)	(IM RD)			(_O_Mrm_L	0x81		_b11 ,reg (_r4 RD)			IM		))
      (define-function ,(name Lir)	(IM RD)			((if (_s1P IM) ,(name Li8r) ,(name Li32r)) IM RD))
      (define-function ,(name Lim)	(IM MD MB MI MS)	(_Os_r_X_sL	0x81		,reg			MD MB MI MS	IM		))

      ;; 64 bit is just REX prefixed 32 bit
      (define-function ,(name Qrr)	(RS RD)			(_REX 1 RS 0 RD)	(,(name Lrr)	(_r8 RS) (_r8 RD)))
      (define-function ,(name Qmr)	(D B I S RD)		(_REX 1 RD I B)		(,(name Lmr)	D (_r8 B) (_r8 I) S (_r8 RD)))
      (define-function ,(name Qrm)	(RS D B I S)		(_REX 1 RS I B)		(,(name Lrm)	(_r8 RS) D (_r8 B) (_r8 I) S))
      (define-function ,(name Qi8r)	(L RD)			(_REX 1 0 0 RD)		(,(name Li8r)	L (_r8 RD)))
      (define-function ,(name Qi32r)	(L RD)			(_REX 1 0 0 RD)		(,(name Li32r)	L (_r8 RD)))
      (define-function ,(name Qir)	(L RD)			(_REX 1 0 0 RD)		(,(name Lir)	L (_r8 RD)))
      (define-function ,(name Qim)	(L D B I S)		(_REX 1 0 I B)		(,(name Lim)	L D (_r8 B) (_r8 I) S))
      )))

(define-alu-instruction ADD 0x00 _b000)
(define-alu-instruction OR  0x08 _b001)
(define-alu-instruction ADC 0x10 _b010)
(define-alu-instruction SBB 0x18 _b011)
(define-alu-instruction AND 0x20 _b100)
(define-alu-instruction SUB 0x28 _b101)
(define-alu-instruction XOR 0x30 _b110)
(define-alu-instruction CMP 0x38 _b111)

(define-function MOVBrr (RS RD)			(_O_Mrm 0x80 _b11 (_r1 RS) (_r1 RD)))
(define-function MOVBir (IM R)			(_Or_B  0xb0 (_r1 R) (_s1 IM)))
(define-function MOVBmr32 (D B I S RD)		(_O_r_X 0x8a (_r1 RD) D B I S))
(define-function MOVBrm32 (RS D B I S)		(_O_r_X 0x88 (_r1 RS) D B I S))
(define-function MOVBim32 (L D B I S)		(_O_X_B 0xc6 D B I S (_s1 L)))
(define-function MOVBmr (D B I S R)		(_p67mr D B I S R MOVBmr32))
(define-function MOVBrm (R D B I S)		(_p67rm R D B I S MOVBrm32))
(define-function MOVBim (L D B I S)		(_p67im L D B I S MOVBim32))

(define-function MOVLrr (RS RD)			(_O_Mrm 0x89 _b11 (_r4 RS) (_r4 RD)))
(define-function MOVLmr (D B I S RD)		(_O_r_X 0x8b (_r4 RD) D B I S))
(define-function MOVLrm (RS D B I S)		(_O_r_X 0x89 (_r4 RS) D B I S))
(define-function MOVLir (L R)			(_Or_L  0xb8 (_r4 R) L))
(define-function MOVLim (L D B I S)		(_O_X_L 0xc7 D B I S L))

;; TODO ? MOVABSQir emits the same as MOVQir
;;(define-function MOVABSQir (I R)		(_REX 1 0 0 R) (MOVLir I (_r8 R)) (_L (bitwise-shift I -32)))
(define-function MOVQrr (S D)			(_REX 1 S 0 D) (MOVLrr (_r8 S) (_r8 D)))
(define-function MOVQmr (D B I S R)		(_REX 1 R I B) (MOVLmr D (_r8 B) (_r8 I) S (_r8 R)))
(define-function MOVQrm (R D B I S)		(_REX 1 R I B) (MOVLrm (_r8 R) D (_r8 B) (_r8 I) S))
(define-function MOVQi32r (L R)			(_REX 1 0 0 R) (_O_Mrm_L	0xc7 _b11 0 (_rN (_r8 R)) L))
(define-function MOVQi64r (L R)			(_REX 1 0 0 R) (_Or_Q		0xb8 (_rN (_r8 R)) L))
(define-function MOVQir (L R)			(if (_s4P L) (MOVQi32r L R) (MOVQi64r L R)))
(define-function MOVQim (L D B I S)		(_REX 1 0 I B) (MOVLim L D (_r8 B) (_r8 I) S))

(define-function BSWAPLr (R)			(_OOr 0x0fc8 (_r4 R)))
(define-function BTWir (IM RD)			(_wOO_Mrm_B 4026 _b11 _b100 (_r2 RD) (_u1 IM)))
(define-function BTWim (IM MD MB MI MS)		(_wOO_r_X_B 4026 _b100 MD MB MI MS (_u1 IM)))
(define-function BTWrr (RS RD)			(_wOO_Mrm 4003 _b11 (_r2 RS) (_r2 RD)))
(define-function BTWrm (RS MD MB MI MS)		(_wOO_r_X 4003 (_r2 RS) MD MB MI MS))
(define-function BTLir (IM RD)			(_OO_Mrm_B 4026 _b11 _b100 (_r4 RD) (_u1 IM)))
(define-function BTLim (IM MD MB MI MS)		(_OO_r_X_B 4026 _b100 MD MB MI MS (_u1 IM)))
(define-function BTLrr (RS RD)			(_OO_Mrm 4003 _b11 (_r4 RS) (_r4 RD)))
(define-function BTLrm (RS MD MB MI MS)		(_OO_r_X 4003 (_r4 RS) MD MB MI MS))
(define-function BTCWir (IM RD)			(_wOO_Mrm_B 4026 _b11 _b111 (_r2 RD) (_u1 IM)))
(define-function BTCWim (IM MD MB MI MS)	(_wOO_r_X_B 4026 _b111 MD MB MI MS (_u1 IM)))
(define-function BTCWrr (RS RD)			(_wOO_Mrm 4027 _b11 (_r2 RS) (_r2 RD)))
(define-function BTCWrm (RS MD MB MI MS)	(_wOO_r_X 4027 (_r2 RS) MD MB MI MS))
(define-function BTCLir (IM RD)			(_OO_Mrm_B 4026 _b11 _b111 (_r4 RD) (_u1 IM)))
(define-function BTCLim (IM MD MB MI MS)	(_OO_r_X_B 4026 _b111 MD MB MI MS (_u1 IM)))
(define-function BTCLrr (RS RD)			(_OO_Mrm 4027 _b11 (_r4 RS) (_r4 RD)))
(define-function BTCLrm (RS MD MB MI MS)	(_OO_r_X 4027 (_r4 RS) MD MB MI MS))
(define-function BTRWir (IM RD)			(_wOO_Mrm_B 4026 _b11 _b110 (_r2 RD) (_u1 IM)))
(define-function BTRWim (IM MD MB MI MS)	(_wOO_r_X_B 4026 _b110 MD MB MI MS (_u1 IM)))
(define-function BTRWrr (RS RD)			(_wOO_Mrm 4019 _b11 (_r2 RS) (_r2 RD)))
(define-function BTRWrm (RS MD MB MI MS)	(_wOO_r_X 4019 (_r2 RS) MD MB MI MS))
(define-function BTRLir (IM RD)			(_OO_Mrm_B 4026 _b11 _b110 (_r4 RD) (_u1 IM)))
(define-function BTRLim (IM MD MB MI MS)	(_OO_r_X_B 4026 _b110 MD MB MI MS (_u1 IM)))
(define-function BTRLrr (RS RD)			(_OO_Mrm 4019 _b11 (_r4 RS) (_r4 RD)))
(define-function BTRLrm (RS MD MB MI MS)	(_OO_r_X 4019 (_r4 RS) MD MB MI MS))
(define-function BTSWir (IM RD)			(_wOO_Mrm_B 4026 _b11 _b101 (_r2 RD) (_u1 IM)))
(define-function BTSWim (IM MD MB MI MS)	(_wOO_r_X_B 4026 _b101 MD MB MI MS (_u1 IM)))
(define-function BTSWrr (RS RD)			(_wOO_Mrm 4011 _b11 (_r2 RS) (_r2 RD)))
(define-function BTSWrm (RS MD MB MI MS)	(_wOO_r_X 4011 (_r2 RS) MD MB MI MS))
(define-function BTSLir (IM RD)			(_OO_Mrm_B 4026 _b11 _b101 (_r4 RD) (_u1 IM)))
(define-function BTSLim (IM MD MB MI MS)	(_OO_r_X_B 4026 _b101 MD MB MI MS (_u1 IM)))
(define-function BTSLrr (RS RD)			(_OO_Mrm 4011 _b11 (_r4 RS) (_r4 RD)))
(define-function BTSLrm (RS MD MB MI MS)	(_OO_r_X 4011 (_r4 RS) MD MB MI MS))
(define-function CALLr (RD)			(_O_Mrm 255 _b11 _b010 (_r4 RD)))
(define-function CALLm (MD MB MI MS)		(if (and (_r0P MB) (_r0P MI)) (_O_D4 232 MD) (_O_r_X 255 _b010 MD MB MI MS)))
(define-function CMPXCHGBrr (RS RD)		(_OO_Mrm 4016 _b11 (_r1 RS) (_r1 RD)))
(define-function CMPXCHGBrm (RS MD MB MI MS)	(_OO_r_X 4016 (_r1 RS) MD MB MI MS))
(define-function CMPXCHGWrr (RS RD)		(_wOO_Mrm 4017 _b11 (_r2 RS) (_r2 RD)))
(define-function CMPXCHGWrm (RS MD MB MI MS)	(_wOO_r_X 4017 (_r2 RS) MD MB MI MS))
(define-function CMPXCHGLrr (RS RD)		(_OO_Mrm 4017 _b11 (_r4 RS) (_r4 RD)))
(define-function CMPXCHGLrm (RS MD MB MI MS)	(_OO_r_X 4017 (_r4 RS) MD MB MI MS))
(define-function DECBr (RD)			(_O_Mrm 254 _b11 _b001 (_r1 RD)))
(define-function DECBm (MD MB MI MS)		(_O_r_X 254 _b001 MD MB MI MS))
(define-function DECWr (RD)			(_wOr 72 (_r2 RD)))
(define-function DECWm (MD MB MI MS)		(_wO_r_X 255 _b001 MD MB MI MS))
(define-function DECLr (RD)			(_Or 72 (_r4 RD)))
(define-function DECLm (MD MB MI MS)		(_O_r_X 255 _b001 MD MB MI MS))
(define-function DIVBrr (RS RD)			(+ (_rAL RD) (_O_Mrm 246 _b11 _b110 (_r1 RS))))
(define-function DIVBmr (MD MB MI MS RD)	(+ (_rAL RD) (_O_r_X 246 _b110 MD MB MI MS)))
(define-function DIVWrr (RS RD)			(+ (_rAX RD) (_wO_Mrm 247 _b11 _b110 (_r2 RS))))
(define-function DIVWmr (MD MB MI MS RD)	(+ (_rAX RD) (_wO_r_X 247 _b110 MD MB MI MS)))
(define-function DIVLrr (RS RD)			(+ (_rEAX RD) (_O_Mrm 247 _b11 _b110 (_r4 RS))))
(define-function DIVLmr (MD MB MI MS RD)	(+ (_rEAX RD) (_O_r_X 247 _b110 MD MB MI MS)))
(define-function ENTERii (W B)			(_O_W_B 200 (_s2 W) (_s1 B)))
(define-function IDIVBrr (RS RD)		(+ (_rAL RD) (_O_Mrm 246 _b11 _b111 (_r1 RS))))
(define-function IDIVBmr (MD MB MI MS RD)	(+ (_rAL RD) (_O_r_X 246 _b111 MD MB MI MS)))
(define-function IDIVWrr (RS RD)		(+ (_rAX RD) (_wO_Mrm 247 _b11 _b111 (_r2 RS))))
(define-function IDIVWmr (MD MB MI MS RD)	(+ (_rAX RD) (_wO_r_X 247 _b111 MD MB MI MS)))
(define-function IDIVLrr (RS RD)		(+ (_rEAX RD) (_O_Mrm 247 _b11 _b111 (_r4 RS))))
(define-function IDIVLmr (MD MB MI MS RD)	(+ (_rEAX RD) (_O_r_X 247 _b111 MD MB MI MS)))
(define-function IMULWrr (RS RD)		(_wOO_Mrm 4015 _b11 (_r2 RS) (_r2 RD)))
(define-function IMULWmr (MD MB MI MS RD)	(_wOO_r_X 4015 (_r2 RD) MD MB MI MS))
(define-function IMULWirr (IM RS RD)		(_wOs_Mrm_sW 105 _b11 (_r2 RS) (_r2 RD) IM))
(define-function IMULWimr (IM MD MB MI MS RD)	(_wOs_r_X_sW 105 (_r2 RD) MD MB MI MS IM))
(define-function IMULLrr (RS RD)		(_OO_Mrm 4015 _b11 (_r4 RD) (_r4 RS)))
(define-function IMULLmr (MD MB MI MS RD)	(_OO_r_X 4015 (_r4 RD) MD MB MI MS))
(define-function IMULLirr (IM RS RD)		(_Os_Mrm_sL 105 _b11 (_r4 RS) (_r4 RD) IM))
(define-function IMULLimr (IM MD MB MI MS RD)	(_Os_r_X_sL 105 (_r4 RD) MD MB MI MS IM))
(define-function INCBr (RD)			(_O_Mrm 254 _b11 _b000 (_r1 RD)))
(define-function INCBm (MD MB MI MS)		(_O_r_X 254 _b000 MD MB MI MS))
(define-function INCWr (RD)			(_wOr 64 (_r2 RD)))
(define-function INCWm (MD MB MI MS)		(_wO_r_X 255 _b000 MD MB MI MS))
(define-function INCLr (RD)			(_Or 64 (_r4 RD)))
(define-function INCLm (MD MB MI MS)		(_O_r_X 255 _b000 MD MB MI MS))
(define-function INVLPGm (MD MB MI MS)		(_OO_r_X 3841 _b111 MD MB MI MS))

(define-function JMPSm (D B I S)		(if (and (_r0P B) (_r0P I)) (_O_D1 235 D) (ASMFAIL "illegal mode in short jump")))
(define-function JMPm (D B I S)			(if (and (_r0P B) (_r0P I)) (_O_D4 233 D) (_O_r_X 255 _b100 D B I S)))
(define-function JMPr (R)			(_O_Mrm 255 _b11 _b100 (_r4 R)))
(define-function LAHF () (_O 159))
(define-function LEALmr (MD MB MI MS RD) (_O_r_X 141 (_r4 RD) MD MB MI MS))
(define-function LEAVE () (_O 201))
(define-function LMSWr (RS) (_OO_Mrm 3841 _b11 _b110 (_r4 RS)))
(define-function LMSWm (MD MB MI MS) (_OO_r_X 3841 _b110 MD MB MI MS))
(define-function LOOPm (MD MB MI MS) (if (and (_r0P MB) (_r0P MI)) (_O_D1 226 MD) (ASMFAIL "illegal mode in loop")))
(define-function LOOPEm (MD MB MI MS) (if (and (_r0P MB) (_r0P MI)) (_O_D1 225 MD) (ASMFAIL "illegal mode in loope")))
(define-function LOOPZm (MD MB MI MS) (if (and (_r0P MB) (_r0P MI)) (_O_D1 225 MD) (ASMFAIL "illegal mode in loopz")))
(define-function LOOPNEm (MD MB MI MS) (if (and (_r0P MB) (_r0P MI)) (_O_D1 224 MD) (ASMFAIL "illegal mode in loopne")))
(define-function LOOPNZm (MD MB MI MS) (if (and (_r0P MB) (_r0P MI)) (_O_D1 224 MD) (ASMFAIL "illegal mode in loopnz")))
(define-function MOVWrr (RS RD) (_wO_Mrm 137 _b11 (_r2 RS) (_r2 RD)))
(define-function MOVWmr (MD MB MI MS RD) (_wO_r_X 139 (_r2 RD) MD MB MI MS))
(define-function MOVWrm (RS MD MB MI MS) (_wO_r_X 137 (_r2 RS) MD MB MI MS))
(define-function MOVWir (IM R) (_wOr_W 184 (_r2 R) (_s2 IM)))
(define-function MOVWim (IM MD MB MI MS) (_wO_X_W 199 MD MB MI MS (_s2 IM)))
(define-function MOVSBLrr (RS RD) (_OO_Mrm 4030 _b11 (_r4 RD) (_r1 RS)))
(define-function MOVSBLmr (MD MB MI MS RD) (_OO_r_X 4030 (_r4 RD) MD MB MI MS))
(define-function MOVZBLmr (MD MB MI MS RD) (_OO_r_X 4022 (_r4 RD) MD MB MI MS))
(define-function MOVZBLrr (RS RD) (_OO_Mrm 4022 _b11 (_r4 RD) (_r1 RS)))
(define-function MULBrr (RS RD) (+ (_rAL RD) (_O_Mrm 246 _b11 _b100 (_r1 RS))))
(define-function MULBmr (MD MB MI MS RD) (+ (_rAL RD) (_O_r_X 246 _b100 MD MB MI MS)))
(define-function MULWrr (RS RD) (+ (_rAX RD) (_wO_Mrm 247 _b11 _b100 (_r2 RS))))
(define-function MULWmr (MD MB MI MS RD) (+ (_rAX RD) (_wO_r_X 247 _b100 MD MB MI MS)))
(define-function MULLrr (RS RD) (+ (_rEAX RD) (_O_Mrm 247 _b11 _b100 (_r4 RS))))
(define-function MULLmr (MD MB MI MS RD) (+ (_rEAX RD) (_O_r_X 247 _b100 MD MB MI MS)))
(define-function NEGBr (RD) (_O_Mrm 246 _b11 _b011 (_r1 RD)))
(define-function NEGBm (MD MB MI MS) (_O_r_X 246 _b011 MD MB MI MS))
(define-function NEGWr (RD) (_wO_Mrm 247 _b11 _b011 (_r2 RD)))
(define-function NEGWm (MD MB MI MS) (_wO_r_X 247 _b011 MD MB MI MS))
(define-function NEGLr (RD) (_O_Mrm 247 _b11 _b011 (_r4 RD)))
(define-function NEGLm (MD MB MI MS) (_O_r_X 247 _b011 MD MB MI MS))
(define-function NOP () (_O 144))
(define-function NOTBr (RD) (_O_Mrm 246 _b11 _b010 (_r1 RD)))
(define-function NOTBm (MD MB MI MS) (_O_r_X 246 _b010 MD MB MI MS))
(define-function NOTWr (RD) (_wO_Mrm 247 _b11 _b010 (_r2 RD)))
(define-function NOTWm (MD MB MI MS) (_wO_r_X 247 _b010 MD MB MI MS))
(define-function NOTLr (RD) (_O_Mrm 247 _b11 _b010 (_r4 RD)))
(define-function NOTLm (MD MB MI MS) (_O_r_X 247 _b010 MD MB MI MS))

(define-function POPWr (RD) (_wOr 88 (_r2 RD)))
(define-function POPWm (MD MB MI MS) (_wO_r_X 143 _b000 MD MB MI MS))
(define-function POPLr (RD) (_Or 88 (_r4 RD)))
(define-function POPLm (MD MB MI MS) (_O_r_X 143 _b000 MD MB MI MS))
(define-function POPA () (_wO 97))
(define-function POPAD () (_O 97))
(define-function POPF () (_wO 157))
(define-function POPFD () (_O 157))
(define-function PUSHWr (R) (_wOr 80 (_r2 R)))
(define-function PUSHWm (MD MB MI MS) (_wO_r_X 255 _b110 MD MB MI MS))
(define-function PUSHWi (IM) (_wOs_sW 104 IM))
(define-function PUSHLr (R) (_Or 80 (_r4 R)))
(define-function PUSHLm (MD MB MI MS) (_O_r_X 255 _b110 MD MB MI MS))
(define-function PUSHLi (IM) (_Os_sL 104 IM))
(define-function PUSHA () (_wO 96))
(define-function PUSHAD () (_O 96))
(define-function PUSHF () (_O 156))
(define-function PUSHFD () (_wO 156))
(define-function RET () (_O 195))
(define-function RETi (IM) (_O_W 194 (_s2 IM)))
(define-function ROLBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b000 (_r1 RD)) (_O_Mrm_B 192 _b11 _b000 (_r1 RD) (_u1 IM))))
(define-function ROLBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b000 MD MB MI MS) (_O_r_X_B 192 _b000 MD MB MI MS (_u1 IM))))
(define-function ROLBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b000 (_r1 RD)) (ASMFAIL "source register must be CL")))
(define-function ROLBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b000 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function ROLWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b000 (_r2 RD)) (_wO_Mrm_B 193 _b11 _b000 (_r2 RD) (_u1 IM))))
(define-function ROLWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b000 MD MB MI MS) (_wO_r_X_B 193 _b000 MD MB MI MS (_u1 IM))))
(define-function ROLWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b000 (_r2 RD)) (ASMFAIL "source register must be CL")))
(define-function ROLWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b000 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function ROLLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b000 (_r4 RD)) (_O_Mrm_B 193 _b11 _b000 (_r4 RD) (_u1 IM))))
(define-function ROLLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b000 MD MB MI MS) (_O_r_X_B 193 _b000 MD MB MI MS (_u1 IM))))
(define-function ROLLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b000 (_r4 RD)) (ASMFAIL "source register must be CL")))
(define-function ROLLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b000 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function RORBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b001 (_r1 RD)) (_O_Mrm_B 192 _b11 _b001 (_r1 RD) (_u1 IM))))
(define-function RORBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b001 MD MB MI MS) (_O_r_X_B 192 _b001 MD MB MI MS (_u1 IM))))
(define-function RORBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b001 (_r1 RD)) (ASMFAIL "source register must be CL")))
(define-function RORBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b001 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function RORWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b001 (_r2 RD)) (_wO_Mrm_B 193 _b11 _b001 (_r2 RD) (_u1 IM))))
(define-function RORWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b001 MD MB MI MS) (_wO_r_X_B 193 _b001 MD MB MI MS (_u1 IM))))
(define-function RORWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b001 (_r2 RD)) (ASMFAIL "source register must be CL")))
(define-function RORWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b001 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function RORLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b001 (_r4 RD)) (_O_Mrm_B 193 _b11 _b001 (_r4 RD) (_u1 IM))))
(define-function RORLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b001 MD MB MI MS) (_O_r_X_B 193 _b001 MD MB MI MS (_u1 IM))))
(define-function RORLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b001 (_r4 RD)) (ASMFAIL "source register must be CL")))
(define-function RORLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b001 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SAHF () (_O 158))
(define-function SARBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b111 (_r1 RD)) (_O_Mrm_B 192 _b11 _b111 (_r1 RD) (_u1 IM))))
(define-function SARBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b111 MD MB MI MS) (_O_r_X_B 192 _b111 MD MB MI MS (_u1 IM))))
(define-function SARBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b111 (_r1 RD)) (ASMFAIL "source register must be CL")))
(define-function SARBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b111 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SARWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b111 (_r2 RD)) (_wO_Mrm_B 193 _b11 _b111 (_r2 RD) (_u1 IM))))
(define-function SARWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b111 MD MB MI MS) (_wO_r_X_B 193 _b111 MD MB MI MS (_u1 IM))))
(define-function SARWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b111 (_r2 RD)) (ASMFAIL "source register must be CL")))
(define-function SARWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b111 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SARLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b111 (_r4 RD)) (_O_Mrm_B 193 _b11 _b111 (_r4 RD) (_u1 IM))))
(define-function SARLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b111 MD MB MI MS) (_O_r_X_B 193 _b111 MD MB MI MS (_u1 IM))))
(define-function SARLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b111 (_r4 RD)) (ASMFAIL "source register must be CL")))
(define-function SARLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b111 MD MB MI MS) (ASMFAIL "source register must be CL")))

(define-function SETCCir (CC RD) (_OO_Mrm (bitwise-or 3984 CC) _b11 _b000 (_r1 RD)))
(define-function SETOr (RD) (SETCCir 0 RD))
(define-function SETNOr (RD) (SETCCir 1 RD))
(define-function SETBr (RD) (SETCCir 2 RD))
(define-function SETNAEr (RD) (SETCCir 2 RD))
(define-function SETNBr (RD) (SETCCir 3 RD))
(define-function SETAEr (RD) (SETCCir 3 RD))
(define-function SETEr (RD) (SETCCir 4 RD))
(define-function SETZr (RD) (SETCCir 4 RD))
(define-function SETNEr (RD) (SETCCir 5 RD))
(define-function SETNZr (RD) (SETCCir 5 RD))
(define-function SETBEr (RD) (SETCCir 6 RD))
(define-function SETNAr (RD) (SETCCir 6 RD))
(define-function SETNBEr (RD) (SETCCir 7 RD))
(define-function SETAr (RD) (SETCCir 7 RD))
(define-function SETSr (RD) (SETCCir 8 RD))
(define-function SETNSr (RD) (SETCCir 9 RD))
(define-function SETPr (RD) (SETCCir 10 RD))
(define-function SETPEr (RD) (SETCCir 10 RD))
(define-function SETNPr (RD) (SETCCir 11 RD))
(define-function SETPOr (RD) (SETCCir 11 RD))
(define-function SETLr (RD) (SETCCir 12 RD))
(define-function SETNGEr (RD) (SETCCir 12 RD))
(define-function SETNLr (RD) (SETCCir 13 RD))
(define-function SETGEr (RD) (SETCCir 13 RD))
(define-function SETLEr (RD) (SETCCir 14 RD))
(define-function SETNGr (RD) (SETCCir 14 RD))
(define-function SETNLEr (RD) (SETCCir 15 RD))
(define-function SETGr (RD) (SETCCir 15 RD))
(define-function SETCCim (CC MD MB MI MS) (_OO_r_X (bitwise-or 3984 CC) _b000 MD MB MI MS))
(define-function SETOm (D B I S) (SETCCim 0 D B I S))
(define-function SETNOm (D B I S) (SETCCim 1 D B I S))
(define-function SETBm (D B I S) (SETCCim 2 D B I S))
(define-function SETNAEm (D B I S) (SETCCim 2 D B I S))
(define-function SETNBm (D B I S) (SETCCim 3 D B I S))
(define-function SETAEm (D B I S) (SETCCim 3 D B I S))
(define-function SETEm (D B I S) (SETCCim 4 D B I S))
(define-function SETZm (D B I S) (SETCCim 4 D B I S))
(define-function SETNEm (D B I S) (SETCCim 5 D B I S))
(define-function SETNZm (D B I S) (SETCCim 5 D B I S))
(define-function SETBEm (D B I S) (SETCCim 6 D B I S))
(define-function SETNAm (D B I S) (SETCCim 6 D B I S))
(define-function SETNBEm (D B I S) (SETCCim 7 D B I S))
(define-function SETAm (D B I S) (SETCCim 7 D B I S))
(define-function SETSm (D B I S) (SETCCim 8 D B I S))
(define-function SETNSm (D B I S) (SETCCim 9 D B I S))
(define-function SETPm (D B I S) (SETCCim 10 D B I S))
(define-function SETPEm (D B I S) (SETCCim 10 D B I S))
(define-function SETNPm (D B I S) (SETCCim 11 D B I S))
(define-function SETPOm (D B I S) (SETCCim 11 D B I S))
(define-function SETLm (D B I S) (SETCCim 12 D B I S))
(define-function SETNGEm (D B I S) (SETCCim 12 D B I S))
(define-function SETNLm (D B I S) (SETCCim 13 D B I S))
(define-function SETGEm (D B I S) (SETCCim 13 D B I S))
(define-function SETLEm (D B I S) (SETCCim 14 D B I S))
(define-function SETNGm (D B I S) (SETCCim 14 D B I S))
(define-function SETNLEm (D B I S) (SETCCim 15 D B I S))
(define-function SETGm (D B I S) (SETCCim 15 D B I S))
(define-function SHLBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b100 (_r1 RD)) (_O_Mrm_B 192 _b11 _b100 (_r1 RD) (_u1 IM))))
(define-function SHLBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b100 MD MB MI MS) (_O_r_X_B 192 _b100 MD MB MI MS (_u1 IM))))
(define-function SHLBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b100 (_r1 RD)) (ASMFAIL "source register must be CL")))
(define-function SHLBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b100 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SHLWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b100 (_r2 RD)) (_wO_Mrm_B 193 _b11 _b100 (_r2 RD) (_u1 IM))))
(define-function SHLWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b100 MD MB MI MS) (_wO_r_X_B 193 _b100 MD MB MI MS (_u1 IM))))
(define-function SHLWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b100 (_r2 RD)) (ASMFAIL "source register must be CL")))
(define-function SHLWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b100 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SHLLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b100 (_r4 RD)) (_O_Mrm_B 193 _b11 _b100 (_r4 RD) (_u1 IM))))
(define-function SHLLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b100 MD MB MI MS) (_O_r_X_B 193 _b100 MD MB MI MS (_u1 IM))))
(define-function SHLLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b100 (_r4 RD)) (ASMFAIL "source register must be CL")))
(define-function SHLLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b100 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SHRBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b101 (_r1 RD)) (_O_Mrm_B 192 _b11 _b101 (_r1 RD) (_u1 IM))))
(define-function SHRBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b101 MD MB MI MS) (_O_r_X_B 192 _b101 MD MB MI MS (_u1 IM))))
(define-function SHRBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b101 (_r1 RD)) (ASMFAIL "source register must be CL")))
(define-function SHRBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b101 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SHRWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b101 (_r2 RD)) (_wO_Mrm_B 193 _b11 _b101 (_r2 RD) (_u1 IM))))
(define-function SHRWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b101 MD MB MI MS) (_wO_r_X_B 193 _b101 MD MB MI MS (_u1 IM))))
(define-function SHRWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b101 (_r2 RD)) (ASMFAIL "source register must be CL")))
(define-function SHRWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b101 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SHRLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b101 (_r4 RD)) (_O_Mrm_B 193 _b11 _b101 (_r4 RD) (_u1 IM))))
(define-function SHRLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b101 MD MB MI MS) (_O_r_X_B 193 _b101 MD MB MI MS (_u1 IM))))
(define-function SHRLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b101 (_r4 RD)) (ASMFAIL "source register must be CL")))
(define-function SHRLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b101 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function STC () (_O 249))

(define-function TESTBrr (RS RD) (_O_Mrm 132 _b11 (_r1 RS) (_r1 RD)))
(define-function TESTBrm (RS MD MB MI MS) (_O_r_X 132 (_r1 RS) MD MB MI MS))
(define-function TESTBir (IM RD) (_O_Mrm_B 246 _b11 _b000 (_r1 RD) (_u1 IM)))
(define-function TESTBim (IM MD MB MI MS) (_O_r_X_B 246 _b000 MD MB MI MS (_u1 IM)))
(define-function TESTWrr (RS RD) (_wO_Mrm 133 _b11 (_r2 RS) (_r2 RD)))
(define-function TESTWrm (RS MD MB MI MS) (_wO_r_X 133 (_r2 RS) MD MB MI MS))
(define-function TESTWir (IM RD) (_wO_Mrm_W 247 _b11 _b000 (_r2 RD) (_u2 IM)))
(define-function TESTWim (IM MD MB MI MS) (_wO_r_X_W 247 _b000 MD MB MI MS (_u2 IM)))
(define-function TESTLrr (RS RD) (_O_Mrm 133 _b11 (_r4 RS) (_r4 RD)))
(define-function TESTLrm (RS MD MB MI MS) (_O_r_X 133 (_r4 RS) MD MB MI MS))
(define-function TESTLir (IM RD) (_O_Mrm_L 247 _b11 _b000 (_r4 RD) IM))
(define-function TESTLim (IM MD MB MI MS) (_O_r_X_L 247 _b000 MD MB MI MS IM))
(define-function XADDBrr (RS RD) (_OO_Mrm 4032 _b11 (_r1 RS) (_r1 RD)))
(define-function XADDBrm (RS MD MB MI MS) (_OO_r_X 4032 (_r1 RS) MD MB MI MS))
(define-function XADDWrr (RS RD) (_wOO_Mrm 4033 _b11 (_r2 RS) (_r2 RD)))
(define-function XADDWrm (RS MD MB MI MS) (_wOO_r_X 4033 (_r2 RS) MD MB MI MS))
(define-function XADDLrr (RS RD) (_OO_Mrm 4033 _b11 (_r4 RS) (_r4 RD)))
(define-function XADDLrm (RS MD MB MI MS) (_OO_r_X 4033 (_r4 RS) MD MB MI MS))
(define-function XCHGBrr (RS RD) (_O_Mrm 134 _b11 (_r1 RS) (_r1 RD)))
(define-function XCHGBrm (RS MD MB MI MS) (_O_r_X 134 (_r1 RS) MD MB MI MS))
(define-function XCHGWrr (RS RD) (_wO_Mrm 135 _b11 (_r2 RS) (_r2 RD)))
(define-function XCHGWrm (RS MD MB MI MS) (_wO_r_X 135 (_r2 RS) MD MB MI MS))
(define-function XCHGLrr (RS RD) (_O_Mrm 135 _b11 (_r4 RS) (_r4 RD)))
(define-function XCHGLrm (RS MD MB MI MS) (_O_r_X 135 (_r4 RS) MD MB MI MS))

(define-constant SALBir SHLBir)
(define-constant SALBim SHLBim)
(define-constant SALBrr SHLBrr)
(define-constant SALBrm SHLBrm)
(define-constant SALWir SHLWir)
(define-constant SALWim SHLWim)
(define-constant SALWrr SHLWrr)
(define-constant SALWrm SHLWrm)
(define-constant SALLir SHLLir)
(define-constant SALLim SHLLim)
(define-constant SALLrr SHLLrr)
(define-constant SALLrm SHLLrm)
(define-function BSWAPr (R) (BSWAPLr R))
(define-function PUSHr (R) (if (_r4P R) (PUSHLr R) (if (_r2P R) (PUSHWr R) (ASMFAIL "illegal register size"))))
(define-function POPr (R) (if (_r4P R) (POPLr R) (if (_r2P R) (POPWr R) (ASMFAIL "illegal register size"))))

(define-function CALLQr (R) (let () (_REX 0 R 0 0) (CALLr (_r8 R))))
(define-function CALLQm (D B I S) (let () (_REX 0 0 I B) (CALLm D (_r8 B) (_r8 I) S)))
(define-function INCQr (R) (let () (_REX 1 0 0 R) (_O_Mrm 255 _b11 _b000 (_rN (_r8 R)))))
(define-function JMPQr (R) (let () (_REX 0 R 0 0) (JMPr (_r8 R))))
(define-function JMPQm (D B I S) (let () (_REX 0 0 I B) (JMPm D (_r8 B) (_r8 I) S)))
(define-function LEAQmr (D B I S R) (let () (_REX 1 R I B) (LEALmr D (_r8 B) (_r8 I) S (_r8 R))))
(define-function LEAVEQ () (LEAVE))

(define-function MOVSBQrr (S D) (let () (_REX 1 S 0 D) (MOVSBLrr S (_r8 D))))
(define-function MOVSBQmr (D B I S R) (let () (_REX 1 S 0 D) (MOVSBLmr D (_r8 B) (_r8 I) S (_r8 R))))
(define-function MOVZBQrr (S D) (let () (_REX 1 S 0 D) (MOVZBLrr S (_r8 D))))
(define-function MOVZBQmr (D B I S R) (let () (_REX 1 S 0 D) (MOVZBLmr D (_r8 B) (_r8 I) S (_r8 R))))
(define-function MULQrr (S D) (let () (_REX 1 S 0 D) (MULLrr (_r8 S) (_r8 D))))
(define-function MULQmr (D B I S RD) (let () (_REX 1 S 0 RD) (MULLmr D (_r8 B) (_r8 I) S (_r8 RD))))
(define-function DIVQrr (S D) (let () (_REX 1 S 0 D) (DIVLrr (_r8 S) (_r8 D))))
(define-function DIVQmr (D B I S RD) (let () (_REX 1 S 0 RD) (DIVLmr D (_r8 B) (_r8 I) S (_r8 RD))))
(define-function NEGQr (R) (let () (_REX 0 0 0 R) (NEGLr (_r8 R))))
(define-function NOTQr (R) (let () (_REX 0 0 0 R) (NOTLr (_r8 R))))
(define-function NOTQm (D B I S) (let () (_REX 1 S 0 0) (NOTLm D (_r8 B) (_r8 I) S)))
(define-function POPQr (R) (let () (_REX 0 0 0 R) (POPLr (_r8 R))))
(define-function PUSHQr (R) (let () (_REX 0 0 0 R) (PUSHLr (_r8 R))))
(define-function PUSHQi (L) (let () (_REX 1 0 0 0) (PUSHLi L)))
(define-function RETQ () (RET))
(define-function SALQir (L R) (let () (_REX 1 0 0 R) (SALLir L (_r8 R))))
(define-function SALQrr (S D) (let () (_REX 1 S 0 D) (SALLrr S (_r8 D))))
(define-function SALQim (L D B I S) (let () (_REX 1 0 I B) (SALLim L D (_r8 B) (_r8 I) S)))
(define-function SALQrm (R D B I S) (let () (_REX 1 R I B) (SALLrm R D (_r8 B) (_r8 I) S)))
(define-function SARQir (L R) (let () (_REX 1 0 0 R) (SARLir L (_r8 R))))
(define-function SARQrr (S D) (let () (_REX 1 S 0 D) (SARLrr S (_r8 D))))
(define-function SARQim (L D B I S) (let () (_REX 1 0 I B) (SARLim L D (_r8 B) (_r8 I) S)))
(define-function SARQrm (R D B I S) (let () (_REX 1 R I B) (SARLrm R D (_r8 B) (_r8 I) S)))
(define-function TESTQrr (S D) (let () (_REX 1 S 0 D) (TESTLrr (_r8 S) (_r8 D))))

(define-function INVD ()		(_OO 0x0f08))
(define-function SYSCALL ()		(_OO 0x0f05))

(define-function CBW ()			(_O 0x98))
(define-function CLC ()			(_O 0xf8))
(define-function CWD ()			(_O 0x99)) ; 16 bit mode
(define-function CDQ ()			(_O 0x99)) ; 32 bit mode, aka CLTD
(define-function CQO ()			(_O 0x99)) ; 64 bit mode
(define-function CMC ()			(_O 0xf5))
(define-function HLT ()			(_O 0xf4))

(define-function CMOVCCLirr (CC RS RD)	(_OO_Mrm (bitwise-or 0x0f40 CC) _b11 (_r4 RD) (_r4 RS)))
(define-function CMOVCCQirr (CC S D)	(_REX 1 S 0 D) (CMOVCCLirr CC (_r8 S) (_r8 D)))
(define-function CMOVEQrr (S D)		(CMOVCCQirr 4 S D))
(define-function CMOVZQrr (S D)		(CMOVCCQirr 4 S D))

(with-forms
    ((x (names
         (let ((index -1))
           `(begin
             ,@(map (lambda (name)
                      `(define-function ,name (RS RD)
                         (CMOVCCLirr ,(incr index) RS RD)))
                    names))))))
  (x
   CMOVOLrr		; 0
   CMOVNOLrr
   CMOVBLrr
   CMOVNAELrr
   CMOVNBLrr
   CMOVAELrr
   CMOVELrr
   CMOVZLrr
   CMOVNELrr
   CMOVNZLrr
   CMOVBELrr
   CMOVNALrr
   CMOVNBELrr
   CMOVALrr
   CMOVSLrr
   CMOVNSLrr
   CMOVPLrr
   CMOVPELrr
   CMOVNPLrr
   CMOVPOLrr
   CMOVLLrr
   CMOVNGELrr
   CMOVNLLrr
   CMOVGELrr
   CMOVLELrr
   CMOVNGLrr
   CMOVNLELrr
   CMOVGLrr		; 15
   ))

;; rel8 distance
(define-function JCCrel8 (CC D)
  (_O_D1 (bitwise-or 0x70 CC) D))

;; rel32 distance
(define-function JCCrel32 (CC D)
  (_OO_D4 (bitwise-or 0x0f80 CC) D))

(with-forms
    ((x (entries
         (let ((index -1))
           `(begin
             ,@(map
                (lambda (entry)
                  (let ((base-name (concat-symbol 'J (first entry))))
                    `(begin
                      (define-function ,(concat-symbol base-name 'S) (D)
                        (JCCrel8 ,(second entry) D))
                      (define-function ,(concat-symbols base-name (string->symbol "32")) (D)
                        (JCCrel32 ,(second entry) D))
                      (define-function ,base-name (D)
                        (if (_s1P D)
                            (JCCrel8 ,(second entry) D)
                          (JCCrel32 ,(second entry) D))))))
                entries))))))
  (x
   (O		00)
   (NO		01)
   (B		02)
   (NAE		02)
   (NB		03)
   (AE		03)
   (E		04)
   (Z		04)
   (NE		05)
   (NZ		05)
   (BE		06)
   (NA		06)
   (NBE		07)
   (A		07)
   (S		08)
   (NS		09)
   (P		10)
   (PE		10)
   (NP		11)
   (PO		11)
   (L		12)
   (NGE		12)
   (NL		13)
   (GE		13)
   (LE		14)
   (NG		14)
   (NLE		15)
   (G		15)))
