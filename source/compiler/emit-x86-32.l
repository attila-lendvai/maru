;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is a compiler that emits i686 (IA-32) machine code directly
;;; into an Elf32 executable.
;;;
;;; It runs on a 64-bit host and targets 32-bit x86. The assembler
;;; encodes the "L" (32-bit operand) forms; see reg64 below for the
;;; base/index register convention.
;;;

(require "source/assembler/single-pass-x86.l")
(require "source/compiler/elf-early.l")

;;;
;;; Registers
;;;

(with-forms
    ((x ((ctor . registers)
         (let ((index -1))
           `(begin
             ,@(map (lambda (reg)
                      (incr index)
                      ;; the op/ prefix stands for operand
                      `(define ,(concat-symbol 'op/ reg)
                          (,ctor ,reg ,index)))
                    registers))))))
  (x R32 EAX EBX ECX EDX ESP EBP ESI EDI))

;; The 64-bit register symbol matching a 32-bit register symbol. The
;; memory-operand encoders take base/index registers as 64-bit symbols
;; (they map them down via to-r32) and the data register as the 32-bit
;; symbol. Passing the 64-bit name also avoids the 0x67 address-size
;; prefix that a register/32? base would select.
(define-function reg64 (reg)
  (cond
    ((= reg EAX) RAX)
    ((= reg EBX) RBX)
    ((= reg ECX) RCX)
    ((= reg EDX) RDX)
    ((= reg ESP) RSP)
    ((= reg EBP) RBP)
    ((= reg ESI) RSI)
    ((= reg EDI) RDI)
    (else (error "reg64: not a 32-bit register: "reg))))

;; cdecl: no register parameters, every argument goes on the stack.
(define-constant +param-registers+		`(quote ,()))
(define-constant +callee-saved-registers+	`(quote ,(list op/EBX op/ESI op/EDI)))

(define-constant +accumulator+		EAX)
(define-constant +op/accumulator+	op/EAX)

(require "source/compiler/elf.l")

;;;
;;; INSTRUCTIONS
;;;

(define-instruction GOTO	()
  ((label)			(JMP $1)))

(define-instruction GOTOF	(true 0 false)
  ((REGISTER label)		(TESTLrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JE $2)))

(define-instruction GOTOT	(true 0 false)
  ((REGISTER label)		(TESTLrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JNE $2)))

(define-instruction CALL	(false 0 true)
  ((label)			(CALLQrel32 $1))
  ((REGISTER)			(CALLr (<REGISTER>-name $1)))
  ((reloc-symbol)		(CALLQrel32 $1)))

(define-instruction ADD		(true 0 true)
  ((R32 STACK-CELL)		(ADDLmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R32 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (unless (= 0 lit)
                                    (ADDLir lit reg)))))

(define-instruction SUB		(true 0 true)
  ((R32 STACK-CELL)		(SUBLmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R32 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (unless (= 0 lit)
                                    (SUBLir lit reg)))))

(define-instruction MULTIPLY	(true 0 true)
  ((R32 STACK-CELL)		(MULLmr (<STACK-CELL>-offset $2) EBP 0 0 (<REGISTER>-name $1)))
  ((R32 LI64)			(cond
                                  ((= 1 (<LITERAL>-value $2))) ; nothing to do
                                  (else
                                   (MOVLir (<LITERAL>-value $2) ECX)
                                   (MULLrr ECX (<REGISTER>-name $1))))))

;; the x86 div instruction is unsigned division
(define-instruction DIVIDE	(true 0 true)
  ((R32 STACK-CELL)		(CDQ)
                                (IDIVLmr (<STACK-CELL>-offset $2) EBP 0 0 (<REGISTER>-name $1)))
  ((R32 LI64)			(CDQ)
                                (cond
                                  ((= 1 (<LITERAL>-value $2))
                                   ;; remainder is zero, %eax is unchanged
                                   )
                                  (else
                                   (MOVLir (<LITERAL>-value $2) ECX) ; divisor
                                   (IDIVLrr ECX (<REGISTER>-name $1))))))

(define-instruction AND		(true 0 true)
  ((R32 STACK-CELL)		(ANDLmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R32 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     (XORLrr reg reg))
                                    ((= -1 lit)
                                     ;; NOP
                                     )
                                    (else
                                     (ANDLir lit reg))))))

