;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits aarch64 machine code directly into an
;;; Elf64 executable.
;;;

;;; TODO
;;;  - factor out the C ffi stuff into a separate file

;;; It can compile a subset of Maru.
;;;
;;; Limitations and peculiarities:
;;;   - lambda's cannot capture variables
;;;   - no variable number of args for functions
;;;   - some literal objects are emitted as valid objects that can participate
;;;     in the heap; see the EMIT-OBJECT methods for an up-to-date list.
;;;   - probaby more
;;;   - see *special-operators* and *special-forms* for the list of specially
;;;     handled constructs
;;;
;;; Naming:
;;;   - EMIT: emit instructions into the output stream
;;;   - COMPILE: something more involved than a simple emit
;;;   - -foo- is an implicit var in the lexenv
;;;   - +foo+ is a constant
;;;   - *foo* is a global

(require "source/conversion.l")
(require "source/c/cffi.l")
(require "source/ansiterm.l")
(require "source/files.l")
(require "source/assembler/single-pass-arm.l")

(require "source/c/cgrov.l")
(require-cgrov "source/platforms/linux/linux")
(require-cgrov "source/platforms/linux/elf")

(require "source/compiler/elf-early.l")

;; forwards
(define compile-expr)

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

(define-constant +param-registers+   `(quote ,(list op/X0 op/X1 op/X2 op/X3 op/X4 op/X5 op/X6 op/X7)))
(define-constant +n-param-registers+ (list-length +param-registers+))

(define-constant +callee-saved-registers+   `(quote ,(list op/X19 op/X20 op/X21 op/X22 op/X23 op/X24 op/X25 op/X26 op/X27 op/X28)))
(define-constant +n-callee-saved-registers+ (list-length +callee-saved-registers+))

(define-constant +accumulator-register+ op/X0)

(require "source/compiler/elf.l")

;;;
;;; Emission
;;;

(define-form emit (instr-name . args)
  `(%emit -c- ,instr-name (list ,@(map (lambda (arg)
                                         (if (= '$ arg)
                                             '(<compiler>-current-value -c-)
                                           arg))
                                       args))))

(define-function %emit (-c- factory args)
  (let* ((instr (factory ())))
    (when (and (<= 3 *compiler-verbosity*)
               (not (is <COMMENT> instr)))
      ;; TODO move this into emit-instruction?
      (print-all *debug-output* "; EMIT of "instr", args: "args"\n"))
    (apply emit-instruction (cons -c- (cons instr args)))))

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit-comment 2 "COMPILE of "__obj__)
     ;;(assert (= (get-segment 'code) (current-segment)))
     (compile __obj__ -c-)
     (<compiler>-current-value -c-)))

(define-selector compile-object)
(define LOAD) ; forward
(define-selector compile (self -c-)
  (emit LOAD (compile-object self -c-)))
(define-selector compile-definition)
(define-selector compile-call-to)
(define-selector emit-prelude _) ; default is NOP

(define *special-forms*) ; forward
(define compile-call-form) ; forward

;; TODO ? introduce abstraction for ABIs...
(define-constant +call-frame-alignmet+
    (case (target-value +word-size-in-bits+)
      (32 (case (target-value +operating-system+)
            (darwin	16)
            (else	4)))
      (64 16)))

(define-constant +function-alignmet+ 16)

(define-record <c-function-entry> ()
  (ptr-label
   stub-label))

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
  ((STACK-CELL STACK-CELL)	(LDUR X16 FP (<STACK-CELL>-offset $1))
                                (STUR X16 FP (<STACK-CELL>-offset $2)))
  ((R64 STACK-CELL)		(STUR (<REGISTER>-name $1) FP (<STACK-CELL>-offset $2)))
  ((STACK-CELL R64)		(LDUR (<REGISTER>-name $2) FP (<STACK-CELL>-offset $1)))
  ((R64 R64)			(MOVr (<REGISTER>-name $2) (<REGISTER>-name $1))))

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

(when-at-expand (feature lower/array)
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

(define-instruction PUSH	()
  ((LI64)			(MOVi X16 (<LITERAL>-value $1))
                                (SUBi SP SP 8)
                                (STR X16 SP 0))
  ((R64)			(SUBi SP SP 8)
                                (STR (<REGISTER>-name $1) SP 0)))

(define-instruction POP		()
  ((R64)			(LDR (<REGISTER>-name $1) SP 0)
                                (ADDi SP SP 8)))

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

;; a vector of assoc lists indexed by operator arity
(define *special-operators*
    (let ((table
           `(;; nullary
             ()
             ;; unary
             ((-  ,NEGATE) (not ,LOGIC-NOT) (bitwise-not ,BITWISE-NOT))
             ;; binary
             ((+  ,ADD) (-   ,SUB) (* ,MULTIPLY) (/ ,DIVIDE)
              (bitwise-and ,AND) (bitwise-or ,OR) (bitwise-xor ,XOR)
              (<  ,LT ) (<=  ,LE ) (= ,EQ ) (>= ,GE) (> ,GT) ; (!= ,NE)
              (arithmethic-shift-left ,ASL) (arithmethic-shift-right  ,ASR)
              (char-at		,LOAD-I8)
              (byte-at		,LOAD-I8)
              ,@(when-at-expand (feature lower/array)
                  `((cell-at	,LOAD-CELL)))
              (oop-at		,LOAD-OOP)
             )
             ;; ternary
             ((set-char-at	,STORE-I8)
              (set-byte-at	,STORE-I8)
              ,@(when-at-expand (feature lower/array)
                  `((set-cell-at ,STORE-CELL)))
              (set-oop-at	,STORE-OOP)
             ))))
      (list->array
       (map (lambda (arity-line)
              (map (lambda (entry)
                     (let* ((op-name (car entry))
                            (op (eval-in-target op-name)))
                       (assert op "operator not found while building *special-operators* "op)
                       (cons op (cdr entry))))
                   arity-line))
            table))))

