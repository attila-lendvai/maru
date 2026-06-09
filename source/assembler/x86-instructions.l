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

     ;; 32 bit mode regs
     (_AL 0x10)
     (_CL 0x11)
     (_DL 0x12)
     (_BL 0x13)

     (_AH 0x14)
     (_CH 0x15)
     (_DH 0x16)
     (_BH 0x17)

     (_AX 0x20)
     (_CX 0x21)
     (_DX 0x22)
     (_BX 0x23)
     (_SP 0x24)
     (_BP 0x25)
     (_SI 0x26)
     (_DI 0x27)

     (_EAX 0x40)
     (_ECX 0x41)
     (_EDX 0x42)
     (_EBX 0x43)
     (_ESP 0x44)
     (_EBP 0x45)
     (_ESI 0x46)
     (_EDI 0x47))

  ;; 64 bit mode regs
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

(define-function register-width-in-bytes (R)
  (bitwise-shift R -4))

(define-function register/8? (R)
  (= 1 (register-width-in-bytes R)))

(define-function register/16? (R)
  (= 2 (register-width-in-bytes R)))

(define-function register/32? (R)
  (= 4 (register-width-in-bytes R)))

(define-function register/64? (R)
  (= 8 (register-width-in-bytes R)))

(define-function undefined-register? (r)
  (= r 0))

(define-function undefined-registers? (r1 r2)
  (and (= 0 r1)
       (= 0 r2)))

;; register-index
(define-function rindex (R)
  (bitwise-and R 7))

;; (define-function _rLP (R)
;;   (and (>= R _AL)
;;        (<= R _BL)))

;; (define-function _rHP (R)
;;   (and (>= R _AH)
;;        (<= R _BH)))

;; (define-function _rL (R)
;;   (if (_rLP R)
;;       (rindex R)
;;     (ASMFAIL "8-bit L register required")))

;; (define-function _rH (R)
;;   (if (_rHP R)
;;       (rindex R)
;;     (ASMFAIL "8-bit H register required")))

(define-function rindex/8 (R)
  (assert (register/8? R) "8-bit register required")
  (rindex R))

(define-function rindex/16 (R)
  (assert (register/16? R) "16-bit register required")
  (rindex R))

(define-function rindex/32 (R)
  (if (register/32? R)
      (rindex R)
    (ASMFAIL "32-bit register required")))

(define-function rindex/64 (R)
  (if (register/64? R)
      (rindex R)
    (ASMFAIL "64-bit register required")))

(define-function to-r32 (R)
  (if (undefined-register? R)
      0
    (if (register/64? R)
        (+ 0x40 (rindex R))
      (ASMFAIL "64-bit register required"))))

(define-function rindex/AL (R)
  (assert (= R _AL) "AL register required")
  0)

(define-function rindex/AX (R)
  (assert (= R _AX) "AX register required")
  0)

(define-function rindex/EAX (R)
  (assert (= R _EAX) "EAX register required")
  0)

;;; IMMEDIATES

(define-function u8? (I)
  (= 0 (bitwise-and I -0x100)))

(define-function u16? (I)
  (= 0 (bitwise-and I -0x10000)))

;; TODO audit why this is needed. maybe this assert should be in _B?
;; but _B doesn't know whether it's signed or not. if i8? is to stay
;; then consider adding i32? and inserting it where needed.
(define-function i8? (I)
  (and (long? I)
       ;; -128 127
       (<= -0x80 I 0x7f)))

(define-function i16? (I)
  (and (long? I)
       ;; -32768 32767
       (<= -0x8000 I 0x7fff)))

(define-function i32? (I)
  (and (long? I)
       ;; -2147483648 2147483647
       (<= -0x80000000 I 0x7fffffff)))

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
  (emit-u8
   (bitwise-or (bitwise-shift (_mod mod) 6)
               (bitwise-shift (_reg reg) 3)
               (_rm rm))))