(define-instruction OR		(true 0 true)
  ((R32 STACK-CELL)		(ORLmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R32 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((= -1 lit)
                                     (MOVLir -1 reg))
                                    (else
                                     (ORLir lit reg))))))

(define-instruction XOR		(true 0 true)
  ((R32 STACK-CELL)		(XORLmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R32 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((= -1 lit)
                                     (NOTLr reg))
                                    (else
                                     (XORLir lit reg))))))

(define-instruction BITWISE-NOT	(true 0 true)
  ((REGISTER)			(NOTLr (<REGISTER>-name $1))))

(define-instruction LOGIC-NOT	(true 0 true)
  ((REGISTER)			(TESTLrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (SETEr AL)
                                (MOVZBLrr AL (<REGISTER>-name $1))))

(define-instruction NEGATE	(true 0 true)
  ((REGISTER)			(NEGLr (<REGISTER>-name $1))))

(define-instruction ASL		(true 0 true)
  ((R32 STACK-CELL)		(MOVLmr (<STACK-CELL>-offset $2) RBP 0 0 ECX)
                                (SALLrr CL (<REGISTER>-name $1)))
  ((R32 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (SALLir lit (<REGISTER>-name $1))))))

(define-instruction ASR		(true 0 true)
  ((R32 STACK-CELL)		(MOVLmr (<STACK-CELL>-offset $2) RBP 0 0 ECX)
                                (SARLrr CL (<REGISTER>-name $1)))
  ((R32 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (SARLir lit (<REGISTER>-name $1))))))

(define-instruction ADDR	(false 0 true)
  ((GLOBAL-CELL)		(MOVLir (<GLOBAL-CELL>-address $1) EAX))
  ((STACK-CELL)			(LEALmr (<STACK-CELL>-offset $1) EBP 0 0 EAX)))

(define-instruction MOVE	()
  ((LI64 STACK-CELL)		(MOVLim (<LITERAL>-value $1) (<STACK-CELL>-offset $2) RBP 0 0))
  ((LI64 R32)			(MOVLir (<LITERAL>-value $1) (<REGISTER>-name $2)))
  ((STACK-CELL STACK-CELL)	(let ((off1 (<STACK-CELL>-offset $1))
                                      (off2 (<STACK-CELL>-offset $2)))
                                  (unless (= off1 off2)
                                    (MOVLmr off1 RBP 0 0 ECX)
                                    (MOVLrm ECX off2 RBP 0 0))))
  ((R32 STACK-CELL)		(MOVLrm (<REGISTER>-name $1) (<STACK-CELL>-offset $2) RBP 0 0))
  ((STACK-CELL R32)		(MOVLmr (<STACK-CELL>-offset $1) RBP 0 0 (<REGISTER>-name $2)))
  ((R32 R32)			(let ((src (<REGISTER>-name $1))
                                      (dst (<REGISTER>-name $2)))
                                  (unless (= src dst)
                                    (MOVLrr src dst)))))

(define-instruction LOAD	(false 0 true)
  ((LI64)			(if (= 0 (<LITERAL>-value $1))
                                    (XORLrr EAX EAX)
                                  (MOVLir (<LITERAL>-value $1) EAX)))
  ((LI32)			(if (= 0 (<LITERAL>-value $1))
                                    (XORLrr EAX EAX)
                                  (MOVLir (<LITERAL>-value $1) EAX)))
  ((STACK-CELL)			(MOVLmr (<STACK-CELL>-offset $1) RBP 0 0 EAX))
  ((R32)			(MOVLrr (<REGISTER>-name $1) EAX))
  ((GLOBAL-CELL)		(MOVLir (<GLOBAL-CELL>-address $1) EAX)
                                (MOVLmr 0 RAX 0 0 EAX))
  ((GLOBAL-ADDR)		(MOVLir (<GLOBAL-ADDR>-address $1) EAX)))

;; args: dest, value
(define-instruction STORE	(true 0 false)
  ((GLOBAL-CELL R32)		(MOVLir (<GLOBAL-CELL>-address $1) EBX)
                                (MOVLrm (<REGISTER>-name $2) 0 RBX 0 1))
  ((R32 R32)			(MOVLrm (<REGISTER>-name $2) 0 (reg64 (<REGISTER>-name $1)) 0 1))
  ((STACK-CELL R32)		(MOVLrm (<REGISTER>-name $2) (<STACK-CELL>-offset $1) RBP 0 1)))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; for now these are all unsigned, i.e. not sign extended.
