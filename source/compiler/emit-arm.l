;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is a compiler that emits aarch64 machine code directly into an
;;; Elf64 executable.
;;;

(require "source/assembler/single-pass-arm.l")
(require "source/compiler/elf-early.l")

;;;
;;; Registers
;;;

(with-forms
    ((x ((ctor name-prefix)
         (let ((i 0)
               (count 32)
               (result ()))
           (while (< i count)
             (let ((reg (concat-symbol name-prefix (number->string i))))
               (push result
                     ;; the op/ prefix stands for operand
                     `(define ,(concat-symbol 'op/ reg)
                        (,ctor ,reg ,i))))
             (incr i))
           `(begin
             ,@result)))))
  (x R32 W)
  (x R64 X))

(define op/FP op/X29)    ; frame pointer
(define op/LP op/X30)    ; link register
(define op/SP op/X31)    ; stack pointer
(define op/XZR op/X31)   ; always zero register in 64-bit opcodes
(define op/WZR op/W31)   ; always zero register in 32-bit opcodes

(define-constant +param-registers+		`(quote ,(list op/X0 op/X1 op/X2 op/X3 op/X4 op/X5 op/X6 op/X7)))
(define-constant +callee-saved-registers+	`(quote ,(list op/X19 op/X20 op/X21 op/X22 op/X23 op/X24 op/X25 op/X26 op/X27 op/X28)))

;; TODO ? use +accumulator+ in the instructions and everywhere
;; else in general where relevant.

;; NOTE in the arm ABI X0 is both the accumulator and also the first
;; parameter; i.e. there's a clash that the x86-64 ABI doesn't
;; have. Because of that definitions like compile-call-to-<target-function>
;; or compile-call-to <STACK-CELL> cannot be shared between the two
;; backends.
(define-constant +accumulator+		X0)
(define-constant +op/accumulator+	op/X0)

(require "source/compiler/elf.l")

;;;
;;; INSTRUCTIONS
;;;

(define-instruction BR		()
  ((label)			(B $1)))

(define-instruction BF		(true 0 false)
  ((REGISTER label)		(ANDSr XZR (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (BEQ $2)))

(define-instruction BT		(true 0 false)
  ((REGISTER label)		(ANDSr XZR (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (BNE $2)))

(define-instruction CALL	(false 0 true)
  ((label)			(BL $1))
  ((REGISTER)			(BLR (<REGISTER>-name $1))))

(define-instruction ADD		(true 0 true)
  ((R64 STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $2))
                                (ADDr (<REGISTER>-name $1) (<REGISTER>-name $1) X16))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((< 0 lit 4096)
                                     (ADDi reg reg lit))
                                    (else
                                     (MOVi X16 lit)
                                     (ADDr reg reg X16))))))

(define-instruction SUB		(true 0 true)
  ((R64 STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $2))
                                (SUBr (<REGISTER>-name $1) (<REGISTER>-name $1) X16))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((< 0 lit 4096)
                                     (SUBi reg reg lit))
                                    (else
                                     (MOVi X16 lit)
                                     (SUBr reg reg X16))))))

(define-instruction MULTIPLY	()
  ((STACK-CELL)			(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (MUL X0 X0 X16))
  ((LI64)			(cond
                                  ((= 1 (<LITERAL>-value $1))) ; nothing to do
                                  (else
                                   (MOVi X16 (<LITERAL>-value $1))
                                   (MUL X0 X0 X16)))))

(define-instruction DIVIDE	()
  ((STACK-CELL)			(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (SDIV X0 X0 X16))
  ((LI64)			(cond
                                  ((= 1 (<LITERAL>-value $1))) ; nothing to do
                                  (else
                                   (MOVi X16 (<LITERAL>-value $1))
                                   (SDIV X0 X0 X16)))))

(define-instruction AND		(true 0 true)
  ((R64 STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $2))
                                (ANDr (<REGISTER>-name $1) (<REGISTER>-name $1) X16))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     (EORr reg reg reg))
                                    ((= -1 lit)
                                     ;; NOP
                                     )
                                    (else
                                     (MOVi X16 lit)
                                     (ANDr reg reg X16))))))

(define-instruction OR		(true 0 true)
  ((R64 STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $2))
                                (ORRr (<REGISTER>-name $1) (<REGISTER>-name $1) X16))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((= -1 lit)
                                     (MOVi X16 lit)
                                     (ORRr reg reg X16))
                                    (else
                                     (MOVi X16 lit)
                                     (ORRr reg reg X16))))))