(define-function _SIB (Sc I B)
  (emit-u8
   (bitwise-or (bitwise-shift (_scale Sc) 6)
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
  (_Mrm _b00 (rindex R) _b101)
  (emit-rel32 D))

(define-function _r_0B (R B)
  (_Mrm _b00 (rindex R) (rindex/32 B)))

(define-function _r_0BIS (R B I S)
  (_Mrm _b00 (rindex R) _b100)
  (_SIB (_SCL S) (rindex/32 I) (rindex/32 B)))

(define-function _r_0DIS (R D I S)
  (_Mrm _b00 (rindex R) _b100)
  (_SIB (_SCL S) (rindex/32 I) 5)
  (emit-i32 D))

(define-function _r_1B (R D B)
  (_Mrm _b01 (rindex R) (rindex/32 B))
  (emit-i8 D))

(define-function _r_1BIS (R D B I S)
  (_Mrm _b01 (rindex R) _b100)
  (_SIB (_SCL S) (rindex/32 I) (rindex/32 B))
  (emit-i8 D))

(define-function _r_4B (R D B)
  (_Mrm _b10 (rindex R) (rindex/32 B))
  (emit-i32 D))

(define-function _r_4BIS (R D B I S)
  (_Mrm _b10 (rindex R) _b100)
  (_SIB (_SCL S) (rindex/32 I) (rindex/32 B))
  (emit-i32 D))

(define-function _r_DB (R D B)
  (cond
    ((zero? D)	(_r_0B R B))
    ((i8? D)	(_r_1B R D B))
    (else	(_r_4B R D B))))

(define-function _r_DBIS (R D B I S)
  (cond
    ((zero? D)	(_r_0BIS R B I S))
    ((i8? D)	(_r_1BIS R D B I S))
    (else	(_r_4BIS R D B I S))))

;; 32 bit version
;; (define-function _r_X (R D B I S)
;;   (if (undefined-register? I)
;;       (if (undefined-register? B)
;;           (_r_D R D)
;;         (if (= _ESP B)
;;             (_r_DBIS R D _ESP _ESP 1)
;;           (_r_DB R D B)))
;;     (if (undefined-register? B)
;;         (_r_0DIS R D I S)
;;       (if (!= I _ESP)
;;           (_r_DBIS R D B I S)
;;         (ASMFAIL "illegal index register: %esp")))))

;; 64 bit version
(define-function _r_X (R D B I S)
  (cond
    ((undefined-register? I)
     (cond
       ((undefined-register? B)	(_r_D R D))
       ((= _ESP B)		(_r_DBIS R D _ESP _ESP 1))
       (else			(_r_DB R D B))))
    ((undefined-register? B)
     (_r_0DIS R D I S))
    (else
     (_r_DBIS R D B I S))))

(define-function _rXP (R) (>= (bitwise-and R 0x0f) 8))

(define-function _REX (W R X B)
  (let ((value (+ (if (_rXP R) 4 0)
                  (if (_rXP X) 2 0)
                  (if (_rXP B) 1 0)
                  (bitwise-shift W 3))))
    (unless (= 0 value)
      (emit-u8 (+ 0x40 value)))))

;;;
;;; instruction formats
;;;

;; Naming Convention:
;;
;; O		 8 bit opcode
;; OO      	16 bit opcode
;; Os		opcode + b10 when imm fits imm8
;; Or		opcode + register
;; sW, sL	try short (imm8), revert to imm16 or imm32
;; X		dispatch on register, displ, base, index, scale and emit appropriate
;; imm		immediate value, usually postfixed with its size in bits
;; w prefix	emit with the 0x66 prefix; i.e. 16 bit operand size

(define-function _d16 ()
  (emit-u8 0x66))

(define-function _a32 (B I)
  (when (or (register/32? B)
            (register/32? I))
    (emit-u8 0x67)))

(define-function _O (OP)
  (emit-u8 OP))

(define-function _Or (OP R)
  (emit-u8 (bitwise-or OP (_reg R))))

(define-function _OO (OP)
  ;; NOTE this is big endian
  (emit-u8 (bitwise-shift OP -8))
  (emit-u8 (bitwise-and OP 0xff)))

(define-function _OOr (OP R)
  ;; NOTE this is big endian
  (emit-u8 (bitwise-shift OP -8))
  (emit-u8 (bitwise-or (bitwise-and OP 0xff) (_reg R))))

(define-function _Os (OP val)
  (if (and (long? val)
           (i8? val))
      (emit-u8 (bitwise-or OP _b10))
    (emit-u8 OP)))

;; TODO? rename to emit-i8-or-i16
(define-function _sW (W)
  (if (i8? W)
      (emit-i8 W)
    (emit-i16 W)))

;; TODO? rename to emit-i8-or-i32
(define-function _sL (L)
  (if (i8? L)
      (emit-i8 L)
    (emit-i32 L)))

(define-function _O_rel8 (OP D)
  (_O OP)
  (emit-rel8 D))

(define-function _O_rel32 (OP D)
  (_O OP)
  (emit-rel32 D))

(define-function _OO_rel32 (OP D)
  (_OO OP)
  (emit-rel32 D))

(define-function _Os_sW (OP W)
  (_Os OP W)
  (_sW W))

(define-function _Os_sL (OP L)
  (_Os OP L)
  (_sL L))

(define-function _O_Mrm (OP MO R M)
  (_O OP)
  (_Mrm MO R M))

(define-function _OO_Mrm (OP MO R M)
  (_OO OP)
  (_Mrm MO R M))

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

(define-function _Os_r_X_sW (OP R MD MB MI MS W)
  (_Os OP W)
  (_r_X R MD MB MI MS)
  (_sW W))

(define-function _Os_r_X_sL (OP R MD MB MI MS L)
  (_Os OP L)
  (_r_X R MD MB MI MS)
  (_sL L))

;; TODO add macrology for the _w prefix

(define-function _wO (OP)
  (_d16)
  (_O OP))

(define-function _wOr (OP R)
  (_d16)
  (_Or OP R))

(define-function _wOs_sW (OP W)
  (_d16)
  (_Os_sW OP W))

(define-function _wO_Mrm (OP MO R M)
  (_d16)
  (_O_Mrm OP MO R M))

(define-function _wOO_Mrm (OP MO R M)
  (_d16)
  (_OO_Mrm OP MO R M))

(define-function _wOs_Mrm_sW (OP MO R M W)
  (_d16)
  (_Os_Mrm_sW OP MO R M W))

(define-function _wO_r_X (OP R MD MB MI MS)
  (_d16)
  (_O_r_X OP R MD MB MI MS))

(define-function _wOO_r_X (OP R MD MB MI MS)
  (_d16)
  (_OO_r_X OP R MD MB MI MS))

(define-function _wOs_r_X_sW (OP R MD MB MI MS W)
  (_d16)
  (_Os_r_X_sW OP R MD MB MI MS W))

;;;
;;; ALU “Group 1” (the most regular class)
;;;

(define-form define-alu-instruction (base-name op reg)
  (with-forms ((name ((size suffix) `(concat-symbols base-name ',size ',suffix))))
    `(begin
      ;; 8 bit
      (define-function ,(name B rr)	(S D)				(_REX 0 S 0 D)	(_O_Mrm		,op		_b11 (rindex/8 S) (rindex/8 D))					)
      (define-function ,(name B ir)	(L R)				(_REX 0 0 0 R)	(_O_Mrm		0x80		_b11 ,reg (rindex/8 R))				(emit-i8 L)	)

      (define-function ,(name B mr)	(D B I S R)	(_a32 B I)	(_REX 0 R I B)	(_O_r_X		,(+ op 2)	(rindex/8 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name B rm)	(R D B I S)	(_a32 B I)	(_REX 0 R I B)	(_O_r_X		,op		(rindex/8 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name B im)	(L D B I S)	(_a32 B I)	(_REX 0 0 I B)	(_O_r_X		0x80		,reg		D (to-r32 B) (to-r32 I) S)	(emit-i8 L)	)

      ;; 16 bit
      (define-function ,(name W rr)	(S D)			  (_d16)(_REX 0 S 0 D)	(_O_Mrm		,(+ op 1)	_b11 (rindex/16 S) (rindex/16 D))				)
      (define-function ,(name W i8r)	(L R)			  (_d16)(_REX 0 0 0 R)	(_O_Mrm		0x83		_b11 ,reg (rindex/16 R))			(emit-i8 L)	)
      (define-function ,(name W i16r)	(L R)			  (_d16)(_REX 0 0 0 R)	(_O_Mrm		0x81		_b11 ,reg (rindex/16 R))			(emit-i16 L)	)
      (define-function ,(name W mr)	(D B I S R)	(_a32 B I)(_d16)(_REX 0 R I B)	(_O_r_X		,(+ op 3)	(rindex/16 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name W rm)	(R D B I S)	(_a32 B I)(_d16)(_REX 0 R I B)	(_O_r_X		,(+ op 1)	(rindex/16 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name W i8m)	(L D B I S)	(_a32 B I)(_d16)(_REX 0 0 I B)	(_O_r_X		0x83		,reg		D (to-r32 B) (to-r32 I) S)	(emit-i8 L)	)
      (define-function ,(name W i16m)	(L D B I S)	(_a32 B I)(_d16)(_REX 0 0 I B)	(_O_r_X		0x81		,reg		D (to-r32 B) (to-r32 I) S)	(emit-i16 L)	)

      ;; 32 bit
      (define-function ,(name L rr)	(S D)				(_REX 0 S 0 D)	(_O_Mrm		,(+ op 1)	_b11 (rindex/32 S) (rindex/32 D))				)
      (define-function ,(name L i8r)	(L R)				(_REX 0 0 0 R)	(_O_Mrm		0x83		_b11 ,reg (rindex/32 R))			(emit-i8 L)	)
      (define-function ,(name L i32r)	(L R)				(_REX 0 0 0 R)	(_O_Mrm		0x81		_b11 ,reg (rindex/32 R))			(emit-i32 L)	)
      (define-function ,(name L mr)	(D B I S R)	(_a32 B I)	(_REX 0 R I B)	(_O_r_X		,(+ op 3)	(rindex/32 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name L rm)	(R D B I S)	(_a32 B I)	(_REX 0 R I B)	(_O_r_X		,(+ op 1)	(rindex/32 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name L i8m)	(L D B I S)	(_a32 B I)	(_REX 0 0 I B)	(_O_r_X		0x83		,reg		D (to-r32 B) (to-r32 I) S)	(emit-i8 L)	)
      (define-function ,(name L i32m)	(L D B I S)	(_a32 B I)	(_REX 0 0 I B)	(_O_r_X		0x81		,reg		D (to-r32 B) (to-r32 I) S)	(emit-i32 L)	)

      (define-function ,(name L ir) (L R)		((if (i8? L) ,(name L i8r) ,(name L i32r)) L R))
      (define-function ,(name L im) (L D B I S)		((if (i8? L) ,(name L i8m) ,(name L i32m)) L D B I S))

      ;; TODO the 64 bit version is the same as the 32 bit one, except:
      ;; - REX.W=1
      ;; - for R S D registers: rindex/64 instead of rindex/32
      (define-function ,(name Q rr)	(S D)				(_REX 1 S 0 D)	(_O_Mrm		,(+ op 1)	_b11 (rindex/64 S) (rindex/64 D))				)
      (define-function ,(name Q i8r)	(L R)				(_REX 1 0 0 R)	(_O_Mrm		0x83		_b11 ,reg (rindex/64 R))			(emit-i8 L)	)
      (define-function ,(name Q i32r)	(L R)				(_REX 1 0 0 R)	(_O_Mrm		0x81		_b11 ,reg (rindex/64 R))			(emit-i32 L)	)
      (define-function ,(name Q mr)	(D B I S R)	(_a32 B I)	(_REX 1 R I B)	(_O_r_X		,(+ op 3)	(rindex/64 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name Q rm)	(R D B I S)	(_a32 B I)	(_REX 1 R I B)	(_O_r_X		,(+ op 1)	(rindex/64 R)	D (to-r32 B) (to-r32 I) S)			)
      (define-function ,(name Q i8m)	(L D B I S)	(_a32 B I)	(_REX 1 0 I B)	(_O_r_X		0x83		,reg		D (to-r32 B) (to-r32 I) S)	(emit-i8 L)	)
      (define-function ,(name Q i32m)	(L D B I S)	(_a32 B I)	(_REX 1 0 I B)	(_O_r_X		0x81		,reg		D (to-r32 B) (to-r32 I) S)	(emit-i32 L)	)

      (define-function ,(name Q ir) (L R)		((if (i8? L) ,(name Q i8r) ,(name Q i32r)) L R))
      (define-function ,(name Q im) (L D B I S)		((if (i8? L) ,(name Q i8m) ,(name Q i32m)) L D B I S))

      )))

(define-alu-instruction ADD 0x00 _b000)
(define-alu-instruction OR  0x08 _b001)
(define-alu-instruction ADC 0x10 _b010)
(define-alu-instruction SBB 0x18 _b011)
(define-alu-instruction AND 0x20 _b100)
(define-alu-instruction SUB 0x28 _b101)
(define-alu-instruction XOR 0x30 _b110)
(define-alu-instruction CMP 0x38 _b111)

;;;
;;; Group 3 (unary)
;;;

;; The /n field selects the operation:
;; /0	TEST (imm)	test r/m with immediate
;; /1	undefined
;; /2	NOT	bitwise NOT
;; /3	NEG	two’s complement
;; /4	MUL	unsigned multiply (implicit regs)
;; /5	IMUL	signed multiply (implicit regs)
;; /6	DIV	unsigned divide
;; /7	IDIV	signed divide

;; TODO finish formatting, identify patterns, then macroify the entire group

(define-function NEGBr (R)		(_O_Mrm  0xf6 _b11	_b011	(rindex/8 R)))
(define-function NEGBm (D B I S)	(_O_r_X  0xf6 		_b011	D B I S))
(define-function NEGWr (R)		(_wO_Mrm 0xf7 _b11	_b011	(rindex/16 R)))
(define-function NEGWm (D B I S)	(_wO_r_X 0xf7		_b011	D B I S))
(define-function NEGLr (R)		(_O_Mrm  0xf7 _b11	_b011	(rindex/32 R)))
(define-function NEGLm (D B I S)	(_O_r_X  0xf7		_b011	D B I S))
(define-function NEGQr (R)		(_REX 1 0 0 R) (NEGLr (to-r32 R)))
(define-function NEGQm (D B I S)	(_REX 1 S I B) (NEGLm D (to-r32 B) (to-r32 I) S))

(define-function NOTBr (R)		(_O_Mrm  0xf6 _b11	_b010	(rindex/8 R)))
(define-function NOTBm (D B I S)	(_O_r_X  0xf6		_b010	D B I S))
(define-function NOTWr (R)		(_wO_Mrm 0xf7 _b11	_b010	(rindex/16 R)))
(define-function NOTWm (D B I S)	(_wO_r_X 0xf7		_b010	D B I S))
(define-function NOTLr (R)		(_O_Mrm  0xf7 _b11	_b010	(rindex/32 R)))
(define-function NOTLm (D B I S)	(_O_r_X  0xf7		_b010	D B I S))
(define-function NOTQr (R)		(_REX 1 0 0 R) (NOTLr (to-r32 R)))
(define-function NOTQm (D B I S)	(_REX 1 S I B) (NOTLm D (to-r32 B) (to-r32 I) S))

(define-function DIVBrr (RS RD)		(rindex/AL RD)	(_O_Mrm  0xf6 _b11	_b110	(rindex/8 RS)))
(define-function DIVBmr (D B I S R)	(rindex/AL R)	(_O_r_X  0xf6		_b110	D B I S))
(define-function DIVWrr (RS RD)		(rindex/AX RD)	(_wO_Mrm 0xf7 _b11	_b110	(rindex/16 RS)))
(define-function DIVWmr (D B I S R)	(rindex/AX R)	(_wO_r_X 0xf7		_b110	D B I S))
(define-function DIVLrr (RS RD)		(rindex/EAX RD)	(_O_Mrm  0xf7 _b11	_b110	(rindex/32 RS)))
(define-function DIVLmr (D B I S R)	(rindex/EAX R)	(_O_r_X  0xf7		_b110	D B I S))
(define-function DIVQrr (RS RD)		(_REX 1 RS 0 RD)(DIVLrr (to-r32 RS) (to-r32 RD)))
(define-function DIVQmr (D B I S R)	(_REX 1 S 0 R)	(DIVLmr D (to-r32 B) (to-r32 I) S (to-r32 R)))

(define-function IDIVBrr (RS RD)		(rindex/AL RD)	(_O_Mrm 0xf6 _b11	_b111	(rindex/8 RS)))
(define-function IDIVBmr (D B I S R)		(rindex/AL R)	(_O_r_X 0xf6		_b111	D B I S))
(define-function IDIVWrr (RS RD)		(rindex/AX RD)	(_wO_Mrm 0xf7 _b11	_b111	(rindex/16 RS)))
(define-function IDIVWmr (D B I S R)		(rindex/AX R)	(_wO_r_X 0xf7		_b111	D B I S))
(define-function IDIVLrr (RS RD)		(rindex/EAX RD)	(_O_Mrm 0xf7 _b11	_b111	(rindex/32 RS)))
(define-function IDIVLmr (D B I S R)		(rindex/EAX R)	(_O_r_X 0xf7		_b111	D B I S))

(define-function MULBrr (RS RD)			(rindex/AL RD)	(_O_Mrm  0xf6 _b11 _b100	(rindex/8 RS)))
(define-function MULBmr (D B I S R)		(rindex/AL R)	(_O_r_X  0xf6 _b100		D B I S))
(define-function MULWrr (RS RD)			(rindex/AX RD)	(_wO_Mrm 0xf7 _b11 _b100	(rindex/16 RS)))
(define-function MULWmr (D B I S R)		(rindex/AX R)	(_wO_r_X 0xf7 _b100		D B I S))
(define-function MULLrr (RS RD)			(rindex/EAX RD)	(_O_Mrm  0xf7 _b11 _b100	(rindex/32 RS)))
(define-function MULLmr (D B I S R)		(rindex/EAX R)	(_O_r_X  0xf7 _b100		D B I S))
(define-function MULQrr (S D)			(_REX 1 S 0 D)	(MULLrr (to-r32 S) (to-r32 D)))
(define-function MULQmr (D B I S R)		(_REX 1 S 0 R)	(MULLmr D (to-r32 B) (to-r32 I) S (to-r32 R)))

(define-function IMULWrr  (RS RD)		(_wOO_Mrm    0xfaf _b11	(rindex/16 RD) (rindex/16 RS)))
(define-function IMULWmr  (D B I S R)		(_wOO_r_X    0xfaf	(rindex/16 R) D B I S))
(define-function IMULWirr (L RS RD)		(_wOs_Mrm_sW 0x69  _b11	(rindex/16 RD) (rindex/16 RS) L))
(define-function IMULWimr (L D B I S R)		(_wOs_r_X_sW 0x69	(rindex/16 R) D B I S L))
(define-function IMULLrr  (RS RD)		(_OO_Mrm     0xfaf _b11	(rindex/32 RD) (rindex/32 RS)))
(define-function IMULLmr  (D B I S R)		(_OO_r_X     0xfaf	(rindex/32 R) D B I S))
(define-function IMULLirr (L RS RD)		(_Os_Mrm_sL  0x69  _b11	(rindex/32 RD) (rindex/32 RS) L))
(define-function IMULLimr (L D B I S R)		(_Os_r_X_sL  0x69	(rindex/32 R) D B I S L))

(define-function TESTBrr (RS RD)	(_O_Mrm    0x84 _b11		(rindex/8 RS) (rindex/8 RD)))
(define-function TESTBrm (R D B I S)	(_O_r_X    0x84			(rindex/8 R) D B I S))
(define-function TESTBir (L R)		(_O_Mrm    0xf6 _b11	_b000	(rindex/8 R)) (emit-u8 L))
(define-function TESTBim (L D B I S)	(_O_r_X    0xf6		_b000	D B I S) (emit-u8 L))
(define-function TESTWrr (RS RD)	(_wO_Mrm   0x85 _b11		(rindex/16 RS) (rindex/16 RD)))
(define-function TESTWrm (R D B I S)	(_wO_r_X   0x85			(rindex/16 S) D B I S))
(define-function TESTWir (L R)		(_wO_Mrm   0xf7 _b11	_b000	(rindex/16 R)) (emit-u16 L))
(define-function TESTWim (L D B I S)	(_wO_r_X   0xf7		_b000	D B I S) (emit-u16 L))
(define-function TESTLrr (RS RD)	(_O_Mrm    0x85 _b11		(rindex/32 RS) (rindex/32 RD)))
(define-function TESTLrm (R D B I S)	(_O_r_X    0x85			(rindex/32 R) D B I S))
(define-function TESTLir (L R)		(_O_Mrm    0xf7 _b11	_b000	(rindex/32 R)) (emit-i32 L))
(define-function TESTLim (L D B I S)	(_O_r_X    0xf7		_b000	D B I S) (emit-i32 L))
(define-function TESTQrr (S D)		(_REX 1 S 0 D) (TESTLrr (to-r32 S) (to-r32 D)))
;; TODO missing Q variants

;;;
;;; MOV
;;;

(define-function MOVBrr (S D)					(_REX 0 S 0 D)	(_O_Mrm 0x88 _b11 (rindex/8 S) (rindex/8 D)))
(define-function MOVBir (L R)					(_REX 0 0 0 R)	(_Or    0xb0	(rindex/8 R))					(emit-i8 L))
(define-function MOVBmr (D B I S R)	(_a32 B I)		(_REX 0 R I B)	(_O_r_X 0x8a	(rindex/8 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVBrm (R D B I S)	(_a32 B I)		(_REX 0 R I B)	(_O_r_X 0x88	(rindex/8 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVBim (L D B I S)	(_a32 B I)		(_REX 0 0 I B)	(_O_r_X 0xc6		   0	D (to-r32 B) (to-r32 I) S)	(emit-i8 L))

(define-function MOVWrr (S D)				(_d16)	(_REX 0 S 0 D)	(_O_Mrm 0x89 _b11 (rindex/16 S) (rindex/16 D)))
(define-function MOVWir (L R)				(_d16)	(_REX 0 0 0 R)	(_Or    0xb8	(rindex/16 R))					(emit-i16 L))
(define-function MOVWmr (D B I S R)	(_a32 B I)	(_d16)	(_REX 0 R I B)	(_O_r_X 0x8b	(rindex/16 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVWrm (R D B I S)	(_a32 B I)	(_d16)	(_REX 0 R I B)	(_O_r_X 0x89	(rindex/16 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVWim (L D B I S)	(_a32 B I)	(_d16)	(_REX 0 0 I B)	(_O_r_X 0xc7		    0	D (to-r32 B) (to-r32 I) S)	(emit-i16 L))

(define-function MOVLrr (S D)					(_REX 0 S 0 D)	(_O_Mrm 0x89 _b11 (rindex/32 S) (rindex/32 D)))
(define-function MOVLir (L R)					(_REX 0 0 0 R)	(_Or    0xb8	(rindex/32 R))					(emit-i32 L))
(define-function MOVLmr (D B I S R)	(_a32 B I)		(_REX 0 R I B)	(_O_r_X 0x8b	(rindex/32 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVLrm (R D B I S)	(_a32 B I)		(_REX 0 R I B)	(_O_r_X 0x89	(rindex/32 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVLim (L D B I S)	(_a32 B I)		(_REX 0 0 I B)	(_O_r_X 0xc7		    0	D (to-r32 B) (to-r32 I) S)	(emit-i32 L))

(define-function MOVQrr (S D)					(_REX 1 S 0 D)	(MOVLrr (to-r32 S) (to-r32 D)))
(define-function MOVQi32r (L R)					(_REX 1 0 0 R)	(_O_Mrm	0xc7 _b11 0 (rindex (to-r32 R)))			(emit-i32 L))
(define-function MOVQi64r (L R)					(_REX 1 0 0 R)	(_Or	0xb8	(rindex (to-r32 R)))				(emit-i64 L))
(define-function MOVQmr (D B I S R)	(_a32 B I)		(_REX 1 R I B)	(_O_r_X 0x8b	(to-r32 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVQrm (R D B I S)	(_a32 B I)		(_REX 1 R I B)	(_O_r_X 0x89	(to-r32 R)	D (to-r32 B) (to-r32 I) S))
(define-function MOVQim (L D B I S)	(_a32 B I)		(_REX 1 0 I B)	(_O_r_X 0xc7	 0		D (to-r32 B) (to-r32 I) S)	(emit-i32 L))

(define-function MOVQir (L R)
  (if (i32? L)
      (MOVQi32r L R)
    (MOVQi64r L R)))

(define-function BTWir (IM RD)			(_wOO_Mrm 4026 _b11 _b100 (rindex/16 RD))	(emit-u8 IM))
(define-function BTWim (IM MD MB MI MS)		(_wOO_r_X 4026 _b100 MD MB MI MS)		(emit-u8 IM))
(define-function BTWrr (RS RD)			(_wOO_Mrm 4003 _b11	(rindex/16 RS) (rindex/16 RD)))
(define-function BTWrm (RS MD MB MI MS)		(_wOO_r_X 4003		(rindex/16 RS) MD MB MI MS))
(define-function BTLir (IM RD)			(_OO_Mrm  4026 _b11 _b100 (rindex/32 RD))	(emit-u8 IM))
(define-function BTLim (IM MD MB MI MS)		(_OO_r_X  4026 _b100 MD MB MI MS)		(emit-u8 IM))
(define-function BTLrr (RS RD)			(_OO_Mrm  4003 _b11	(rindex/32 RS) (rindex/32 RD)))
(define-function BTLrm (RS MD MB MI MS)		(_OO_r_X  4003		(rindex/32 RS) MD MB MI MS))
(define-function BTCWir (IM RD)			(_wOO_Mrm 4026 _b11 _b111 (rindex/16 RD))	(emit-u8 IM))
(define-function BTCWim (IM MD MB MI MS)	(_wOO_r_X 4026 _b111 MD MB MI MS) (emit-u8 IM))
(define-function BTCWrr (RS RD)			(_wOO_Mrm 4027 _b11	(rindex/16 RS) (rindex/16 RD)))
(define-function BTCWrm (RS MD MB MI MS)	(_wOO_r_X 4027		(rindex/16 RS) MD MB MI MS))
(define-function BTCLir (IM RD)			(_OO_Mrm  4026 _b11 _b111 (rindex/32 RD))	(emit-u8 IM))
(define-function BTCLim (IM MD MB MI MS)	(_OO_r_X  4026 _b111 MD MB MI MS)		(emit-u8 IM))
(define-function BTCLrr (RS RD)			(_OO_Mrm  4027 _b11	(rindex/32 RS) (rindex/32 RD)))
(define-function BTCLrm (RS MD MB MI MS)	(_OO_r_X  4027		(rindex/32 RS) MD MB MI MS))
(define-function BTRWir (IM RD)			(_wOO_Mrm 4026 _b11 _b110 (rindex/16 RD))	(emit-u8 IM))
(define-function BTRWim (IM MD MB MI MS)	(_wOO_r_X 4026 _b110 MD MB MI MS)		(emit-u8 IM))
(define-function BTRWrr (RS RD)			(_wOO_Mrm 4019 _b11	(rindex/16 RS) (rindex/16 RD)))
(define-function BTRWrm (RS MD MB MI MS)	(_wOO_r_X 4019		(rindex/16 RS) MD MB MI MS))
(define-function BTRLir (IM RD)			(_OO_Mrm  4026 _b11 _b110 (rindex/32 RD))	(emit-u8 IM))
(define-function BTRLim (IM MD MB MI MS)	(_OO_r_X  4026 _b110 MD MB MI MS)		(emit-u8 IM))
(define-function BTRLrr (RS RD)			(_OO_Mrm  4019 _b11	(rindex/32 RS) (rindex/32 RD)))
(define-function BTRLrm (RS MD MB MI MS)	(_OO_r_X  4019		(rindex/32 RS) MD MB MI MS))
(define-function BTSWir (IM RD)			(_wOO_Mrm 4026 _b11 _b101 (rindex/16 RD))	(emit-u8 IM))
(define-function BTSWim (IM MD MB MI MS)	(_wOO_r_X 4026 _b101 MD MB MI MS)		(emit-u8 IM))
(define-function BTSWrr (RS RD)			(_wOO_Mrm 4011 _b11	(rindex/16 RS) (rindex/16 RD)))
(define-function BTSWrm (RS MD MB MI MS)	(_wOO_r_X 4011		(rindex/16 RS) MD MB MI MS))
(define-function BTSLir (IM RD)			(_OO_Mrm  4026 _b11 _b101 (rindex/32 RD))	(emit-u8 IM))
(define-function BTSLim (IM MD MB MI MS)	(_OO_r_X  4026 _b101 MD MB MI MS)		(emit-u8 IM))
(define-function BTSLrr (RS RD)			(_OO_Mrm  4011 _b11	(rindex/32 RS) (rindex/32 RD)))
(define-function BTSLrm (RS MD MB MI MS)	(_OO_r_X  4011		(rindex/32 RS) MD MB MI MS))

(define-function BSWAPLr (R)			(_OOr 0x0fc8 (rindex/32 R)))
(define-function CALLr (RD)			(_O_Mrm 255 _b11 _b010 (rindex/32 RD)))
(define-function CALLm (MD MB MI MS)		(if (undefined-registers? MB MI) (_O_rel32 232 MD) (_O_r_X 255 _b010 MD MB MI MS)))
(define-function CMPXCHGBrr (RS RD)		(_OO_Mrm 4016 _b11 (rindex/8 RS) (rindex/8 RD)))
(define-function CMPXCHGBrm (RS MD MB MI MS)	(_OO_r_X 4016 (rindex/8 RS) MD MB MI MS))
(define-function CMPXCHGWrr (RS RD)		(_wOO_Mrm 4017 _b11 (rindex/16 RS) (rindex/16 RD)))
(define-function CMPXCHGWrm (RS MD MB MI MS)	(_wOO_r_X 4017 (rindex/16 RS) MD MB MI MS))
(define-function CMPXCHGLrr (RS RD)		(_OO_Mrm 4017 _b11 (rindex/32 RS) (rindex/32 RD)))
(define-function CMPXCHGLrm (RS MD MB MI MS)	(_OO_r_X 4017 (rindex/32 RS) MD MB MI MS))
(define-function DECBr (RD)			(_O_Mrm 254 _b11 _b001 (rindex/8 RD)))
(define-function DECBm (MD MB MI MS)		(_O_r_X 254 _b001 MD MB MI MS))
(define-function DECWr (RD)			(_wOr 72 (rindex/16 RD)))
(define-function DECWm (MD MB MI MS)		(_wO_r_X 255 _b001 MD MB MI MS))
(define-function DECLr (RD)			(_O_Mrm 255 _b11 _b001 (rindex/32 RD)))
(define-function DECLm (MD MB MI MS)		(_O_r_X 255 _b001 MD MB MI MS))

(define-function ENTERii (W B)			(_O 200) (emit-i16 W) (emit-i8 B))

(define-function INCBr (RD)			(_O_Mrm 254 _b11 _b000 (rindex/8 RD)))
(define-function INCBm (MD MB MI MS)		(_O_r_X 254 _b000 MD MB MI MS))
(define-function INCWr (RD)			(_wOr 64 (rindex/16 RD)))
(define-function INCWm (MD MB MI MS)		(_wO_r_X 255 _b000 MD MB MI MS))
(define-function INCLr (RD)			(_O_Mrm 255 _b11 _b000 (rindex/32 RD)))
(define-function INCLm (MD MB MI MS)		(_O_r_X 255 _b000 MD MB MI MS))
(define-function INVLPGm (MD MB MI MS)		(_OO_r_X 3841 _b111 MD MB MI MS))

(define-function JMPSm (D B I S)		(if (undefined-registers? B I) (_O_rel8  235 D) (ASMFAIL "illegal mode in short jump")))
(define-function JMPm (D B I S)			(if (undefined-registers? B I) (_O_rel32 233 D) (_O_r_X 255 _b100 D B I S)))
(define-function JMPr (R)			(_O_Mrm 255 _b11 _b100 (rindex/32 R)))
(define-function LAHF () (_O 159))
(define-function LEALmr (MD MB MI MS RD) (_O_r_X 141 (rindex/32 RD) MD MB MI MS))
(define-function LEAVE () (_O 201))
(define-function LMSWr (RS) (_OO_Mrm 3841 _b11 _b110 (rindex/32 RS)))
(define-function LMSWm (MD MB MI MS) (_OO_r_X 3841 _b110 MD MB MI MS))
(define-function LOOPm (MD MB MI MS)   (if (undefined-registers? MB MI) (_O_rel8 226 MD) (ASMFAIL "illegal mode in loop")))
(define-function LOOPEm (MD MB MI MS)  (if (undefined-registers? MB MI) (_O_rel8 225 MD) (ASMFAIL "illegal mode in loope")))
(define-function LOOPZm (MD MB MI MS)  (if (undefined-registers? MB MI) (_O_rel8 225 MD) (ASMFAIL "illegal mode in loopz")))
(define-function LOOPNEm (MD MB MI MS) (if (undefined-registers? MB MI) (_O_rel8 224 MD) (ASMFAIL "illegal mode in loopne")))
(define-function LOOPNZm (MD MB MI MS) (if (undefined-registers? MB MI) (_O_rel8 224 MD) (ASMFAIL "illegal mode in loopnz")))
(define-function MOVSBLrr (RS RD) (_OO_Mrm 4030 _b11 (rindex/32 RD) (rindex/8 RS)))
(define-function MOVSBLmr (MD MB MI MS RD) (_OO_r_X 4030 (rindex/32 RD) MD MB MI MS))
(define-function MOVZBLmr (MD MB MI MS RD) (_OO_r_X 4022 (rindex/32 RD) MD MB MI MS))
(define-function MOVZBLrr (RS RD) (_OO_Mrm 4022 _b11 (rindex/32 RD) (rindex/8 RS)))
(define-function NOP () (_O 144))

(define-function POPWr (RD) (_wOr 88 (rindex/16 RD)))
(define-function POPWm (MD MB MI MS) (_wO_r_X 143 _b000 MD MB MI MS))
(define-function POPLr (RD) (_Or 88 (rindex/32 RD)))
(define-function POPLm (MD MB MI MS) (_O_r_X 143 _b000 MD MB MI MS))
(define-function POPA () (_wO 97))
(define-function POPAD () (_O 97))
(define-function POPF () (_wO 157))
(define-function POPFD () (_O 157))
(define-function PUSHWr (R) (_wOr 80 (rindex/16 R)))
(define-function PUSHWm (MD MB MI MS) (_wO_r_X 255 _b110 MD MB MI MS))
(define-function PUSHWi (IM) (_wOs_sW 104 IM))
(define-function PUSHLr (R) (_Or 80 (rindex/32 R)))
(define-function PUSHLm (MD MB MI MS) (_O_r_X 255 _b110 MD MB MI MS))
(define-function PUSHLi (IM) (_Os_sL 104 IM))
(define-function PUSHA () (_wO 96))
(define-function PUSHAD () (_O 96))
(define-function PUSHF () (_O 156))
(define-function PUSHFD () (_wO 156))
(define-function RET () (_O 195))
(define-function RETi (IM) (_O 194) (emit-i16 IM))
(define-function ROLBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b000 (rindex/8 RD)) (_O_Mrm 192 _b11 _b000 (rindex/8 RD)) (emit-u8 IM)))
(define-function ROLBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b000 MD MB MI MS) (_O_r_X 192 _b000 MD MB MI MS) (emit-u8 IM)))
(define-function ROLBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b000 (rindex/8 RD)) (ASMFAIL "source register must be CL")))
(define-function ROLBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b000 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function ROLWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b000 (rindex/16 RD)) (_wO_Mrm 193 _b11 _b000 (rindex/16 RD)) (emit-u8 IM)))
(define-function ROLWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b000 MD MB MI MS) (_wO_r_X 193 _b000 MD MB MI MS) (emit-u8 IM)))
(define-function ROLWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b000 (rindex/16 RD)) (ASMFAIL "source register must be CL")))
(define-function ROLWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b000 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function ROLLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b000 (rindex/32 RD)) (_O_Mrm 193 _b11 _b000 (rindex/32 RD)) (emit-u8 IM)))
(define-function ROLLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b000 MD MB MI MS) (_O_r_X 193 _b000 MD MB MI MS) (emit-u8 IM)))
(define-function ROLLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b000 (rindex/32 RD)) (ASMFAIL "source register must be CL")))
(define-function ROLLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b000 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function RORBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b001 (rindex/8 RD)) (_O_Mrm 192 _b11 _b001 (rindex/8 RD)) (emit-u8 IM)))
(define-function RORBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b001 MD MB MI MS) (_O_r_X 192 _b001 MD MB MI MS) (emit-u8 IM)))
(define-function RORBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b001 (rindex/8 RD)) (ASMFAIL "source register must be CL")))
(define-function RORBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b001 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function RORWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b001 (rindex/16 RD)) (_wO_Mrm 193 _b11 _b001 (rindex/16 RD)) (emit-u8 IM)))
(define-function RORWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b001 MD MB MI MS) (_wO_r_X 193 _b001 MD MB MI MS) (emit-u8 IM)))
(define-function RORWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b001 (rindex/16 RD)) (ASMFAIL "source register must be CL")))
(define-function RORWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b001 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function RORLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b001 (rindex/32 RD)) (_O_Mrm 193 _b11 _b001 (rindex/32 RD)) (emit-u8 IM)))
(define-function RORLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b001 MD MB MI MS) (_O_r_X 193 _b001 MD MB MI MS) (emit-u8 IM)))
(define-function RORLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b001 (rindex/32 RD)) (ASMFAIL "source register must be CL")))
(define-function RORLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b001 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SAHF () (_O 158))
(define-function SARBir (IM RD) (if (= IM 1) (_O_Mrm 208 _b11 _b111 (rindex/8 RD)) (_O_Mrm 192 _b11 _b111 (rindex/8 RD)) (emit-u8 IM)))
(define-function SARBim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 208 _b111 MD MB MI MS) (_O_r_X 192 _b111 MD MB MI MS) (emit-u8 IM)))
(define-function SARBrr (RS RD) (if (= RS _CL) (_O_Mrm 210 _b11 _b111 (rindex/8 RD)) (ASMFAIL "source register must be CL")))
(define-function SARBrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 210 _b111 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SARWir (IM RD) (if (= IM 1) (_wO_Mrm 209 _b11 _b111 (rindex/16 RD)) (_wO_Mrm 193 _b11 _b111 (rindex/16 RD)) (emit-u8 IM)))
(define-function SARWim (IM MD MB MS MI) (if (= IM 1) (_wO_r_X 209 _b111 MD MB MI MS) (_wO_r_X 193 _b111 MD MB MI MS) (emit-u8 IM)))
(define-function SARWrr (RS RD) (if (= RS _CL) (_wO_Mrm 211 _b11 _b111 (rindex/16 RD)) (ASMFAIL "source register must be CL")))
(define-function SARWrm (RS MD MB MS MI) (if (= RS _CL) (_wO_r_X 211 _b111 MD MB MI MS) (ASMFAIL "source register must be CL")))
(define-function SARLir (IM RD) (if (= IM 1) (_O_Mrm 209 _b11 _b111 (rindex/32 RD)) (_O_Mrm 193 _b11 _b111 (rindex/32 RD)) (emit-u8 IM)))
(define-function SARLim (IM MD MB MS MI) (if (= IM 1) (_O_r_X 209 _b111 MD MB MI MS) (_O_r_X 193 _b111 MD MB MI MS) (emit-u8 IM)))
(define-function SARLrr (RS RD) (if (= RS _CL) (_O_Mrm 211 _b11 _b111 (rindex/32 RD)) (ASMFAIL "source register must be CL")))
(define-function SARLrm (RS MD MB MS MI) (if (= RS _CL) (_O_r_X 211 _b111 MD MB MI MS) (ASMFAIL "source register must be CL")))