;;;
;;; Compiling lambdas
;;;
(define-function compile/expression-to-operand (expr -c-)
  (cond
    ((and (variable? expr)
          ;; TODO we should handle global variables, too.
          (let ((x (<variable>-value expr)))
            (or (is <STACK-CELL>	x)
                (is <LI64>		x)
                (is <LI32>		x))))
     ;; (let ((value (<variable>-value expr)))
     ;;   (print-all *debug-output* "*** matched: "expr"="value", type:" (type-of value) "\n")
     ;;   value)
     (<variable>-value expr))

    ((long? expr)
     (LI64 expr))

    (else
     ;; (when (variable? expr)
     ;;   (let ((value (<variable>-value expr)))
     ;;     (assert (global-variable? expr))
     ;;     (print-all *debug-output* "*** matched: "expr"="value", type:" (type-of value) "\n")
     ;;     value))
     (comp expr))))

(define-function compile/expr-into-temp-or-literal (expr -c-)
  (cond
    ((long? expr)
     (LI64 expr))
    (else
      (comp expr)
      (let ((temp (alloc-stack-temp -c-)))
        (emit STORE $ temp)
        temp))))

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

(define-function closure-code-label (name)
  (label (if (feature emit-with-object-headers)
             (concat-symbol name '.code)
           name)))

(define-function compile-call-to-global-function (op -c-)
  (if (feature redefinable-functions-in-target)
      (let ()
        (comp op)
        (compile-call-to-<target-function> -c-))
    (emit CALL (closure-code-label (<variable>-name op))))
  ())

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

;; this case is handled early in compile-call
;; (define-method compile-call-to <pair> (op -c-)
;;   (comp op)
;;   (compile-call-to-<target-function> -c-))

(define-method compile-call-to <expr> (op -c-)
  ;; NOTE the fact that a literal <expr> is found in a variable's
  ;; value slot at compile time implies that it's a global definition.
  (compile-call-to-global-function op -c-)
  (expr-n-required-parameters self))

(define-method compile-call-to (slave-value <selector>) (op -c-)
  (compile-call-to-global-function op -c-)
  ;; TODO extract and return n-params
  ())

;;;
;;; Special Forms
;;;

(define-function compile/expressions-into-temp (prog -c-)
  (assert (pair? prog) "compile/expressions-into-temp: prog is empty or not a list") ; this is against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  ;; NOTE it's tempting here to check for single-element prog's, and
  ;; turning them into a compile/expression, but our single caller,
  ;; namely compile/let, requires a temp location, even when
  ;; initialized to literal values.
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-stack-temp -c-)))
    (emit STORE $ temp)
    temp))