(define-instruction LOAD-U8	(true 0 true)
  ((R32 STACK-CELL)		(MOVLmr (<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (LEALmr 0 (<REGISTER>-name $1) ECX 1 ECX)
                                (XORLrr EAX EAX)
                                (MOVBmr 0 RCX 0 1 AL))
  ((R32 LI64)			(let ((offset (<LITERAL>-value $2)))
                                  (if (= 0 offset)
                                      (MOVLrr (<REGISTER>-name $1) ECX)
                                    (LEALmr offset (<REGISTER>-name $1) 0 1 ECX)))
                                (XORLrr EAX EAX)
                                (MOVBmr 0 RCX 0 1 AL)))

(define-instruction STORE-U8	(true 0 true)
  ((R32 STACK-CELL STACK-CELL)	(when-at-expand (feature strict-semantics-for-compiled-set)
                                  (XORLrr	EBX EBX))
                                (MOVBmr	(<STACK-CELL>-offset $3) RBP 0 1 BL)
                                (MOVLmr	(<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (MOVBrm	BL 0 (reg64 (<REGISTER>-name $1)) RCX 1)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr	EBX EAX)))
  ((R32 STACK-CELL LI64)	(MOVLmr	(<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (if-at-expand (feature strict-semantics-for-compiled-set)
                                    (begin
                                     (XORLrr	EBX EBX)
                                     (MOVBir	(<LITERAL>-value $3) BL)
                                     (MOVBrm	BL 0 (reg64 (<REGISTER>-name $1)) RCX 1)
                                     (MOVLrr	EBX EAX))
                                  (MOVBim	(<LITERAL>-value $3) 0 (reg64 (<REGISTER>-name $1)) RCX 1)))
  ((R32 LI64 STACK-CELL)	(MOVLmr	(<STACK-CELL>-offset $3) RBP 0 1 ECX)
                                (MOVBrm	CL (<LITERAL>-value $2) (reg64 (<REGISTER>-name $1)) 0 1)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVZBLrr	CL EAX)))
  ((R32 LI64 LI64)		(if-at-expand (feature strict-semantics-for-compiled-set)
                                    (begin
                                     (XORLrr	EBX EBX)
                                     (MOVBir	(<LITERAL>-value $3) BL)
                                     (MOVBrm	BL (<LITERAL>-value $2) (reg64 (<REGISTER>-name $1)) 0 1)
                                     (MOVLrr	EBX EAX))
                                  (MOVBim	(<LITERAL>-value $3) (<LITERAL>-value $2) (reg64 (<REGISTER>-name $1)) 0 1))))

;; args: ptr, byteoffset
(define-instruction LOAD-U32	(true 0 true)
  ((R32 STACK-CELL)		(MOVLmr (<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (MOVLmr 0 (reg64 (<REGISTER>-name $1)) RCX 1 EAX))
  ((R32 LI64)			(LEALmr (<LITERAL>-value $2) (<REGISTER>-name $1) 0 0 EAX)
                                (MOVLmr 0 RAX 0 0 EAX)))

;; args: ptr, byteoffset, value
(define-instruction STORE-U32	(true 0 true)
  ((R32 STACK-CELL STACK-CELL)	(MOVLmr (<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (MOVLmr (<STACK-CELL>-offset $3) RBP 0 1 EDX)
                                (MOVLrm EDX 0 (reg64 (<REGISTER>-name $1)) RCX 1)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr EDX EAX)))
  ((R32 LI64 LI64)		(MOVLir (<LITERAL>-value $3) EDX)
                                (MOVLrm EDX (<LITERAL>-value $2) (reg64 (<REGISTER>-name $1)) 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr EDX EAX)))
  ((R32 STACK-CELL LI64)	(MOVLmr (<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (MOVLir (<LITERAL>-value $3) EDX)
                                (MOVLrm EDX 0 (reg64 (<REGISTER>-name $1)) RCX 1)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr EDX EAX)))
  ((R32 LI64 STACK-CELL)	(MOVLmr (<STACK-CELL>-offset $3) RBP 0 1 EDX)
                                (MOVLrm EDX (<LITERAL>-value $2) (reg64 (<REGISTER>-name $1)) 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr EDX EAX))))

(when-at-expand (feature memory-block)

;; TODO these two are the same as the -OOP versions, except the MOV's scale
(define-instruction LOAD-CELL	(true 0 true)
  ((R32 STACK-CELL)		(MOVLmr	(<STACK-CELL>-offset $2) RBP 0 1 ECX) ; index
				(MOVLmr 0 (reg64 (<REGISTER>-name $1)) RCX 1 EAX))
  ((R32 LI64)			(LEALmr	(<LITERAL>-value $2) (<REGISTER>-name $1) 0 0 EAX) ; index
				(MOVLmr 0 RAX 0 0 EAX)))

(define-instruction STORE-CELL	(true 0 true)
  ((R32 STACK-CELL STACK-CELL)	(MOVLmr	(<STACK-CELL>-offset $2) RBP 0 1 ECX) ; index
				(MOVLmr	(<STACK-CELL>-offset $3) RBP 0 1 EBX) ; value
				(MOVLrm	EBX 0 (reg64 (<REGISTER>-name $1)) RCX 1)))

) ; (feature memory-block)

(define-instruction LOAD-OOP	(true 0 true)
  ((R32 STACK-CELL)		(MOVLmr	(<STACK-CELL>-offset $2) RBP 0 1 ECX) ; index
				(MOVLmr	0 (reg64 (<REGISTER>-name $1)) RCX target/cell-size/bytes EAX))
  ((R32 LI64)			(let ((offset (<LITERAL>-value $2)))
                                  (if (= 0 offset)
                                      (MOVLmr 0 (reg64 (<REGISTER>-name $1)) 0 0 EAX)
                                    (LEALmr (* offset target/cell-size/bytes) (<REGISTER>-name $1) 0 0 ECX)
                                    (MOVLmr 0 RCX 0 0 EAX)))))

;; object is in EAX; args: offset, value
(define-instruction STORE-OOP	(true 0 true)
  ((R32 STACK-CELL STACK-CELL)	(MOVLmr	(<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (MOVLmr	(<STACK-CELL>-offset $3) RBP 0 1 EDX)
                                (MOVLrm	EDX 0 (reg64 (<REGISTER>-name $1)) RCX target/cell-size/bytes)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  ;; TODO these should probably mess with the current-value,
                                  ;; instead of move'ing into EAX
                                  (MOVLrr	EDX EAX)))
  ((R32 LI64 LI64)		(MOVLir	(<LITERAL>-value $3) EDX) ; value
                                (MOVLrm	EDX (* (<LITERAL>-value $2) target/cell-size/bytes) (reg64 (<REGISTER>-name $1)) 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr	EDX EAX)))
  ((R32 STACK-CELL LI64)	(MOVLmr	(<STACK-CELL>-offset $2) RBP 0 1 ECX)
                                (MOVLir	(<LITERAL>-value $3) EDX)
                                (MOVLrm	EDX 0 (reg64 (<REGISTER>-name $1)) RCX target/cell-size/bytes)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr	EDX EAX)))
  ((R32 LI64 STACK-CELL)	(MOVLmr	(<STACK-CELL>-offset $3) RBP 0 1 EDX) ; value
                                (MOVLrm	EDX (* (<LITERAL>-value $2) target/cell-size/bytes) (reg64 (<REGISTER>-name $1)) 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVLrr	EDX EAX))))