(define-instruction XOR		(true 0 true)
  ((R64 STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $2))
                                (EORr (<REGISTER>-name $1) (<REGISTER>-name $1) X16))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((= -1 lit)
                                     (MVN reg reg))
                                    (else
                                     (MOVi X16 lit)
                                     (EORr reg reg X16))))))

(define-instruction BITWISE-NOT	(true 0 true)
  ((REGISTER)			(MVN (<REGISTER>-name $1) (<REGISTER>-name $1))))

(define-instruction LOGIC-NOT	(true 0 true)
  ((REGISTER)			(CMPi (<REGISTER>-name $1) 0)
                                 (CSET (<REGISTER>-name $1) 0)))  ; EQ cond = 0

(define-instruction NEGATE	(true 0 true)
  ((REGISTER)			(NEG (<REGISTER>-name $1) (<REGISTER>-name $1))))

(define-instruction ASL		(true 0 true)
  ((R64 STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $2))
                                (LSLV (<REGISTER>-name $1) (<REGISTER>-name $1) X16))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (unless (= 0 lit)
                                    (MOVi X16 lit)
                                    (LSLV reg reg X16)))))

(define-instruction ASR		(true 0 true)
  ((R64 STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $2))
                                (ASRV (<REGISTER>-name $1) (<REGISTER>-name $1) X16))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (unless (= 0 lit)
                                    (MOVi X16 lit)
                                    (ASRV reg reg X16)))))

(define-instruction ADDR	(false 0 true)
  ((GLOBAL-CELL)		(ADR X0 (<GLOBAL-CELL>-address $1)))
  ((STACK-CELL)			(SUBi X0 FP (- 0 (<STACK-CELL>-offset $1)))))

(define-instruction MOVE	()
  ((LI64 STACK-CELL)		(MOVi X16 (<LITERAL>-value $1))
                                (STUR X16 FP (<STACK-CELL>-offset $2)))
  ((LI64 R64)			(MOVi (<REGISTER>-name $2) (<LITERAL>-value $1)))
  ((STACK-CELL STACK-CELL)	(let ((off1 (<STACK-CELL>-offset $1))
                                      (off2 (<STACK-CELL>-offset $2)))
                                  (unless (= off1 off2)
                                    (LDUR X16 FP off1)
                                    (STUR X16 FP off2))))
  ((R64 STACK-CELL)		(STUR (<REGISTER>-name $1) FP (<STACK-CELL>-offset $2)))
  ((STACK-CELL R64)		(LDUR (<REGISTER>-name $2) FP (<STACK-CELL>-offset $1)))
  ((R64 R64)			(let ((src (<REGISTER>-name $1))
                                      (dst (<REGISTER>-name $2)))
                                  (unless (= src dst)
                                    (MOVr dst src)))))

(define-instruction LOAD	(false 0 true)
  ((LI64)			(if (= 0 (<LITERAL>-value $1))
                                    (EORr X0 X0 X0)
                                  (MOVi X0 (<LITERAL>-value $1))))
  ((STACK-CELL)			(LDUR X0 FP (<STACK-CELL>-offset $1)))
  ((R64)			(MOVr X0 (<REGISTER>-name $1)))
  ((GLOBAL-CELL)		(ADR X0 (<GLOBAL-CELL>-address $1))
                                (LDR X0 X0 0))
  ((GLOBAL-ADDR)		(ADR X0 (<GLOBAL-ADDR>-address $1)))
  )

(define-instruction/emit-forms LOAD 1
  ((STACK-PARAM)			(LDUR X0 FP (<STACK-CELL>-offset $1))))

(define-instruction STORE	(true 0 false)
  ((R64 GLOBAL-CELL)		(ADR X16 (<GLOBAL-CELL>-address $2))
                                (STR (<REGISTER>-name $1) X16 0))
  ((R64 R64)			(STR (<REGISTER>-name $1) (<REGISTER>-name $2) 0))
  ((R64 STACK-CELL)		(STUR (<REGISTER>-name $1) FP (<STACK-CELL>-offset $2)))
  ((R64 STACK-PARAM)		(STUR (<REGISTER>-name $1) FP (<STACK-CELL>-offset $2))))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; in haskell the signed ones are called integer, and the unsigned one are called word.