(define-function compile/let-binding (binding comp)
  ;; we unconditionally initialize empty bindings to () to avoid hidden bugs,
  ;; at a small cost of initializing temp locations even when it wouldn't be necessary.
  ;; TODO cleanup! expand now brings let bindings to a normal form (to ease encode's job). think this through...
  (unless (pair? binding)
    (set binding (list binding ())))
  (unless (cdr binding)
    (set binding (list (car binding) ())))
  (let ((var (car binding))
        (tmp (compile/expressions-into-temp (cdr binding) comp)))
    (assert (= (type-of var) <variable>) "compile/let-binding: encountered a non-variable: " var)
    (set (<variable>-value var) tmp)))

(define-function compile/let (expr -c-)
  (let ((temps (map-with compile/let-binding (caddr expr) -c-)))
    (list-do stmt (cdddr expr)
      (comp stmt))
    (free-temps temps)))

(define-function compile/and (expr -c-)
  (let ((done (label)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (emit BF $ done)))
    (label! done)))

(define-function compile/or (expr -c-)
  (let ((done (label)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (emit BT $ done)))
    (label! done)))

(define-function compile/if (expr -c-)
  (let ((condition	(second expr))
        (then		(third expr))
        (else		(cdddr expr))
        (l/false	(label))
        (l/end		(label)))
    (comp condition)
    ;; the current-value from the condition is false when we jump to
    ;; the else branch, therefore we don't need to clear the
    ;; current-value when the else branch is empty.
    (emit BF $ l/false)
    (comp then)
    ;; therefore, we can just fall through with the return value of
    ;; the true branch when the else branch is empty.
    (when else
      (emit BR l/end))
    (label! l/false)
    (list-do stmt else
      (comp stmt))
    (label! l/end)))

(define-function compile/while (expr -c-)
  (let ((l/body	(label))
        (l/cond	(label))
        (body	(cddr expr)))
    (when body ; only need to skip it at first if there's any at all
      (emit BR l/cond))
    (label! l/body)
    (list-do stmt body
      (and stmt (comp stmt)))
    (label! l/cond)
    (comp (second expr))
    (emit BT $ l/body)))

(define-function compile/return (expr -c-)
  (list-do stmt (cdr expr)
    (comp stmt))
  (emit BR (or (<compiler>-fn-epilogue-label -c-)
               (set (<compiler>-fn-epilogue-label -c-) (label)))))

(define-function emit-object/C-string (self -c-)
  (emit-comment 3 "emit-object/C-string for: "self)
  (GLOBAL-ADDR
   (with-new-label 'ro-data
     (.ascii self)
     (.i8 0))))

(define-function compile/C-string (expr -c-)
  (assert (= (list-length expr) 2))
  (emit LOAD (emit-object/C-string (second expr) -c-)))

(define-method compile-object <string> (-c-)
  (emit-object/C-string self -c-))

(define-method compile-object <undefined> (-c-)
  (LI64 (target-value false)))

(define-function compile/lambda (form -c-)
  (let ((expr (eval form)))
    (emit LOAD (compile-expr expr () -c-))))

;;;
;;; Special Operators
;;;

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  ;; FIXME we shouldn't need to instantiate the instructions here...
  (let ((instr (op ())))
    (if (<instruction>-has-input? instr)
        (emit op $)
      (emit op))))

;; FIXME? these implement a right-to-left evaluation order, while
;; function calls implement the opposite. note that this is entangled
;; with e.g. the LOAD/STORE instructions above, as they expect arg0 to
;; be loaded in %rax.
(define-function compile/binary-operator (op args -c-)
  (let ((tmp (compile/expr-into-temp-or-literal (cadr args) -c-)))
    (comp (car args))
    (free-temp tmp)
    (let ((instr (op ())))
      (if (<instruction>-has-input? instr)
          (emit op $ tmp)
        (emit op tmp)))))

(define-function compile/ternary-operator (op args -c-)
  (let ((tmp2 (compile/expr-into-temp-or-literal (third  args) -c-))
        (tmp1 (compile/expr-into-temp-or-literal (second args) -c-)))
    (comp (car args))
    (free-temp tmp1)
    (free-temp tmp2)
    (let ((instr (op ())))
      (if (<instruction>-has-input? instr)
          (emit op $ tmp1 tmp2)
        (emit op tmp1 tmp2)))))

(define +operator-compilers+ (list->array (list () compile/unary-operator compile/binary-operator compile/ternary-operator)))

