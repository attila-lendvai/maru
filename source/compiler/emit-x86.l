;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits x86-64 machine code directly into an
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

(require "source/compiler/emit-early.l")
(require "source/ansiterm.l")
(require "source/files.l")
(require "source/assembler/single-pass-x86.l")

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
    ((x ((ctor . registers)
         (let ((index -1))
           `(begin
             ,@(map (lambda (reg)
                      (incr index)
                      ;; the op/ prefix stands for operand
                      `(define ,(concat-symbol 'op/ reg)
                         (,ctor ,reg ,index)))
                    registers))))))
  (x R32 EAX EBX ECX EDX ESP EBP ESI EDI)
  (x R64 RAX RBX RCX RDX RSP RBP RSI RDI R8 R9 R10 R11 R12 R13 R14 R15))

(define-constant +param-registers+   `(quote ,(list op/RDI op/RSI op/RDX op/RCX op/R8 op/R9)))
(define-constant +n-param-registers+ (list-length +param-registers+))

(define-constant +callee-saved-registers+   `(quote ,(list op/RBX op/R12 op/R13 op/R14 op/R15)))
(define-constant +n-callee-saved-registers+ (list-length +callee-saved-registers+))

;; TODO ? use +accumulator+ in the instructions and everywhere
;; else in general where relevant.
(define-constant +accumulator+		RAX)
(define-constant +op/accumulator+	op/RAX)

(require "source/compiler/elf.l")

;;;
;;; INSTRUCTIONS
;;;

(define-instruction BR		()
  ((label)			(JMPm $1 0 0 0)))

(define-instruction BF		(true 0 false)
  ((REGISTER label)		(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JE $2)))

(define-instruction BT		(true 0 false)
  ((REGISTER label)		(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JNE $2)))

(define-instruction CALL	(false 0 true)
  ((label)			(CALLQm $1 0 0 0))
  ((REGISTER)			(CALLQr (<REGISTER>-name $1))))

(define-instruction ADD		(true 0 true)
  ;; ((R32 STACK-CELL)		(ADDLmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ;; ((R32 LI32)			(let ((lit (<LITERAL>-value $2)))
  ;;                                 (unless (= lit 0)
  ;;       			    (ADDLir lit (<REGISTER>-name $1)))))
  ((R64 STACK-CELL)		(ADDQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((< -0x80000000 lit 0x80000000)
                                     (ADDQi32r lit reg))
                                    (else
                                     (MOVQi64r lit RBX)
                                     (ADDQrr RBX reg))))))

(define-instruction SUB		(true 0 true)
  ;; ((R32 STACK-CELL)		(SUBLmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ;; ;; TODO wtf? the order...
  ;; ((R32 LI32)			(let ((lit (<LITERAL>-value $2)))
  ;;                                 (unless (= lit 0)
  ;;       			    (SUBLir lit (<REGISTER>-name $1)))))
  ((R64 STACK-CELL)		(SUBQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ;; TODO wtf? the order...
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((< -0x80000000 lit 0x80000000)
                                     (SUBQi32r lit reg))
                                    (else
                                     (MOVQi64r lit RBX)
                                     (SUBQrr RBX reg))))))

(define-instruction MUL		(true 0 true)
  ((R64 STACK-CELL)		(MULQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(cond
                                  ((= 1 (<LITERAL>-value $2))) ; nothing to do
                                  ;; TODO emit shifts when possible
                                  (else
                                   (MOVQir (<LITERAL>-value $2) RCX)
                                   (MULQrr RCX (<REGISTER>-name $1))))))

;; the x86 div instruction is unsigned division
(define-instruction DIV		(true 0 true)
  ((R64 STACK-CELL)		(CQO)
                                (IDIVQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(CQO)
                                (cond
                                  ((= 1 (<LITERAL>-value $2))
                                   ;; remainder is zero, %rax is unchanged
                                   )
                                  ;; TODO emit shifts when possible
                                  (else
                                   (MOVQir (<LITERAL>-value $2) RCX) ; divisor
                                   (IDIVQrr RCX (<REGISTER>-name $1))))))

(define-instruction AND		(true 0 true)
  ((R64 STACK-CELL)		(ANDQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     (XORQrr reg reg))
                                    ((= -1 lit)
                                     ;; NOP
                                     )
                                    ((< -0x80000000 lit 0x80000000)
                                     (ANDQi32r lit reg))
                                    (else
                                     (MOVQi64r lit RBX)
                                     (ANDQrr RBX reg))))))

(define-instruction OR		(true 0 true)
  ((R64 STACK-CELL)		(ORQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((= -1 lit)
                                     (MOVQi32r -1 reg))
                                    ((< -0x80000000 lit 0x80000000)
                                     (ORQi32r lit reg))
                                    (else
                                     (MOVQi64r lit RBX)
                                     (ORQrr RBX reg))))))

;; TODO could be simplified with LI and TI base classes
(define-instruction XOR		(true 0 true)
  ((R64 STACK-CELL)		(XORQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2))
                                      (reg (<REGISTER>-name $1)))
                                  (cond
                                    ((= 0 lit)
                                     ;; NOP
                                     )
                                    ((= -1 lit)
                                     (NOTQr reg))
                                    ((< -0x80000000 lit 0x80000000)
                                     (XORQi32r lit reg))
                                    (else
                                     (MOVQi64r lit RBX)
                                     (XORQrr RBX reg))))))