(define-function SETCCir (CC RD) (_OO_Mrm (bitwise-or 3984 CC) _b11 _b000 (rindex/8 RD)))
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

(define-function SHLBir (L RD)			(if (= L 1)	(_O_Mrm  0xd0 _b11 _b100 (rindex/8 RD))		(_O_Mrm  0xc0 _b11 _b100 (rindex/8 RD)) (emit-u8 L)))
(define-function SHLBim (L D B I S)		(if (= L 1)	(_O_r_X  0xd0 _b100 D B I S)			(_O_r_X  0xc0 _b100 D B I S) (emit-u8 L)))
(define-function SHLBrr (RS RD)			(if (= RS _CL)	(_O_Mrm  0xd2 _b11 _b100 (rindex/8 RD))		(ASMFAIL "source register must be CL")))
(define-function SHLBrm (RS D B I S)		(if (= RS _CL)	(_O_r_X  0xd2 _b100 D B I S)			(ASMFAIL "source register must be CL")))
(define-function SHLWir (L RD)			(if (= L 1)	(_wO_Mrm 0xd1 _b11 _b100 (rindex/16 RD))	(_wO_Mrm 0xc1 _b11 _b100 (rindex/16 RD)) (emit-u8 L)))
(define-function SHLWim (L D B I S)		(if (= L 1)	(_wO_r_X 0xd1 _b100 D B I S)			(_wO_r_X 0xc1 _b100 D B I S) (emit-u8 L)))
(define-function SHLWrr (RS RD)			(if (= RS _CL)	(_wO_Mrm 0xd3 _b11 _b100 (rindex/16 RD))	(ASMFAIL "source register must be CL")))
(define-function SHLWrm (RS D B I S)		(if (= RS _CL)	(_wO_r_X 0xd3 _b100 D B I S)			(ASMFAIL "source register must be CL")))
(define-function SHLLir (L RD)			(if (= L 1)	(_O_Mrm  0xd1 _b11 _b100 (rindex/32 RD))	(_O_Mrm  0xc1 _b11 _b100 (rindex/32 RD)) (emit-u8 L)))
(define-function SHLLim (L D B I S)		(if (= L 1)	(_O_r_X  0xd1 _b100 D B I S)			(_O_r_X  0xc1 _b100 D B I S) (emit-u8 L)))
(define-function SHLLrr (RS RD)			(if (= RS _CL)	(_O_Mrm  0xd3 _b11 _b100 (rindex/32 RD))	(ASMFAIL "source register must be CL")))
(define-function SHLLrm (RS D B I S)		(if (= RS _CL)	(_O_r_X  0xd3 _b100 D B I S)			(ASMFAIL "source register must be CL")))

