;;; -*- mode: lisp; coding: us-ascii -*-

;;; This is a compiler that emits x86-64 machine code directly into an
;;; Elf64 executable.
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
  (x R32 EAX EBX ECX EDX ESP EBP ESI EDI)
  (x R64 RAX RBX RCX RDX RSP RBP RSI RDI R8 R9 R10 R11 R12 R13 R14 R15))

(define-constant +param-registers+		`(quote ,(list op/RDI op/RSI op/RDX op/RCX op/R8 op/R9)))
(define-constant +callee-saved-registers+	`(quote ,(list op/RBX op/R12 op/R13 op/R14 op/R15)))

;; TODO ? use +accumulator+ in the instructions and everywhere
;; else in general where relevant.
(define-constant +accumulator+		RAX)
(define-constant +op/accumulator+	op/RAX)

(require "source/compiler/elf.l")

;;;
;;; INSTRUCTIONS
;;;

(define-instruction GOTO	()
  ((label)			(JMPQrel32 $1)))

(define-instruction GOTOF	(true 0 false)
  ((REGISTER label)		(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JE $2)))

(define-instruction GOTOT	(true 0 false)
  ((REGISTER label)		(TESTQrr (<REGISTER>-name $1) (<REGISTER>-name $1))
                                (JNE $2)))

(define-instruction CALL	(false 0 true)
  ((label)			(CALLQrel32 $1))
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

(define-instruction MULTIPLY	(true 0 true)
  ((R64 STACK-CELL)		(MULQmr (<STACK-CELL>-offset $2) RBP 0 0 (<REGISTER>-name $1)))
  ((R64 LI64)			(cond
                                  ((= 1 (<LITERAL>-value $2))) ; nothing to do
                                  ;; TODO emit shifts when possible
                                  (else
                                   (MOVQir (<LITERAL>-value $2) RCX)
                                   (MULQrr RCX (<REGISTER>-name $1))))))

;; the x86 div instruction is unsigned division
(define-instruction DIVIDE	(true 0 true)
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

(define-instruction NEGATE	(true 0 true)
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

(when-at-expand (feature memory-block)

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

) ; (feature memory-block)

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
  ;; push	%rbp
  ;; mov	%rsp, %rbp
  ;; sub	$n, %rsp
  ;;
  ;; so, the 8(%rbp) is to undo the push %rbp, so that we
  ;; regain the %rsp value at the entry point to the function.

  (LEAQmr	target/cell-size/bytes RBP 0 0 RAX)
  (set (<compiler>-current-value -c-) op/RAX))

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
    (emit ADD op/RSP (LI64 (* arg-stack-cell-count target/cell-size/bytes)))
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

(define-function run-compiler (env output-path)
  (compile-env env (compiler 1) output-path
               elf/EM_X86_64
               elf/R_X86_64_RELATIVE))

(require "source/compiler/emit-late.l")