(define-instruction BITWISE-NOT	(true 0 true)
  ((REGISTER)			(NOTQr (<REGISTER>-name $1))))

(define-instruction LOGIC-NOT	(true 0 true)
  ((REGISTER)			(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (SETEr AL)
                                (MOVZBQrr AL (<REGISTER>-name $1))))

(define-instruction NEG		(true 0 true)
  ((REGISTER)			(NEGQr (<REGISTER>-name $1))))

(define-instruction ASL		(true 0 true)
  ((R64 STACK-CELL)		(MOVQmr (<STACK-CELL>-offset $2) RBP 0 0 RCX)
                                (SALQrr CL (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (SALQir lit (<REGISTER>-name $1))))))

(define-instruction ASR		(true 0 true)
  ((R64 STACK-CELL)		(MOVQmr (<STACK-CELL>-offset $2) RBP 0 0 RCX)
                                (SARQrr CL (<REGISTER>-name $1)))
  ((R64 LI64)			(let ((lit (<LITERAL>-value $2)))
                                  (unless (= 0 lit)
                                    (SARQir lit (<REGISTER>-name $1))))))

(define-instruction ADDR	(false 0 true)
  ((GLOBAL-CELL)		(LEAQmr	(<GLOBAL-CELL>-address $1) 0 0 0 RAX))
  ;;((label)			(LEAQmr	$1 0 0 0 RAX))
  ((STACK-CELL)			(LEAQmr	(<STACK-CELL>-offset $1) RBP 0 0 RAX)))

(define-instruction MOVE	()
  ((LI64 STACK-CELL)		(MOVQim (<LITERAL>-value $1) (<STACK-CELL>-offset $2) RBP 0 0))
  ((LI64 R64)			(MOVQir (<LITERAL>-value $1) (<REGISTER>-name $2)))
  ((STACK-CELL STACK-CELL)	(let ((off1 (<STACK-CELL>-offset $1))
                                      (off2 (<STACK-CELL>-offset $2)))
                                  (unless (= off1 off2)
                                    (MOVQmr off1 RBP 0 0 RCX)
                                    (MOVQrm RCX off2 RBP 0 0))))
  ((R64 STACK-CELL)		(MOVQrm (<REGISTER>-name $1) (<STACK-CELL>-offset $2) RBP 0 0))
  ((STACK-CELL R64)		(MOVQmr (<STACK-CELL>-offset $1) RBP 0 0 (<REGISTER>-name $2)))
  ((R64 R64)			(let ((src (<REGISTER>-name $1))
                                      (dst (<REGISTER>-name $2)))
                                  (unless (= src dst)
                                    (MOVQrr src dst)))))

(define-instruction LOAD	(false 0 true)
  ((LI64)			(if (= 0 (<LITERAL>-value $1))
                                    (XORQrr RAX RAX)
                                  (MOVQir (<LITERAL>-value $1) RAX)))
  ((STACK-CELL)			(MOVQmr (<STACK-CELL>-offset $1) RBP 0 0 RAX))
  ((R64)			(MOVQrr (<REGISTER>-name $1) RAX))
  ((GLOBAL-CELL)		(LEAQmr	(<GLOBAL-CELL>-address $1) 0 0 0 RAX)
                                (MOVQmr 0 RAX 0 0 RAX))
  ((GLOBAL-ADDR)		(LEAQmr	(<GLOBAL-ADDR>-address $1) 0 0 0 RAX))
  ;; ((GOT64)			(println "	mov	"$1"@GOTPCREL(%rip), %rax")
  ;;       			(println "	mov	(%rax), %rax"))
  )
;; $1 what, $2 where
(define-instruction STORE	(true 0 false)
  ((R64 GLOBAL-CELL)		(LEAQmr	(<GLOBAL-CELL>-address $2) 0 0 0 RBX)
                                (MOVQrm (<REGISTER>-name $1) 0 RBX 0 1))
  ;; ((R64 GOT64)			(println "	mov	"$2"@GOTPCREL(%rip), %rbx")
  ;;                               (println "	mov	"$1", (%rbx)"))
  ((R64 R64)			(MOVQrm (<REGISTER>-name $1) 0 (<REGISTER>-name $2) 0 1))
  ((R64 STACK-CELL)		(MOVQrm (<REGISTER>-name $1) (<STACK-CELL>-offset $2) RBP 0 1)))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; in haskell the signed ones are called integer, and the unsigned one are called word.
;; for now these are all unsigned, i.e. not sign extended.
(define-instruction LOAD-I8	(true 0 true)
  ((R64 STACK-CELL)		(MOVQmr (<STACK-CELL>-offset $2) RBP 0 1 RCX)
                                (LEAQmr 0 (<REGISTER>-name $1) RCX 1 RCX)
                                (XORQrr RAX RAX)
                                (MOVBmr 0 RCX 0 1 AL))
  ((R64 LI64)			(let ((offset (<LITERAL>-value $2)))
                                  (if (= 0 offset)
                                      (MOVQrr (<REGISTER>-name $1) RCX)
                                    (LEAQmr offset (<REGISTER>-name $1) 0 1 RCX)))
                                (XORQrr RAX RAX)
                                (MOVBmr 0 RCX 0 1 AL)))

(define-instruction STORE-I8	(true 0 true)
  ((R64 STACK-CELL STACK-CELL)	(when-at-expand (feature strict-semantics-for-compiled-set)
                                  (XORQrr	RBX RBX))
                                (MOVBmr	(<STACK-CELL>-offset $3) RBP 0 1 BL)
                                (MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RCX)
                                (MOVBrm	BL 0 (<REGISTER>-name $1) RCX 1)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RBX RAX)))
  ((R64 STACK-CELL LI64)	(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RCX)
                                (if-at-expand (feature strict-semantics-for-compiled-set)
                                    (begin
                                     (XORQrr	RBX RBX)
                                     (MOVBir	(<LITERAL>-value $3) BL)
                                     (MOVBrm	BL 0 (<REGISTER>-name $1) RCX 1)
                                     (MOVQrr	RBX RAX))
                                  (MOVBim	(<LITERAL>-value $3) 0 (<REGISTER>-name $1) RCX 1))))