(define-method compile <pair> (-c-)
  (let* ((op		(first self))
         (op-is-a-var?	(variable? op))
         (op-value	(if op-is-a-var?
                            (or (<variable>-value op)
                                (error "error: calling undefined function: "op))
                          op))
         (args		(rest self))
         (arity		(list-length args))
         (handler	()))
    (emit-comment 2 "call of op: "op", op-is-a-var? "op-is-a-var?", args: " args)
    ;; TODO add compiler-macros. use them to optimize stuff on the lisp semantic level
    (cond
      ((set handler (second (assq op-value (array-at *special-operators* arity))))
       (emit-comment 3 "found op "op" in *special-operators*, handler: "handler)
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((is <fixed> op)
       (let ((handler (cdr (assq op *special-forms*))))
         (emit-comment 3 "op is a <fixed>: "op", handler: "handler)
         (or handler (error "No handler for fixed form: " self))
         (handler self -c-)))
      (else
       (compile-call-form op args -c-)))))

;;;
;;; x86-64 -- INSTRUCTIONS
;;;

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

;;;
;;; Compiling lambdas
;;;

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
    ;;               ", frame-size: "frame-size"("(/ frame-size +word-size-in-bytes+)
    ;;               "), temp-size: "temp-size "("(/ temp-size  +word-size-in-bytes+)")")
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
      (let ((i 2))        ; 2 is the pushed FP and LP (return address)
        (list-do var params
          (let ((offset (* i +word-size-in-bytes+)))
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
          (let* ((offset (* i +word-size-in-bytes+))
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
                           +word-size-in-bytes+))
             (frame-size	(align +call-frame-alignmet+
                                       (+ temp-size
                                          ;; the pushed %ebp and the return address
                                          (* 2 +word-size-in-bytes+)))))

        (label! frame-body-size (- frame-size (* 2 +word-size-in-bytes+)))

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
         (arg-stack-cell-count	(max 0 (- arg-count +n-param-registers+)))
         (arg-regs	+param-registers+))

    ;; move the reg passed operands into the regs
    (times-do (min arg-count +n-param-registers+)
      (emit MOVE (pop arg-operands) (pop arg-regs)))

    ;; push the remaining (i.e. stack-passed) arguments in reverse order
    (list-do op (list-reverse! arg-operands)
      (emit PUSH op))

    (let* ((n-params	 (emit-comment 2 "compile-call-to: "op-value)
                         ;; FIXME delete unused arg-locs
                         (compile-call-to op-value op -c-))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))
    (emit ADD op/SP (LI64 (* arg-stack-cell-count +word-size-in-bytes+)))
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
  (unless (= X16 (<REGISTER>-name self))
    (emit MOVE self op/X16))
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

;;;
;;; Special Forms
;;;
(define-function compile/set (expr -c-)
  (let* ((var	(second expr))
         (value	(<variable>-value var)))
    (accessible-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ((or (is <STACK-CELL> value)
           (is <R64> value))
       (emit STORE $ value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (error "TODO <C-variable>")
       ;; (emit STORE $ ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
       ;;             (EXTERNAL-LABEL (<C-variable>-name value))))
       )
      (else
       (emit STORE $ (GLOBAL-CELL (label (<variable>-name var))))))))

(define-function compile/address-of (expr -c-)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (cond
        ((global-variable? var)
         (emit ADDR (GLOBAL-CELL (label (<variable>-name var)))))
        ((is <STACK-CELL> val)
         (emit ADDR val))
        ;; ((is <R64> val)
        ;;  (maybe-spill-params -c-)
        ;;  (emit ADDR (<variable>-value var)))
        (else
         (error "address-of: don't know how to compile for variable " var ", holding the value " val))))))