(define-function SHRBir (L RD)			(if (= L 1)	(_O_Mrm  0xd0 _b11 _b101 (rindex/8 RD))		(_O_Mrm  0xc0 _b11 _b101 (rindex/8 RD)) (emit-u8 L)))
(define-function SHRBim (L D B I S)		(if (= L 1)	(_O_r_X  0xd0 _b101 D B I S)			(_O_r_X  0xc0 _b101 D B I S) (emit-u8 L)))
(define-function SHRBrr (RS RD)			(if (= RS _CL)	(_O_Mrm  0xd2 _b11 _b101 (rindex/8 RD))		(ASMFAIL "source register must be CL")))
(define-function SHRBrm (RS D B I S)		(if (= RS _CL)	(_O_r_X  0xd2 _b101 D B I S)			(ASMFAIL "source register must be CL")))
(define-function SHRWir (L RD)			(if (= L 1)	(_wO_Mrm 0xd1 _b11 _b101 (rindex/16 RD))	(_wO_Mrm 0xc1 _b11 _b101 (rindex/16 RD)) (emit-u8 L)))
(define-function SHRWim (L D B I S)		(if (= L 1)	(_wO_r_X 0xd1 _b101 D B I S)			(_wO_r_X 0xc1 _b101 D B I S) (emit-u8 L)))
(define-function SHRWrr (RS RD)			(if (= RS _CL)	(_wO_Mrm 0xd3 _b11 _b101 (rindex/16 RD))	(ASMFAIL "source register must be CL")))
(define-function SHRWrm (RS D B I S)		(if (= RS _CL)	(_wO_r_X 0xd3 _b101 D B I S)			(ASMFAIL "source register must be CL")))
(define-function SHRLir (L RD)			(if (= L 1)	(_O_Mrm  0xd1 _b11 _b101 (rindex/32 RD))	(_O_Mrm  0xc1 _b11 _b101 (rindex/32 RD)) (emit-u8 L)))
(define-function SHRLim (L D B I S)		(if (= L 1)	(_O_r_X  0xd1 _b101 D B I S)			(_O_r_X  0xc1 _b101 D B I S) (emit-u8 L)))
(define-function SHRLrr (RS RD)			(if (= RS _CL)	(_O_Mrm  0xd3 _b11 _b101 (rindex/32 RD))	(ASMFAIL "source register must be CL")))
(define-function SHRLrm (RS D B I S)		(if (= RS _CL)	(_O_r_X  0xd3 _b101 D B I S)			(ASMFAIL "source register must be CL")))

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