(when-at-expand (feature lower/array)

;; TODO these two are the same as the -OOP versions, except the MOV's scale
(define-instruction LOAD-CELL	(true 0 true)
  ((R64 STACK-CELL)		(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RCX) ; index
				(MOVQmr 0 (<REGISTER>-name $1) RCX 1 RAX))
  ((R64 LI64)			(LEAQmr	(<LITERAL>-value $2) (<REGISTER>-name $1) 0 0 RAX) ; index
				(MOVQmr 0 RAX 0 0 RAX)))

(define-instruction STORE-CELL	(true 0 true)
  ((R64 STACK-CELL STACK-CELL)	(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RCX) ; index
				(MOVQmr	(<STACK-CELL>-offset $3) RBP 0 1 RBX) ; value
				(MOVQrm	RBX 0 (<REGISTER>-name $1) RCX 1)))

) ; (feature lower/array)

(define-instruction LOAD-OOP	(true 0 true)
  ((R64 STACK-CELL)		(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RCX) ; index
				(MOVQmr 0 (<REGISTER>-name $1) RCX 8 RAX))
  ((R64 LI64)			(let ((offset (<LITERAL>-value $2)))
                                  (if (= 0 offset)
                                      (MOVQmr 0 (<REGISTER>-name $1) 0 0 RAX)
                                    (LEAQmr (* offset 8) (<REGISTER>-name $1) 0 0 RCX)
                                    (MOVQmr 0 RCX 0 0 RAX)))))