;;;
;;; *special-forms*
;;;
(define *special-forms* (list
  (cons (target-value let)		compile/let)
  (cons (target-value and)		compile/and)
  (cons (target-value or)		compile/or)
  (cons (target-value if)		compile/if)
  (cons (target-value while)		compile/while)
  (cons (target-value set)		compile/set)
  (cons (target-value lambda)		compile/lambda)
  (cons (target-value return)		compile/return)
  (cons (target-value address-of)	compile/address-of)
  (cons (target-value C-string)		compile/C-string)
  (cons (target-value stack-pointer-on-entry)
        (lambda (expr -c-)
          ;; the function prologue we also employ is like this:
          ;;
          ;; stp	x29, x30, [sp, #-16]!
          ;; mov	x29, sp
          ;; sub	sp, sp, $n
          ;; ...
          ;;
          ;; so, the 16(sp) is to undo the stp and sub, so that we
          ;; regain the sp value at the entry point to the function.

          (ADDi X0 FP 16)
          (set (<compiler>-current-value -c-) op/X0)))
  ))

;;;
;;; Special Operators
;;;

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (is <R64> value)
           (is <LI64> value)
           (is <STACK-CELL> value)
           (is <STACK-PARAM> value))
       (emit LOAD value))
      ((global-variable? self)
       (cond
         ((= 'true self.name)
          (emit LOAD (LI64 (target-value true))))
         ((subtype? (type-of value) <type>)
          (emit LOAD (LI64 (eval-in-slave `(<type>-slave-id ,value)))))
         ((is <C-function> value) ; handles the situation when e.g. libc/strcmp is passed as a comparator fn for array-binary-search
          (error "TODO <C-function>")
          ;;(emit LOAD (EXTERNAL-LABEL (<C-function>-name value)))
          )
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (error "TODO <C-variable>")
          ;; (emit LOAD ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
          ;;            (EXTERNAL-LABEL (<C-variable>-name value))))
          )
         ((and (not (feature redefinable-functions-in-target))
               (is <expr> value))
          (emit LOAD (GLOBAL-ADDR (label self.name))))
         (else
          (emit LOAD (GLOBAL-CELL (label self.name))))))
      (else
       (error "don't know how to compile <variable>: " self ", holding the value: "value", type: "(type-of value))))))

(define-method compile <long> (-c-)
  ;; FIXME: We can't call COMPILE-OBJECT here, because that would box
  ;; the value. But then why the lack of symmetry with <string> and
  ;; other literals in the code (they are emitted as full heap objects)?
  (emit LOAD (LI64 self)))

;;;
;;; COMPILE-DEFINITION
;;;
;; TODO a lot of this is the same in the 32 bits
(define-method compile-definition <type>		(name -c-)	) ; we don't need (target-value <type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition (target-value false) name -c-))
(define-method compile-definition <C-function>		(name -c-)	) ; it will be handled at the call site
(define-method compile-definition <C-variable>		(name -c-)	) ; it will be handled at the site of reference

(define-method compile-definition <long> (name -c-)
  (with-current-segment (if (= 0 self) 'bss 'data)
    (label! name)
    (emit-symtab-entry/variable name
                                (if (= 0 self) +.bss-section-index+ +.data-section-index+)
                                (current-laddress)
                                +word-size-in-bytes+)
    (emit CELL self)))

;; kinda KLUDGE
;; this is used when emitting the literal dispatch tables of <selectors>
;; FIXME merge this somehow into the compile-object protocol?
;; this, and the whole emit-object business is kinda KLUDGEy
(define-function compile-array (self -c-)
  (let ((compiled (array (array-length self))))
    (for (i 0 (array-length self))
      (let ((obj (array-at self i)))
        (set (array-at compiled i)
             (typecase obj
               (<long>		(compile-object obj -c-))
               (<expr>		(compile-expr   obj () -c-))
               (<undefined>	(compile-object obj -c-))
               (else (error "compile-array: don't know how to compile: "obj))))))
    compiled))

(define-method compile-definition <array> (name -c-)
  (let ((compiled (compile-array self -c-)))
    (with-current-segment 'data
      (label! name)
      (emit-symtab-entry/variable name
                                  +.data-section-index+
                                  (current-laddress)
                                  +word-size-in-bytes+)
      (array-do el compiled
        (emit CELL el)))))

(define-method compile-definition <expr> (name -c-)
  (assert name)
  (let ((object-label (compile-expr self name -c-)))
    (when (feature redefinable-functions-in-target)
      (with-current-segment 'data
        (label! name)
        (emit CELL object-label)))))

(define-constant +n-program-headers+ 8)
(define-constant +n-section-headers+ 11)
(define-constant +elf-prefix-size+ (+ elf/sizeof-Elf64_Ehdr
                                      (* +n-program-headers+
                                         elf/sizeof-Elf64_Phdr)
                                      (* +n-section-headers+
                                         elf/sizeof-Elf64_Shdr)))

(define-constant +code-segment-address+		0x00000000)
(define-constant +data-segment-address+		0x00040000)
(define-constant +bss-segment-address+		0x00050000)
(define-constant +ro-data-segment-address+	0x00100000)

(define-function write-elf-to-stream (stream)
  (.segment	'code)
  (.align	elf/page-size)

  (.segment	'data)
  (.align	elf/page-size)

  (.segment	'ro-data)
  (label!	'elf-interpreter-start)
  (.ascii	+ld.so-path+)
  (.i8		0)
  (label!	'elf-interpreter-end)

  (.align	elf/page-size)

  (create-segment 'elf-prefix)
  (.segment 'elf-prefix)
  (.base 0) ; without this the laddress is random, which disrupts .align

;;;
;;; ELF header
;;;
  (label!	'elf-header-start)
  (.i8		0x7f)                   ; ident[0]
  (.ascii	"ELF")
  (.i8		elf/ELFCLASS64 elf/ELFDATA2LSB 1 elf/ELFOSABI_NONE) ; version
  (.i8		0 0 0 0 0 0 0 0) ; EI_ABIVERSION and padding (total 16 ident bytes)
  (.i16		elf/ET_DYN)      ; e_type
  (.i16		elf/EM_AARCH64)   ; e_machine
  (.i32		1)               ; e_version
  (.i64		(closure-code-label '_start)) ; e_entry (entry point)
  (.i64		(label 'program-headers	(- self (laddress 'elf-header-start)))) ; e_phoff	Start of program headers (file offset)
  (.i64		(label 'section-headers	(- self (laddress 'elf-header-start)))) ; e_shoff	Start of section headers
  (.i32		0)               ; e_flags
  (.i16		(label 'elf-header-end	(- self (laddress 'elf-header-start)))) ; e_ehsize	Size of this header
  (.i16		elf/sizeof-Elf64_Phdr) ; e_phentsize	Size of program header entry
  (.i16		+n-program-headers+)   ; e_phnum	Number of program headers
  (.i16		elf/sizeof-Elf64_Shdr) ; e_shentsize	Size of section header
  (.i16		+n-section-headers+)   ; e_shnum	Number of section headers
  (.i16		+.shstrtab-section-index+) ; e_shstrndx	Section header string table index
  (label!	'elf-header-end)

  (assert (= (- (laddress 'elf-header-end) (laddress 'elf-header-start)) elf/sizeof-Elf64_Ehdr))

;;;
;;; Program headers (segment layout)
;;;
  (label! 'program-headers)

  ;; code segment
  (let* ((file-position		0)
         (file-offset/text	file-position)
         ;; the elf header is included into the code segment as per convention
         (size/text		(+ (segment-length 'code) +elf-prefix-size+))
         file-offset/ro-data
         size/ro-data
         file-offset/data
         size/data
         size/bss
         size/relocation-tables)

    ;; PT_PHDR
    (let ((size
            ;; TODO FIXME? this yields different values for the two sizes emitted. but why?
            ;; (label 'program-headers-end (- self (laddress 'program-headers)))
            ;; (label 'program-headers-end (- (laddress 'program-headers-end) (laddress 'program-headers)))
            (* +n-program-headers+
               elf/sizeof-Elf64_Phdr)))
      (emit-program-header elf/PT_PHDR
                           (paddress 'program-headers)
                           size size
                           elf/PF_R
                           (laddress 'program-headers)
                           8))

    ;; text segment
    (emit-program-header elf/PT_LOAD
                         file-offset/text
                         size/text size/text
                         (+ elf/PF_R elf/PF_X)
                         +code-segment-address+
                         elf/page-size)
    (incr file-position size/text)

    ;; NOTE: program headers must be emitted in increasing vaddr order
    ;; for ld-linux to process them correctly. The file-position
    ;; computation tracks the file layout order (text, ro-data, data),
    ;; but the headers are emitted in vaddr order.

    ;; ro-data segment - precompute: data and bss offsets depend on ro-data size
    (set size/ro-data (segment-length 'ro-data))
    (set file-offset/ro-data file-position)

    ;; data segment
    (set size/data (segment-length 'data))
    (set file-offset/data (+ file-offset/ro-data size/ro-data))
    (emit-program-header elf/PT_LOAD
                         file-offset/data
                         size/data size/data
                         (+ elf/PF_R elf/PF_W)
                         +data-segment-address+
                         elf/page-size)
    (incr file-position size/data)

    ;; BSS, aka zero-initialized data
    (set size/bss (segment-length 'bss))
    (when (= 0 size/bss)
      ;; zero is illegal, and not emitting is more trouble than just
      ;; setting it to 1.
      (set size/bss 1))
    (emit-program-header elf/PT_LOAD
                         (+ file-position size/ro-data)
                         0 size/bss
                         (+ elf/PF_R elf/PF_W)
                         +bss-segment-address+
                         elf/page-size)

    ;; ro-data segment
    (emit-program-header elf/PT_LOAD
                         file-offset/ro-data
                         size/ro-data size/ro-data
                         (+ elf/PF_R elf/PF_W)
                         +ro-data-segment-address+
                         elf/page-size)
    (incr file-position size/ro-data)

    ;; mark the entire ro-data segment to become read-only after
    ;; relocation is finished. note that it's possible to mark only a
    ;; subset of it using this extra PT_GNU_RELRO program header.
    (emit-program-header elf/PT_GNU_RELRO file-offset/ro-data
                         size/ro-data size/ro-data
                         elf/PF_R
                         +ro-data-segment-address+
                         elf/page-size)

    ;; data segment continues after ro-data in the file
    (incr file-position size/data)

    ;; PT_INTERP segment (dynamic linker path)
    ;; NOTE: PT_INTERP doesn't add file content - it references existing .rodata content
    (let ((interp-size (- (laddress 'elf-interpreter-end)
                          (laddress 'elf-interpreter-start))))
      (emit-program-header elf/PT_INTERP
                           (+ file-offset/ro-data
                              (paddress 'elf-interpreter-start))
                           interp-size interp-size
                           elf/PF_R
                           (laddress 'elf-interpreter-start)
                           1))

    (set size/relocation-tables (- (laddress '.dynamic-end)
                                   (laddress '.dynamic)))
    (emit-program-header elf/PT_DYNAMIC
                         (+ file-offset/ro-data
                            (paddress '.dynamic))
                         size/relocation-tables size/relocation-tables
                         elf/PF_R
                         (laddress '.dynamic)
                         8)

    (label! 'program-headers-end)

    (label! 'section-headers)

    ;; section #0 must be NULL
    (emit-section-header 0 0 0 0 0 0 0 0 0 0)

;;;
;;; This is fragile for reordering, must be in sync with the
;;; +.*-section-index+ constants.
;;;

    ;; section #1
    (emit-section-header (emit-shstrtab-entry ".text")
                         elf/SHT_PROGBITS
                         (+ elf/SHF_ALLOC elf/SHF_EXECINSTR)
                         +code-segment-address+
                         file-offset/text
                         size/text
                         0 0 16 0)

    ;; section #2
    (emit-section-header (emit-shstrtab-entry ".rodata")
                         elf/SHT_PROGBITS
                         elf/SHF_ALLOC
                         +ro-data-segment-address+
                         file-offset/ro-data
                         size/ro-data
                         0 0 16 0)

    ;; section #3
    (emit-section-header (emit-shstrtab-entry ".data")
                         elf/SHT_PROGBITS
                         (+ elf/SHF_ALLOC elf/SHF_WRITE)
                         +data-segment-address+
                         file-offset/data
                         size/data
                         0 0 16 0)

    ;; section #4
    (emit-section-header (emit-shstrtab-entry ".bss")
                         elf/SHT_NOBITS
                         (+ elf/SHF_ALLOC elf/SHF_WRITE)
                         +bss-segment-address+
                         0
                         size/bss
                         0 0 16 0)

    ;; section #5: .dynamic
    (emit-section-header (emit-shstrtab-entry ".dynamic")
                         elf/SHT_DYNAMIC
                         (+ elf/SHF_ALLOC elf/SHF_WRITE)
                         (laddress '.dynamic)
                         (+ file-offset/ro-data
                            (paddress '.dynamic))
                         size/relocation-tables
                         +.dynstr-section-index+
                         0 8 elf/sizeof-Elf64_Dyn)

    ;; section #6: .rela.dyn
    (emit-section-header (emit-shstrtab-entry ".rela.dyn")
                         elf/SHT_RELA
                         (+ elf/SHF_ALLOC elf/SHF_WRITE)
                         (laddress '.rela.dyn)
                         (+ file-offset/ro-data
                            (paddress '.rela.dyn))
                         (- (laddress '.rela.dyn-end)
                            (laddress '.rela.dyn))
                         0 0 8 elf/sizeof-Elf64_Rela)

    ;; section #7: .dynstr
    (let ((name-offset		(emit-shstrtab-entry ".dynstr")))
      (emit-section-header name-offset
                           elf/SHT_STRTAB 0 0
                           (+ file-offset/ro-data
                              (paddress '.dynstr))
                           (- (laddress '.dynstr-end)
                              (laddress '.dynstr))
                           0 0 1 0))

    ;; section #8: .symtab
    (let ((size/symtab (segment-length '.symtab))
          (symtab-offset file-position))
      (emit-section-header (emit-shstrtab-entry ".symtab")
                           elf/SHT_SYMTAB
                           0 0
                           symtab-offset
                           size/symtab
                           +.strtab-section-index+
                           (/ size/symtab elf/sizeof-Elf64_Sym)
                           8
                           elf/sizeof-Elf64_Sym)
      (incr file-position size/symtab))

    ;; section #9: .strtab
    (let ((size/strtab (segment-length '.strtab)))
      (emit-section-header (emit-shstrtab-entry ".strtab")
                           elf/SHT_STRTAB 0 0
                           file-position
                           size/strtab 0 0 1 0)
      (incr file-position size/strtab))

    ;; section #10: .shstrtab
    (let* ((name-offset		(emit-shstrtab-entry ".shstrtab"))
           (size/shstrtab	(segment-length '.shstrtab)))
      (emit-section-header name-offset
                           elf/SHT_STRTAB 0 0
                           file-position
                           size/shstrtab
                           0 0 1 0))

    )

  ;; we can start writing the file. note that the order must be in
  ;; sync with the headers above.
  (list-do name '(elf-prefix code ro-data data ; bss is discarded
                  .symtab .strtab .shstrtab)
    (write-segment-to-stream name stream)))

(define-function emit-relocation-tables ()
  (with-current-segment 'ro-data
    (.align elf/alignof-Elf64_Rela)
    (label! '.rela.dyn)
    (let ((rela-count 0))
      (let ((code-segment		(get-segment 'code))
            (data-segment		(get-segment 'data))
            (ro-data-segment	(get-segment 'ro-data)))
        (list-do entry (list-reverse *rela-entries*)
          (let* ((segment	(first entry))
                 (paddress	(second entry))
                 (addend	(third entry))
                 (segment-base
                   ;; NOTE CASE would do something else for symbols... (they would get quoted due to self-evaluating-value?)
                   ;; FIXME clean this up
                   (cond
                     ((= segment code-segment)	+code-segment-address+)
                     ((= segment data-segment)	+data-segment-address+)
                     ((= segment ro-data-segment)	+ro-data-segment-address+)
                     (else (error "unexpected segment in .rela.dyn emission: "segment)))))
            ;; Elf64_Rela entry (3 cells):
            ;; 1. r_offset: byte offset in file where relocation applies (paddress + segment file offset)
            (.i64 (+ segment-base paddress))
            ;; 2. r_info: relocation type (R_AARCH64_RELATIVE = 1027)
            (.i64 elf/R_AARCH64_RELATIVE)
            ;; 3. r_addend: constant addend for relocation (0 for pure relative)
            (.i64 addend
                  ;;(+ segment-base paddress)
                  ))
          (incr rela-count)))
      (label! '.rela.dyn-end)

      (label! '.dynstr)
      (.i8 0)
      (label! '.dynstr-end)

      (.align elf/alignof-Elf64_Sym)
      (label! '.dynsym)
      (.i64 0 0 0) ; TODO better express elf/sizeof-Elf64_Sym number of zero bytes

      ;; minimal SysV hash table for the dummy symbol above (nbucket,
      ;; nchain, one empty bucket, one terminating chain entry). musl
      ;; >=1.2.4 unconditionally looks up "malloc" in every loaded dso
      ;; during startup, and its sysv_lookup derefs dso->hashtab; a
      ;; symtab without a hash table crashes the process there.
      (label! 'dt-hash)
      (.i32 1 1 0 0)

      ;; Dynamic Linking Metadata Table
      (label! '.dynamic)
      ;; Elf64_Dyn struct entries, which really are just (name, tag) tuples
      (.i64 elf/DT_RELA		(laddress '.rela.dyn))
      (.i64 elf/DT_RELASZ	(* rela-count elf/sizeof-Elf64_Rela))
      (.i64 elf/DT_RELAENT	elf/sizeof-Elf64_Rela)
      (.i64 elf/DT_RELACOUNT	rela-count)
      (.i64 elf/DT_STRTAB	(laddress '.dynstr))
      (.i64 elf/DT_STRSZ	1)
      (.i64 elf/DT_SYMTAB	(laddress '.dynsym))
      (.i64 elf/DT_SYMENT	elf/sizeof-Elf64_Sym)
      (.i64 elf/DT_HASH		(laddress 'dt-hash))
      (.i64 elf/DT_NULL		0))
    (label! '.dynamic-end)))

(define-function compile-env (env -c- output-path)
  (verbosity 1
    (warn "begin compiling env with "(array-length (<env>-bindings env))" definitions\n\n")
    (map (lambda (sym)
           (warn (symbol->string sym)"	"(eval-in-slave sym)"\n"))
         '(+operating-system+ +architecture+ +little-endian?+
           +word-size-in-bits+
           ;;oop/alignment-in-bytes oop/align-padding
           ;;oop/payload-mask oop/tag-mask
           )))
  (comment-features)
  (emit-prelude -c-)
  ;; NOTE this array-do will not pick up any new definitions added to
  ;; the env after the iterations has begun (see e.g. the
  ;; COMPILE-DEFINITION of <selector>).
  (with-assembling (((code	(+ +code-segment-address+
                                   +elf-prefix-size+))
                     (ro-data	+ro-data-segment-address+)
                     (data	+data-segment-address+)
                     (bss	+bss-segment-address+)
                     (.shstrtab	0)
                     (.symtab	0)
                     (.strtab	0)))

    (.segment	'.shstrtab)
    (.i8	0)				; mandated by the elf standard

    (.segment	'.strtab)
    (.i8	0)				; mandated by the elf standard

    (.segment	'.symtab)
    (emit-symtab-entry 0 0 0 0 0 0)		; mandated by the elf standard

    ;; This is the default segment, and whoever changes it should make
    ;; sure changes it back by using WITH-CURRENT-SEGMENT,
    ;; WITH-NEW-LABEL, or similar constructs.
    (.segment 'code)

    (array-do var (<env>-bindings env)
      (let* ((name		(<variable>-name  var))
             (value		(<variable>-value var))
             (type-blacklist	(list <form> <fixed>))
             (name-blacklist	'()))
        (unless (or (member? (type-of value) type-blacklist)
                    (member? name name-blacklist))
          ;; (emit-comment 1 "defn "name)
          (verbosity 1 (warn name ", "))
          (compile-definition value name -c-))))

    (emit-relocation-tables)

    (with-open-file (file output-path "w")
      (write-elf-to-stream (file-stream file)))

    (when (<= 1 *compiler-verbosity*)
      (array-do var (<env>-bindings (<assembler>-env *assembler*))
        (let ((value (<variable>-value var)))
          (when (is <label> value)
            (emit COMMENT (list "0x"(integer->string (<label>-laddress value) 16)
                                "\t" (<variable>-name var))))))))
  (verbosity 1 (warn "\n")))

(define-function run-compiler (env output-path)
  (compile-env env (compiler 1) output-path))

(require "source/compiler/emit-late.l")