;; for now these are all unsigned, i.e. not sign extended.
(define-instruction LOAD-I8	(false 0 true)
  ((STACK-CELL)			(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (ADDr X16 X0 X16)
                                (LDRB W0 X16 0))
  ((LI64)			(let ((offset (<LITERAL>-value $1)))
                                  (cond
                                    ((= 0 offset)
                                     (LDRB W0 X0 0))
                                    ((<= 0 offset 4095)
                                     (ADDi X16 X0 offset)
                                     (LDRB W0 X16 0))
                                    (else
                                     (MOVi X16 offset)
                                     (ADDr X16 X0 X16)
                                     (LDRB W0 X16 0))))))

(define-instruction STORE-I8	(false 0 true)
  ((STACK-CELL STACK-CELL)	(when-at-expand (feature strict-semantics-for-compiled-set)
                                  (EORr X17 X17 X17))
                                (LDUR X16 FP (<STACK-CELL>-offset $2))
                                (LDUR X17 FP (<STACK-CELL>-offset $1))
                                (ADDr X17 X0 X17)
                                (STRB W16 X17 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVr X0 X16)))
  ((STACK-CELL LI64)		(LDUR X17 FP (<STACK-CELL>-offset $1))
                                (ADDr X17 X0 X17)
                                (if-at-expand (feature strict-semantics-for-compiled-set)
                                    (begin
                                     (EORr X16 X16 X16)
                                     (MOVi X16 (<LITERAL>-value $2))
                                     (STRB W16 X17 0)
                                     (MOVr X0 X16))
                                  (begin
                                    (MOVi X16 (<LITERAL>-value $2))
                                    (STRB W16 X17 0)))))