;; object is in RAX; args: offset, value
(define-instruction STORE-OOP	(true 0 true)
  ((R64 STACK-CELL STACK-CELL)	(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RCX)
                                (MOVQmr	(<STACK-CELL>-offset $3) RBP 0 1 RDX)
                                (MOVQrm	RDX 0 (<REGISTER>-name $1) RCX 8)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  ;; TODO these should probably mess with the current-value,
                                  ;; instead of move'ing into RAX
                                  (MOVQrr	RDX RAX)))
  ((R64 LI64 LI64)		(MOVQir	(<LITERAL>-value $3) RDX) ; value
                                (MOVQrm	RDX (* (<LITERAL>-value $2) 8) (<REGISTER>-name $1) 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RDX RAX)))
  ((R64 STACK-CELL LI64)	(MOVQmr	(<STACK-CELL>-offset $2) RBP 0 1 RCX)
                                (MOVQir	(<LITERAL>-value $3) RDX)
                                (MOVQrm	RDX 0 (<REGISTER>-name $1) RCX 8)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RDX RAX)))
  ((R64 LI64 STACK-CELL)	(MOVQmr	(<STACK-CELL>-offset $3) RBP 0 1 RDX) ; value
                                (MOVQrm	RDX (* (<LITERAL>-value $2) 8) (<REGISTER>-name $1) 0 0)
                                (when-at-expand (feature strict-semantics-for-compiled-set)
                                  (MOVQrr	RDX RAX))))

(define-instruction PUSH	()
  ((LI64)			(PUSHQi (<LITERAL>-value $1)))
  ((R64)			(PUSHQr (<REGISTER>-name $1))))

;; (define-instruction POP		()
;;   ((R64)			(POPQr (<REGISTER>-name $1))))

;; ENTER is slow, so don't use it (LEAVE is fine): https://stackoverflow.com/questions/5959890/enter-vs-push-ebp-mov-ebp-esp-sub-esp-imm-and-leave-vs-mov-esp-ebp
(define-instruction ENTER-FRAME	()
  ((_)				(PUSHQr RBP)
                                (MOVQrr RSP RBP)
                                (unless (= 0 $1)
                                  (SUBQir $1 RSP))))

(define-instruction LEAVE-FRAME	()
  ((_)				(LEAVE)
                                (RET)))

(define-instruction SEXT	()
  ((R32 R64)			(MOVSBQrr (<REGISTER>-name $1) (<REGISTER>-name $2))))