(define-function STC () (_O 249))

(define-function XADDBrr (RS RD) (_OO_Mrm 4032 _b11 (rindex/8 RS) (rindex/8 RD)))
(define-function XADDBrm (RS MD MB MI MS) (_OO_r_X 4032 (rindex/8 RS) MD MB MI MS))
(define-function XADDWrr (RS RD) (_wOO_Mrm 4033 _b11 (rindex/16 RS) (rindex/16 RD)))
(define-function XADDWrm (RS MD MB MI MS) (_wOO_r_X 4033 (rindex/16 RS) MD MB MI MS))
(define-function XADDLrr (RS RD) (_OO_Mrm 4033 _b11 (rindex/32 RS) (rindex/32 RD)))
(define-function XADDLrm (RS MD MB MI MS) (_OO_r_X 4033 (rindex/32 RS) MD MB MI MS))
(define-function XCHGBrr (RS RD) (_O_Mrm 134 _b11 (rindex/8 RD) (rindex/8 RS)))
(define-function XCHGBrm (RS MD MB MI MS) (_O_r_X 134 (rindex/8 RS) MD MB MI MS))
(define-function XCHGWrr (RS RD) (_wO_Mrm 135 _b11 (rindex/16 RS) (rindex/16 RD)))
(define-function XCHGWrm (RS MD MB MI MS) (_wO_r_X 135 (rindex/16 RS) MD MB MI MS))
(define-function XCHGLrr (RS RD) (_O_Mrm 135 _b11 (rindex/32 RD) (rindex/32 RS)))
(define-function XCHGLrm (RS MD MB MI MS) (_O_r_X 135 (rindex/32 RS) MD MB MI MS))