(when-at-expand (feature memory-block)
  ;; TODO these two are the same as the -OOP versions, except the MOV's scale
  (define-instruction LOAD-CELL	(false 0 true)
    ((STACK-CELL)		(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (ADDr X16 X0 X16)
                                (LDR X0 X16 0))
    ((LI64)			(let ((offset (<LITERAL>-value $1)))
                                  (cond
                                    ((= 0 offset)
                                     (LDR X0 X0 0))
                                    ((<= 0 offset 4095)
                                     (ADDi X0 X0 offset)
                                     (LDR X0 X0 0))
                                    (else
                                     (MOVi X16 offset)
                                     (ADDr X0 X0 X16)
                                     (LDR X0 X0 0))))))

  ;; args: base in X0 (implicit), offset, value
  (define-instruction STORE-CELL	(false 0 true)
    ((STACK-CELL STACK-CELL)	(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (LDUR X17 FP (<STACK-CELL>-offset $2))
                                (ADDr X16 X0 X16)
                                (STR X17 X16 0))))

(define-instruction LOAD-OOP	(false 0 true)
  ((STACK-CELL)			(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (MOVi X17 8)
                                (MUL X16 X16 X17)
                                (ADDr X16 X0 X16)
                                (LDR X0 X16 0))
  ((LI64)			(let ((offset (* (<LITERAL>-value $1) 8)))
                                  (cond
                                    ((= 0 offset)
                                     (LDR X0 X0 0))
                                    ;; the LDR imm12 is unsigned; negative
                                    ;; offsets need to go through a register
                                    ((<= 0 offset 4095)
                                     (ADDi X0 X0 offset)
                                     (LDR X0 X0 0))
                                    (else
                                     (MOVi X16 offset)
                                     (ADDr X0 X0 X16)
                                     (LDR X0 X0 0))))))

;; object is in X0 (base); args: index, value
(define-instruction STORE-OOP	(false 0 true)
  ((STACK-CELL STACK-CELL)	(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (LDUR X17 FP (<STACK-CELL>-offset $2))
                                (MOVi X15 8)
                                (MUL X16 X16 X15)
                                (ADDr X16 X0 X16)
                                (STR X17 X16 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVr X0 X17)))
  ((LI64 LI64)			(MOVi X16 (* (<LITERAL>-value $1) 8))
                                (ADDr X16 X0 X16)
                                (MOVi X17 (<LITERAL>-value $2))
                                (STR X17 X16 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVr X0 X17)))
  ((STACK-CELL LI64)		(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (MOVi X15 8)
                                (MUL X16 X16 X15)
                                (ADDr X16 X0 X16)
                                (MOVi X17 (<LITERAL>-value $2))
                                (STR X17 X16 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVr X0 X17)))
  ((LI64 STACK-CELL)		(MOVi X16 (* (<LITERAL>-value $1) 8))
                                (ADDr X16 X0 X16)
                                (LDUR X17 FP (<STACK-CELL>-offset $2))
                                (STR X17 X16 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVr X0 X17))))

;;; NOTE: in logical register instructions (e.g. ORR, i.e. MOVr) the
;;; register number 31 encodes XZR, not SP. SP can only be the target
;;; of ADD/SUB immediate ops. so we must use ADDi to move SP into FP.
(define-instruction ENTER-FRAME	()
  ((_)				(STPpre FP LP SP -2)
				(ADDi FP SP 0)
				(unless (= 0 $1)
				  (SUBi SP SP $1))))

(define-instruction LEAVE-FRAME	()
  ((_)				(ADDi SP FP 0)
				(LDPpost FP LP SP 2)
				(RET LP)))

(define-instruction SEXT	()
  ((R32 R64)			(SXTW (<REGISTER>-name $2) (<REGISTER>-name $1))))

(define-form define-instruction/comparator (maru-name cond)
  `(define-instruction ,maru-name (true 0 true)
     ((R64 STACK-CELL)
      (LDUR X16 FP (<STACK-CELL>-offset $2))
      (CMPr (<REGISTER>-name $1) X16)
      (CSET (<REGISTER>-name $1) ,cond))
     ((R64 LI64)
      (let ((lit (<LITERAL>-value $2)))
        (if (= 0 lit)
            (CMPi (<REGISTER>-name $1) 0)
          ;; CMPi's imm12 is unsigned (0-4095), negative or large
          ;; values must go through a register
          (if (<= 0 lit 4095)
              (CMPi (<REGISTER>-name $1) lit)
            (begin
              (MOVi X16 lit)
              (CMPr (<REGISTER>-name $1) X16))))
        (CSET (<REGISTER>-name $1) ,cond)))))

(define-instruction/comparator LT 11)
(define-instruction/comparator LE 13)
(define-instruction/comparator EQ 0)
(define-instruction/comparator GE 10)
(define-instruction/comparator GT 12)
;;(define-instruction/comparator NE 1)

;;;
;;; Compiling lambdas
;;;

(let ((program-code-byte-offset (* (slave-value (record/slot-index <target-function> 'program-code)) 8)))
  (define-function compile-call-to-<target-function> (-c-)
    ;; TODO assert the type to be <target-function>
    ;; TODO assert nr of args = params
    ;; Load fn ptr into X16, NOT X0, because X0 holds arg1
    (emit MOVE $ op/X16)
    (when (feature emit-with-object-headers)
      ;; LOAD-OOP: load data[program-code-slot] from the object
      (if (= 0 program-code-byte-offset)
          (LDR X16 X16 0)
        (if (< program-code-byte-offset 4096)
            (begin
              (ADDi X16 X16 program-code-byte-offset)
              (LDR X16 X16 0))
          (begin
            (MOVi X17 program-code-byte-offset)
            (ADDr X16 X16 X17)
            (LDR X16 X16 0)))))
    (emit CALL op/X16)
    ()))

(define-method compile-call-to (slave-value <target-function>) (op -c-)
  (let* ((value self)
         (name (<target-function>-name value)))
    (when name
      (emit-comment 3 (string-append "// " name)))
    (if (feature redefinable-functions-in-target)
        (let ()
          (comp op)
          (compile-call-to-<target-function> -c-))
      (emit CALL (closure-code-label name))))
  ())

(define-function sf/stack-pointer-on-entry (expr -c-)
  ;; the usual function prologue that we also employ is like this:
  ;;
  ;; STP	FP, LP, [SP, #-16]!   ; push FP and LP
  ;; MOV	FP, SP
  ;; SUB	SP, SP, $n
  ;;
  ;; so, the 16(SP) is to undo the STP and SUB, so that we
  ;; regain the SP value at the entry point to the function.

  (ADDi X0 FP (eval-at-expand (* 2 target/cell-size/bytes)))
  (set (<compiler>-current-value -c-) op/X0))

(require "source/compiler/elf-late.l")

(define-function emit-expr-code (self entry-point-label parent-comp)
  ;;(assert (is <expr> self))
  ;; NOTE printing the code as-is, i.e. without escaping, may break the comment syntax
  (.align +function-alignmet+)

  (let* ((body		(<expr>-body self))
         (-c-		(compiler (+ 1 (<compiler>-level parent-comp))))
         (params	(<expr>-parameters self))
         (param-count	(list-length params))
         (frame-body-size (label)))

    (label! entry-point-label)
    ;; (emit-comment 1 "params: "(list-length (<expr>-parameters self))
    ;;               ", frame-size: "frame-size"("(/ frame-size target/cell-size/bytes)
    ;;               "), temp-size: "temp-size "("(/ temp-size  target/cell-size/bytes)")")
    (BTI-C)
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

      ;; spill the stack-passed params (args 9+) from FP to SP-relative cells
      (let ((i 2))        ; 2 is the pushed FP and LP
        (list-do var params
          (let* ((offset (* i target/cell-size/bytes))
                 (spill-cell (new-stack-cell -c-)))
            (LDR X0 FP (bitwise-shift offset -3))
            (STUR X0 FP (<STACK-CELL>-offset spill-cell))
            (set (<variable>-value var) spill-cell))
          (incr i)))

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
      ;; FIXME this uses the same .code suffix as closure-code-label,
      ;; but they are not bound together.
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
                                (emit STORE $ temp)
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
         ;; NOTE here we *must* store the arg values calculated by
         ;; expression into temps (as opposed to storing them straight
         ;; into the arg locations, i.e. first 6 into registers)
         ;; because the arg expression can be of any complexity;
         ;; i.e. they may call other functions, which would overwrite
         ;; the arg registers...

         ;; The (align ... 2) is needed to keep SP 16 byte aligned. We
         ;; sometimes leave an unused word on the stack, but that is
         ;; fine.
         (arg-stack-cell-count	(align (max 0 (- arg-count +n-param-registers+)) 2))
         (arg-regs	+param-registers+))

    ;; move the reg-passed operands into the regs
    (times-do (min arg-count +n-param-registers+)
      (emit MOVE (pop arg-operands) (pop arg-regs)))

    ;; The remaining args are passed through the stack. NOTE that on
    ;; aarch64 SP must always be 16-byte aligned when it is used in a
    ;; LDR or STR.

    (emit SUB op/SP (LI64 (* arg-stack-cell-count target/cell-size/bytes)))

    (let ((index 0))
      (list-do op arg-operands
        ;; TODO KLUDGE it should be this: (emit STORE op SP index) but
        ;; STORE has no offset... and STORE-OOP and STORE-CELL takes
        ;; the base implicitly in the accumulator.
        (typecase op
          (<R64>
           (STR (<REGISTER>-name op) SP index))
          (<LI64>
           (MOVi X16 (<LITERAL>-value op))
           (STR X16 SP index))
          (else (error "operand with unexpected type while storing arguments: "op ", " (type-of op))))
        (incr index)))

    (let* ((n-params	 (emit-comment 2 "compile-call-to: "op-value)
                         (compile-call-to op-value op -c-))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))
    (emit ADD op/SP (LI64 (* arg-stack-cell-count target/cell-size/bytes)))
    (free-temps tmps-to-free)))

(define-method compile-call-to <STACK-CELL> (op -c-)
  ;; Load fn ptr into X16, NOT X0, because X0 is arg 1 (already set up)
  (LDUR X16 FP (<STACK-CELL>-offset self))
  (when (feature emit-with-object-headers)
    (LDR X16 X16 (* (slave-value (record/slot-index <target-function> 'program-code)) 8)))
  (emit CALL op/X16)
  ())

(define-method compile-call-to <R64> (op -c-)
  ;; Move fn ptr to X16 to avoid clobbering arg 1 in X0
  (emit MOVE self op/X16)
  (when (feature emit-with-object-headers)
    (LDR X16 X16 (* (slave-value (record/slot-index <target-function> 'program-code)) 8)))
  (emit CALL op/X16)
  ())

;; TODO
;; (define-method compile-call-to <C-function> (op -c-)
;;   (let* ((c-function-entries	(<compiler>-c-function-entries -c-))
;;          (var			(defined? self.name c-function-entries))
;;          (c-function-entry	(if var
;;                                     (<variable>-value var)
;;                                   (let* ((ptr-label (with-new-label 'data
;;                                                       (.cell 0)))
;;                                          (stub-label (with-new-label 'code
;;                                                        ;; TODO
;;                                                        ))
;;                                          (entry ()))
;;                                     (environment-define c-function-entries self.name entry)
;;                                     entry))))
;;     )
;;
;;   (.segment 'data)
;;   (let ((fnptr (label))
;;         (stub  (flabel)))
;;     (.cell stub)
;;     (.segment 'code)
;;     (label stub)
;;     )
;;
;;   (emit CALL (EXTERNAL-LABEL (<C-function>-name self)))
;;   (case (<C-function>-return-type self)
;;     ;; TODO introduce a proper infrastructure for this
;;     (int
;;      (emit SEXT op/EAX op/RAX))
;;     (short
;;      (error "TODO sign-extend a short to 64 bits")))
;;   (unless (<C-function>-vararg? self)
;;     (list-length (<C-function>-parameter-types self))))

(define-function run-compiler (env output-path)
  (compile-env env (compiler 1) output-path
               elf/EM_AARCH64
               elf/R_AARCH64_RELATIVE))

(require "source/compiler/emit-late.l")