(define-form define-instruction/comparator (maru-name x86-name)
  `(define-instruction ,maru-name (true 0 true)
     ((R64 STACK-CELL)
      ;; TODO order?!
      (CMPQmr (<STACK-CELL>-offset $2) RBP 0 1 (<REGISTER>-name $1))
      (,x86-name AL)
      (MOVZBQrr AL (<REGISTER>-name $1)))
     ((R64 LI64)
      (let ((lit (<LITERAL>-value $2)))
        (if (= 0 lit)
            (TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
          (CMPQir lit (<REGISTER>-name $1))))
      (,x86-name AL)
      (MOVZBQrr AL (<REGISTER>-name $1)))))

(define-instruction/comparator LT SETLr)
(define-instruction/comparator LE SETLEr)
(define-instruction/comparator EQ SETEr)
(define-instruction/comparator GE SETGEr)
(define-instruction/comparator GT SETGr)
;;(define-instruction/comparator NE "setne")

;; a vector of assoc lists indexed by operator arity
(define *special-operators*
    (let ((table
           `(;; nullary
             ()
             ;; unary
             ((-  ,NEG) (not ,LOGIC-NOT) (bitwise-not ,BITWISE-NOT))
             ;; binary
             ((+  ,ADD) (-   ,SUB) (* ,MUL) (/ ,DIV)
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

;;;
;;; Special Forms
;;;

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

(require "source/compiler/elf-late.l")

;;;
;;; Compiling lambdas
;;;

(define-function emit-expr-code (self entry-point-label parent-comp)
  ;;(assert (is <expr> self))
  ;; NOTE printing the code as-is, i.e. without escaping, may break the comment syntax
  (.align +function-alignmet+ 0x90)

  (let* ((body		(<expr>-body self))
         (-c-		(compiler (+ 1 (<compiler>-level parent-comp))))
         (params	(<expr>-parameters self))
         (param-count	(list-length params))
         (frame-body-size (label)))

    (label! entry-point-label)
    ;; (emit-comment 1 "params: "(list-length (<expr>-parameters self))
    ;;               ", frame-size: "frame-size"("(/ frame-size +word-size-in-bytes+)
    ;;               "), temp-size: "temp-size "("(/ temp-size  +word-size-in-bytes+)")")
    (emit ENTER-FRAME frame-body-size)

    (let ((spill-locs	()))
      ;; allocate stack-cells for spilling the reg params
      (times-do (min param-count +n-param-registers+)
        (let ((spill-loc	(new-stack-cell -c-))
              (var		(pop params)))
          (set (<variable>-value var) spill-loc)
          (push spill-locs spill-loc)))

      ;; assign the stack locations to the params passed on the stack
      (let ((i 2))        ; 2 is the pushed RBP and the return address
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

    ;; move the reg-passed operands into the regs
    (times-do (min arg-count +n-param-registers+)
      (emit MOVE (pop arg-operands) (pop arg-regs)))

    ;; push the remaining (i.e. stack-passed) arguments in reverse order
    (list-do op (list-reverse! arg-operands)
      (emit PUSH op))

    (let* ((n-params	 (emit-comment 2 "compile-call-to: "op-value)
                         (compile-call-to op-value op -c-))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))
    (emit ADD op/RSP (LI64 (* arg-stack-cell-count +word-size-in-bytes+)))
    (free-temps tmps-to-free)))

(define-method compile-call-to <STACK-CELL> (op -c-)
  (emit LOAD self)
  (compile-call-to-<target-function> -c-))

(define-method compile-call-to <R64> (op -c-)
  (emit MOVE self +op/accumulator+)
  (compile-call-to-<target-function> -c-))

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
          ;; push	%rbp
          ;; mov	%rsp, %rbp
          ;; sub	$n, %rsp
          ;; ...
          ;;
          ;; so, the 8(%rbp) is to undo the push %rbp, so that we
          ;; regain the %rsp value at the entry point to the function.

          (LEAQmr	8 RBP 0 0 RAX)
          (set (<compiler>-current-value -c-) op/RAX)))
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
(define-constant +ro-data-segment-address+	0x00040000)
(define-constant +data-segment-address+		0x00060000)
(define-constant +bss-segment-address+		0x00080000)

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
  ;; The reason we added support for ET_DYN is that we want to
  ;; implement a C FFI (a questionable decision, admittedly); i.e. we
  ;; want to be able to reference symbols in .so files and use dlopen
  ;; at runtime. but ET_DYN brings ASLR with it, and we have internal
  ;; references in the data segment, therefore we now need to emit
  ;; relocation info in the section headers. Quite some complexity to
  ;; get admission into the C universe.
  ;; see commit: 'x86: emit relocation info, ET_DYN binaries'
  (.i16		elf/ET_DYN)      ; e_type
  (.i16		elf/EM_X86_64)   ; e_machine
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

    ;; ro-data segment (must be last, because this will also mmap the )
    (set size/ro-data (segment-length 'ro-data))
    (set file-offset/ro-data file-position)
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

    ;; data segment
    (set size/data (segment-length 'data))
    (set file-offset/data file-position)
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
                         file-position
                         0 size/bss
                         (+ elf/PF_R elf/PF_W)
                         +bss-segment-address+
                         elf/page-size)

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

(define-form syscall (sys-number . args)
  `(begin
    (MOVQir	,sys-number RAX)
    ,@(map (lambda (arg reg)
             ;; this being a macro opens the possibility for automatic
             ;; opcode selection based on the provided arg.
             `(MOVQir	,arg ,reg))
           args '(RDI RSI RDX R10 R8 R9))
    (SYSCALL)))

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
            ;; 2. r_info: relocation type (R_X86_64_RELATIVE = 8, base-relative)
            (.i64 elf/R_X86_64_RELATIVE)
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