(define-function BSWAPr (R) (BSWAPLr R))
(define-function PUSHr (R) (if (register/32? R) (PUSHLr R) (if (register/16? R) (PUSHWr R) (ASMFAIL "illegal register size"))))
(define-function POPr  (R) (if (register/32? R) (POPLr R)  (if (register/16? R) (POPWr R)  (ASMFAIL "illegal register size"))))

(define-function CALLQr (R) (let () (_REX 0 R 0 0) (CALLr (to-r32 R))))
(define-function CALLQm (D B I S) (let () (_REX 0 0 I B) (CALLm D (to-r32 B) (to-r32 I) S)))
(define-function INCQr (R) (let () (_REX 1 0 0 R) (_O_Mrm 255 _b11 _b000 (rindex (to-r32 R)))))
(define-function JMPQr (R) (let () (_REX 0 R 0 0) (JMPr (to-r32 R))))
(define-function JMPQm (D B I S) (let () (_REX 0 0 I B) (JMPm D (to-r32 B) (to-r32 I) S)))
(define-function LEAQmr (D B I S R) (let () (_REX 1 R I B) (LEALmr D (to-r32 B) (to-r32 I) S (to-r32 R))))
(define-function LEAVEQ () (LEAVE))

(define-function MOVSBQrr (S D) (let () (_REX 1 S 0 D) (MOVSBLrr S (to-r32 D))))
(define-function MOVSBQmr (D B I S R) (let () (_REX 1 S 0 D) (MOVSBLmr D (to-r32 B) (to-r32 I) S (to-r32 R))))
(define-function MOVZBQrr (S D) (let () (_REX 1 S 0 D) (MOVZBLrr S (to-r32 D))))
(define-function MOVZBQmr (D B I S R) (let () (_REX 1 S 0 D) (MOVZBLmr D (to-r32 B) (to-r32 I) S (to-r32 R))))
(define-function POPQr (R) (let () (_REX 0 0 0 R) (POPLr (to-r32 R))))
(define-function PUSHQr (R) (let () (_REX 0 0 0 R) (PUSHLr (to-r32 R))))
(define-function PUSHQi (L) (let () (_REX 1 0 0 0) (PUSHLi L)))
(define-function RETQ () (RET))