(define-instruction PUSH	()
  ((LI64)			(PUSHLi (<LITERAL>-value $1)))
  ((R32)			(PUSHLr (<REGISTER>-name $1)))
  ((STACK-CELL)			(MOVLmr (<STACK-CELL>-offset $1) RBP 0 0 EAX)
                                (PUSHLr EAX)))

;; ENTER is slow, so don't use it (LEAVE is fine)
(define-instruction ENTER-FRAME	()
  ((_)				(PUSHLr EBP)
                                (MOVLrr ESP EBP)
                                (unless (= 0 $1)
                                  (SUBLi32r $1 ESP))))

(define-instruction LEAVE-FRAME	()
  ((_)				(LEAVE)
                                (RET)))

(define-form define-instruction/comparator (maru-name x86-name)
  `(define-instruction ,maru-name (true 0 true)
     ((R32 STACK-CELL)
      ;; TODO order?!
      (CMPLmr (<STACK-CELL>-offset $2) RBP 0 1 (<REGISTER>-name $1))
      (,x86-name AL)
      (MOVZBLrr AL (<REGISTER>-name $1)))
     ((R32 LI64)
      (let ((lit (<LITERAL>-value $2)))
        (if (= 0 lit)
            (TESTLrr (<REGISTER>-name $1) (<REGISTER>-name $1))
          (CMPLir lit (<REGISTER>-name $1))))
      (,x86-name AL)
      (MOVZBLrr AL (<REGISTER>-name $1)))))

(define-instruction/comparator LT SETLr)
(define-instruction/comparator LE SETLEr)
(define-instruction/comparator EQ SETEr)
(define-instruction/comparator GE SETGEr)
(define-instruction/comparator GT SETGr)

;;;
;;; Compiling lambdas
;;;

(let ((program-code-offset (slave-value (record/slot-index <target-function> 'program-code))))
  (define-function compile-call-to-<target-function> (-c-)
    ;; TODO assert the type to be <target-function>
    ;; TODO assert nr of args = params
    (when (feature emit-with-object-headers)
      ;; i.e. this is a full <target-function> object. when the
      ;; feature is disabled then it's just a raw function pointer to
      ;; be called.
      (emit LOAD-OOP $ (LI64 program-code-offset)))
    (emit CALL $)
    ()))

(define-method compile-call-to (slave-value <target-function>) (op -c-)
  (comp op)
  (compile-call-to-<target-function> -c-))

(define-function sf/stack-pointer-on-entry (expr -c-)
  ;; the usual function prologue that we also employ is like this:
  ;;
  ;; push	%ebp
  ;; mov	%esp, %ebp
  ;; sub	$n, %esp
  ;;
  ;; so, the 4(%ebp) is to undo the push %ebp, so that we
  ;; regain the %esp value at the entry point to the function.
  (LEALmr	target/cell-size/bytes EBP 0 0 EAX)
  (set (<compiler>-current-value -c-) op/EAX))

(require "source/compiler/elf-late.l")

(define-function emit-expr-code (self entry-point-label parent-comp)
  ;;(assert (is <expr> self))
  (.align +function-alignmet+)

  (let* ((body		(<expr>-body self))
         (-c-		(compiler (+ 1 (<compiler>-level parent-comp))))
         (params	(<expr>-parameters self))
         (param-count	(list-length params))
         (frame-body-size (label/deferred-value)))

    (label! entry-point-label)
    (emit ENTER-FRAME frame-body-size)

    (let ((spill-locs	()))
      ;; allocate stack-cells for spilling the reg params
      (times-do (min param-count +n-param-registers+)
        (let ((spill-loc	(new-stack-cell -c-))
              (var		(pop params)))
          (set (<variable>-value var) spill-loc)
          (push spill-locs spill-loc)))

      ;; assign the stack locations to the params passed on the stack
      (let ((i 2))        ; 2 is the pushed frame pointer and return address
        (list-do var params
          (let ((offset (* i target/cell-size/bytes)))
            (set (<variable>-value var) (STACK-PARAM offset)))
          (incr i)))

      (emit-comment 2 "emitting "self", at level: "(<compiler>-level parent-comp))
      (emit-comment 3 ", code: "(<expr>-body self))
      ;; Unconditionally spill the params to the stack.
      (let ((regs		+param-registers+)
            (stack-cells	(list-reverse! spill-locs)))
        (times-do (min param-count +n-param-registers+)
          (emit MOVE (pop regs) (pop stack-cells))))

      ;; Compile the fn body (COMP is a form, we cannot MAP it).
      (list-do el body
        (comp el))

      ;; Calculate the frame and emit the entire fn
      (let* ((temp-size	(* (<compiler>-temp-limit -c-)
                           target/cell-size/bytes))
             (frame-size	(align +call-frame-alignmet+
                                       (+ temp-size
                                          ;; the pushed %ebp and the return address
                                          (* 2 target/cell-size/bytes)))))

        (label! frame-body-size (- frame-size (* 2 target/cell-size/bytes)))

        (awhen (<compiler>-fn-epilogue-label -c-)
          (label! it))

        (emit LEAVE-FRAME frame-body-size))))

  (let ((name (<expr>-name self)))
    (when name
      (emit-symtab-entry/function (concat-string (symbol->string name) ".code")
                                  (laddress entry-point-label)
                                  (- (current-laddress)
                                     (laddress entry-point-label)))))
  (GLOBAL-ADDR entry-point-label))

;; serious KLUDGE: use a global instead of a slot on <compiler> fixing
;; it is not trivial because compiler objects get nested and at this
;; point we are already nested, and we should push into the parent.
(define expr-queue ())

(define-function compiled-expr-wrapper (name entry-point -c-)
  entry-point)

;; even when emitting is deferred into the queue we still create,
;; register, and return a label. it gets its value set when the queue
;; is eventually emitted.
(define-function compile-expr (self name -c-)
  (emit-comment 2 "0x" (integer->string (current-laddress) 16)
                ": compiling fn "term/FG-GREEN (or name "/unnamed/") term/RESET", "self", level " (<compiler>-level -c-))
  (let ((entry-point (if name
                         (closure-code-label name)
                       (label))))
    (if (< 1 (<compiler>-level -c-))
        ;; a lambda inside a lambda : save it for later
        (begin
         (emit-comment 2 "queueing fn for later: "(or name "/unnamed/")", "self", level " (<compiler>-level -c-))
         (push expr-queue (cons entry-point self)))

      ;; we are at the toplevel, emit ourselves first
      (emit-expr-code self entry-point -c-)
      ;; then emit the queue, if any
      (let (el)
        (while (set el (pop expr-queue))
          (let ((entry-point	(car el))
                (expr		(cdr el)))
            (emit-comment 2 "compiling queued fn "expr", entry-point "entry-point)
            (emit-expr-code expr entry-point -c-)))))

    ;; TODO this compiled-expr-wrapper thing is calling for a cleanup...
    (GLOBAL-ADDR (compiled-expr-wrapper name entry-point -c-))))

;;;
;;; Compiling calls
;;;

(define-function compile-call-form (op args -c-)
  (emit-comment 2 "compile-call: "op", args: "args)
  (safety 2 (assert (or (pair? op) (variable? op))))
  ;; NOTE this implements a left-to-right evaluation order, including the operator.
  ;; i.e. moving this op-tmp means changing the evaluation order!
  (let* ((tmps-to-free	())
         (maybe-store	(lambda (operand)
                          ;; TODO cleanup
                          (if (or (is <R64> operand)
                                  (is <R32> operand))
                              (let ((temp (alloc-reg-temp -c-)))
                                (push tmps-to-free temp)
                                (emit STORE temp $)
                                temp)
                            operand)))
         (arg-operands	(map (lambda (expr)
                               (maybe-store (compile/expression-to-operand expr -c-)))
                             args))
         (arg-count	(list-length args))
         (op-value	(if (variable? op)
                            ;; get the value for dispatch purposes
                            (<variable>-value op)
                          ;; compile to a temp or a literal
                          (maybe-store (compile/expression-to-operand op -c-))))
         ;; cdecl: every argument is pushed; the caller pops them.
         (arg-stack-cell-count	(max 0 (- arg-count +n-param-registers+)))
         (arg-regs	+param-registers+))

    ;; move the reg-passed operands into the regs (none on i686)
    (times-do (min arg-count +n-param-registers+)
      (emit MOVE (pop arg-operands) (pop arg-regs)))

    ;; push all arguments right-to-left
    (list-do op (list-reverse! arg-operands)
      (emit PUSH op))

    (let* ((n-params	 (emit-comment 2 "compile-call-to: "op-value)
                         (compile-call-to op-value op -c-))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))
    (emit ADD op/ESP (LI64 (* arg-stack-cell-count target/cell-size/bytes)))
    (free-temps tmps-to-free)))

(define-method compile-call-to <STACK-CELL> (op -c-)
  (emit LOAD self)
  (compile-call-to-<target-function> -c-))

(define-method compile-call-to <R32> (op -c-)
  (emit MOVE self +op/accumulator+)
  (compile-call-to-<target-function> -c-))

(define-method compile-call-to <C-function> (op -c-)
  ;; 'link-time: a direct call against the UND symbol, resolved by the
  ;; static linker ('c-obj); 'load-time: through the GOT-cell
  ;; trampoline, resolved by ld.so ('standalone)
  (if (= "c-obj" elf-emission-type)
      (emit CALL (reloc-symbol (<C-function>-name self)))
    (emit CALL (external-trampoline-label self -c-)))
  ;; a 32-bit int return already fills the accumulator
  (set (<compiler>-current-value -c-) +op/accumulator+)
  (unless (<C-function>-vararg? self)
    (list-length (<C-function>-parameter-types self))))

(define-function run-compiler (env output-path)
  (compile-env env (compiler 1) output-path
               elf/EM_386
               elf/R_386_RELATIVE
               elf/R_386_GLOB_DAT))

(require "source/compiler/emit-late.l")