(define-function SALQir (L R)		(_REX 1 0 0 R) (SALLir L (to-r32 R)))
(define-function SALQrr (S D)		(_REX 1 S 0 D) (SALLrr S (to-r32 D)))
(define-function SALQim (L D B I S)	(_REX 1 0 I B) (SALLim L D (to-r32 B) (to-r32 I) S))
(define-function SALQrm (R D B I S)	(_REX 1 R I B) (SALLrm R D (to-r32 B) (to-r32 I) S))
(define-function SARQir (L R)		(_REX 1 0 0 R) (SARLir L (to-r32 R)))
(define-function SARQrr (S D)		(_REX 1 S 0 D) (SARLrr S (to-r32 D)))
(define-function SARQim (L D B I S)	(_REX 1 0 I B) (SARLim L D (to-r32 B) (to-r32 I) S))
(define-function SARQrm (R D B I S)	(_REX 1 R I B) (SARLrm R D (to-r32 B) (to-r32 I) S))

(define-function INVD ()		(_OO 0x0f08))
(define-function SYSCALL ()		(_OO 0x0f05))

(define-function CBW ()			(_wO 0x98))
(define-function CLC ()			(_O 0xf8))
(define-function CWD ()			(_O 0x99)) ; 16 bit mode
(define-function CDQ ()			(_O 0x99)) ; 32 bit mode, aka CLTD
(define-function CQO ()			(_REX 1 0 0 0) (_O 0x99)) ; 64 bit mode
(define-function CMC ()			(_O 0xf5))
(define-function HLT ()			(_O 0xf4))

(define-function CMOVCCLirr (CC RS RD)	(_OO_Mrm (bitwise-or 0x0f40 CC) _b11 (rindex/32 RD) (rindex/32 RS)))
(define-function CMOVCCQirr (CC S D)	(_REX 1 S 0 D) (CMOVCCLirr CC (to-r32 S) (to-r32 D)))
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
(define-function %JCCrel8 (CC D)
  (_O_rel8 (bitwise-or 0x70 CC) D))

;; rel32 distance
(define-function %JCCrel32 (CC D)
  (_OO_rel32 (bitwise-or 0x0f80 CC) D))

(with-forms
    ((x (entries
         (let ((index -1))
           `(begin
             ,@(map
                (lambda (entry)
                  (let ((base-name (concat-symbol 'J (first entry))))
                    `(begin
                      (define-function ,(concat-symbol base-name 'S) (D)
                        (%JCCrel8 ,(second entry) D))
                      (define-function ,(concat-symbols base-name (string->symbol "32")) (D)
                        (%JCCrel32 ,(second entry) D))
                      (define-function ,base-name (D)
                        (if (i8? D)
                            (%JCCrel8 ,(second entry) D)
                          (%JCCrel32 ,(second entry) D))))))
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
