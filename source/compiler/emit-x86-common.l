;;; -*- mode: lisp; coding: us-ascii -*-

(define *special-forms*) ; forward
(define compile-call-form) ; forward
(define compile-call-to-<target-function>) ; forward
(define closure-code-label) ; forward

;; TODO this is kludgey. why only this one, etc...
(define-constant +word-size-in-bytes+ (target-value +word-size-in-bytes+))

;; TODO ? introduce abstraction for ABIs...
(define-constant +call-frame-alignmet+
    (case (target-value +word-size-in-bits+)
      (32 (case (target-value +operating-system+)
            (darwin	16)
            (else	4)))
      (64 16)))

;; TODO use the grovelled __USER_LABEL_PREFIX__
(define-constant +external-label-prefix+
    (case (target-value +operating-system+)
      (darwin	"_")
      (else	"")))

(define-function mangle-label (name)
  (with-forms ((putnext ((c) `(string-append mangled ,c))))
    (let* ((plain   (symbol->string name))
           (mangled (string))
           (digit-for (lambda (c)
                        (if (< c 10)
                            (+ c ?0)
                          (+ c (- ?A 10))))))
      (string-do c plain
        (cond
          ((or (and (<= ?a c) (<= c ?z))
               (and (<= ?A c) (<= c ?Z))
               (and (<= ?0 c) (<= c ?9)))
           (putnext c))
          ((or (= ?- c)
               (= ?_ c))
           (putnext ?_))
          (else
           (putnext ?_)
           (putnext (digit-for (bitwise-shift c -4)))
           (putnext (digit-for (bitwise-and c 0xf))))))
      mangled)))

(define-record <x86-compiler> <compiler>
  (param-offset
   arg-offset
   arg-limit
   asm-cell-type
   fn-epilogue-label
   ))

;;;
;;; OPERANDS
;;;
(define-operand LABEL () (name)		+maru-label-prefix+ (mangle-label self.name))		; a label that we generate
(define-operand EXTERNAL-LABEL LABEL ()	+external-label-prefix+ self.name)			; a label in the global C namespace

(define-function UNIQUE-LABEL args
  (LABEL (unique-name (or (first args) "L"))))

;; Naming convention: global, literal, temp, general register
(define-operand REGISTER ()	(name)		self.name)
(define-operand LITERAL ()	(value)		"$"self.value)
(define-operand GLOBAL-CELL ()	(name)		self.name)
(define-operand STACK-CELL ()	(offset))

(define-operand LI32 LITERAL)
(define-operand R32 REGISTER)

(define-operand GOT64 GLOBAL-CELL)     ; GOT = Global Offset Table (darwin)
(define-operand LI64 LITERAL)
(define-operand R64 REGISTER ())

;; TODO this is not yet used in the 32 bit backend
(define-operand STACK-PARAM STACK-CELL	()	self.offset"(%rbp)")

;;;
;;; INSTRUCTIONS
;;;
(define-instruction/emit-forms COMMENT 0
  ((pair)			(print "# ") (apply println $1)))

(define-instruction INLINE	()
  ((string)			(println $1)))

;; KLUDGE this dispatch should happen at runtime, not load-time
(if (= 'darwin (target-value +operating-system+))
    (let ()
      (define-instruction TEXT		()
        (()				(println "	.section __TEXT,__text")))
      (define-instruction DATA		()
        (()				(println "	.section __DATA,__data")))
      (define-instruction RODATA	()
        (()				(println "	.section __TEXT,__const")))
      ;; there's no .type on Darwin
      (define-instruction TYPE	()
        ((_ _)			)))
  (define-instruction TEXT	()
    (()				(println "	.text")))
  (define-instruction DATA	()
    (()				(println "	.section .data")))
  (define-instruction RODATA	()
    (()				(println "	.section .rodata")))
  (define-instruction TYPE	()
    ((_ _)			(println "	.type "$1", "$2))))

;;(define-instruction    (SECTION string)		(println "	.section "$1))
;;(define-instruction    (INDIRECT LABEL)		(println "	.indirect_symbol "$1))

(define-instruction ALIAS	()
  ((_ _)			(println "	.set "$1", "$2)))

(define-instruction EXPORT	()
  ((LABEL)			(println "	.globl "$1)))

(define-instruction ALIGN	()
  ((long)			(println "	.align " $1)))

(define-instruction ASCIZ	()
  ((string)			(print   "	.asciz ") (dumpln $1)))

;; TODO rename to DEFINE? that would be less unique
(define-instruction DEFLABEL	()
  ((LABEL)			(println $1":")))

;; The natural pointer/word size of the target.
(define-instruction CELL	()
  ((LITERAL)			(println "	"(<x86-compiler>-asm-cell-type -c-)"	"(<LITERAL>-value $1)))
  ((_)				(println "	"(<x86-compiler>-asm-cell-type -c-)"	"$1)))

(define-instruction LEAVE	()
  ((long)			(println "	leave")
				(println "	ret")))

(define-instruction BR		()
  ((LABEL)			(println "	jmp	"$1)))

(define-instruction BF		(true 0 false)
  ((REGISTER LABEL)		(println "	test	"$1", "$1)
				(println "	je	"$2)))

(define-instruction BT		(true 0 false)
  ((REGISTER LABEL)		(println "	test	"$1", "$1)
				(println "	jne	"$2)))

(define-instruction CALL	(false 0 true)
  ((LABEL)			(println "	call	"$1)))

(define-instruction CALLPTR	(true 0 false)
  ((REGISTER)			(println "	call	*"$1)))

(define-instruction ADD		(true 0 true)
  ((R32 STACK-CELL)		(println "	add	"$2","$1))
  ((R32 LI32)			(unless (= 0 (<LITERAL>-value $2))
				  (println "	add	"$2","$1)))
  ((R64 STACK-CELL)		(println "	add	"$2","$1))
  ((R64 LI64)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	add	"$2","$1))))

(define-instruction SUB		(true 0 true)
  ((R32 STACK-CELL)		(println "	sub	"$2", "$1))
  ((R32 LI32)			(unless (= 0 (<LITERAL>-value $2))
				  (println "	sub	"$2", "$1)))
  ((R64 STACK-CELL)		(println "	sub	"$2", "$1))
  ((R64 LI64)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	sub	"$2", "$1))))

;; TODO x86 mul operates on eax, which somehow needs to be encoded
;; into the instruction. same applies to div.
(define-instruction MUL		()
  ((LI32)			(cond
                                  ((= 1 (<LITERAL>-value $1))) ; nothing to do
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	mov	"$1", %ecx")
                                   (println "	mul	%ecx"))))
  ((LI64)			(cond
                                  ((= 1 (<LITERAL>-value $1))) ; nothing to do
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	mov	"$1", %rcx")
                                   (println "	mul	%rcx")))))

;; the x86 div instruction is unsigned division
(define-instruction DIV		()
  ((LI32)			(cond
                                  ((= 1 (<LITERAL>-value $1))
                                   ;; remainder is zero, %eax is unchanged
                                   (println "	xor	%edx, %edx"))
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	xor	%edx, %edx") ; the upper side of 64 bit operand
                                   (println "	mov	"$1", %ecx") ; divisor
                                   (println "	div	%ecx"))))
  ((LI64)			(cond
                                  ((= 1 (<LITERAL>-value $1))
                                   ;; remainder is zero, %rax is unchanged
                                   (println "	xor	%rdx, %rdx"))
                                  ;; TODO emit shifts when possible
                                  (else
                                   (println "	xor	%rdx, %rdx") ; the upper side of 64 bit operand
                                   (println "	mov	"$1", %rcx") ; divisor
                                   (println "	div	%rcx")))))

(define-instruction AND		(true 0 true)
  ((R32 STACK-CELL)		(println "	and	"$2", "$1))
  ((R32 LI32)			(unless (= -1 (<LITERAL>-value $2))
                                  (println "	and	"$2", "$1)))
  ((R64 STACK-CELL)		(println "	and	"$2", "$1))
  ((R64 LI64)			(unless (= -1 (<LITERAL>-value $2))
                                  (println "	and	"$2", "$1))))

(define-instruction OR		(true 0 true)
  ((R32 STACK-CELL)		(println "	or	"$2", "$1))
  ((R32 LI32)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	or	"$2", "$1)))
  ((R64 STACK-CELL)		(println "	or	"$2", "$1))
  ((R64 LI64)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	or	"$2", "$1))))

;; TODO could be simplified with LI and TI base classes
(define-instruction XOR		(true 0 true)
  ((R32 STACK-CELL)		(println "	xor	"$2", "$1))
  ((R32 LI32)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	xor	"$2", "$1)))
  ((R64 STACK-CELL)		(println "	xor	"$2", "$1))
  ((R64 LI64)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	xor	"$2", "$1))))

(define-instruction BITWISE-NOT	(true 0 true)
  ((REGISTER)			(println "	not	"$1)))

(define-instruction LOGIC-NOT	(true 0 true)
  ((REGISTER)			(println "	test	"$1", "$1)
				(println "	sete	%al")
				(println "	movzb	%al, "$1)))

(define-instruction NEG		(true 0 true)
  ((REGISTER)			(println "	neg	"$1)))

;; TODO should use reg1 and allocate a reg instead of directly using
;; ecx. same applies to asr.
(define-instruction ASL		(true 0 true)
  ((R32 STACK-CELL)		(println "	mov	"$2", %ecx")
				(println "	sal	%cl, "$1))
  ((R32 LI32)			(unless (= 0 (<LITERAL>-value $2))
				  (println "	shl	"$2", "$1)))
  ((R64 STACK-CELL)		(println "	mov	"$2", %rcx")
		                (println "	sal	%cl, "$1))
  ((R64 LI64)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	shl	"$2", "$1))))

(define-instruction ASR		(true 0 true)
  ((R32 STACK-CELL)		(println "	mov	"$2", %ecx")
				(println "	sar	%cl, "$1))
  ((R32 LI32)			(unless (= 0 (<LITERAL>-value $2))
				  (println "	sar	"$2", "$1)))
  ((R64 STACK-CELL)		(println "	mov	"$2", %rcx")
		                (println "	sar	%cl, "$1))
  ((R64 LI64)			(unless (= 0 (<LITERAL>-value $2))
                                  (println "	sar	"$2", "$1))))

(define-instruction MOVE	(false 0 false)
  ((LI32 STACK-CELL)		(println "	movl	"$1", "$2))
  ((LI64 STACK-CELL)		(println "	movq	"$1", "$2))
  ((R64 _)			(println "	movq	"$1", "$2))
  ((_ R64)			(println "	movq	"$1", "$2)))

(define-instruction LOAD	(false 0 true)
  ((LI32)			(if (= 0 (<LITERAL>-value $1))
				    (println "	xor	%eax, %eax")
				  (println "	mov	"$1", %eax")))
  ((LI64)			(if (= 0 (<LITERAL>-value $1))
                                    (println "	xor	%rax, %rax")
                                  (println "	mov	"$1", %rax")))
  ((R64)			(println "	mov	"$1", %rax"))
  ((GOT64)			(println "	mov	"$1"@GOTPCREL(%rip), %rax")
				(println "	mov	(%rax), %rax")))
;; $1 what, $2 where
(define-instruction STORE	(true 0 false)
  ((R32 STACK-CELL)		(println "	mov	"$1", "$2))
  ((R32 GLOBAL-CELL)		(println "	mov	"$1", "$2))
  ((R64 GLOBAL-CELL)		(println "	lea	"$2"(%rip), %rbx")
                                (println "	mov	"$1", (%rbx)"))
  ((R64 GOT64)			(println "	mov	"$2"@GOTPCREL(%rip), %rbx")
                                (println "	mov	"$1", (%rbx)"))
  ((R64 R64)			(println "	mov	"$1", "$2"")) ; e.g. when dest is an arg reg in a function call
  ((R64 STACK-CELL)		(println "	mov	"$1", "$2)))

(when-at-expand (feature lower/array)
  ;; TODO these two are the same as the -OOP versions, except the lea's multiplier
  (define-instruction LOAD-CELL	(false 0 true))

  (define-instruction STORE-CELL (false 0 true)))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; in haskell the signed ones are called integer, and the unsigned one are called word.
;; for now these are all unsigned, i.e. not sign extended.
(define-instruction LOAD-I8	(false 0 true)
  ((LI32)			(let ((offset (<LITERAL>-value $1)))
				  (if (= 0 offset)
				      (println "	movl	%eax, %ecx")
				    (println "	lea	"offset"(%eax), %ecx")))
				(println "	xor	%eax, %eax")
				(println "	movb	(%ecx), %al"))
  ((LI64)			(let ((offset (<LITERAL>-value $1)))
                                  (if (= 0 offset)
                                      (println "	mov	%rax, %rcx")
                                    (println "	lea	"offset"(%rax), %rcx")))
                                (println "	xor	%rax, %rax")
                                (println "	mov	(%rcx), %al")))

(define-instruction STORE-I8	(false 0 true)
  ((LI32 _)			(let ((offset (<LITERAL>-value $1)))
                                  (if-at-expand (feature strict-semantics-for-compiled-set)
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%eax, %ecx")
                                          (println "	lea	"offset"(%eax), %ecx"))
                                        (println "	xor	%eax, %eax")
                                        (println "	mov	"$2", %al") ; this also leaves it as return value in %eax
                                        (println "	mov	%al, (%ecx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"offset"(%eax), %eax"))
                                    (println "	movb	"$2", (%eax)"))))
  ((LI64 _)			(let ((offset (<LITERAL>-value $1)))
                                  (if-at-expand (feature strict-semantics-for-compiled-set)
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%rax, %rcx")
                                          (println "	lea	"offset"(%rax), %rcx"))
                                        (println "	xor	%rax, %rax")
                                        (println "	mov	"$2", %al") ; this also leaves it as return value in %rax
                                        (println "	mov	%al, (%rcx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"offset"(%rax), %rax"))
                                    (println "	movb	"$2", (%rax)")))))

(define-instruction LOAD-OOP	(false 0 true)
  ((LI32)			(let ((offset (<LITERAL>-value $1)))
                                  (if (= 0 offset)
                                      (println "	mov	(%eax), %eax")
                                    (println "	lea	"(* 4 offset)"(%eax), %ecx")
                                    (println "	mov	(%ecx), %eax"))))
  ((LI64)			(let ((offset (<LITERAL>-value $1)))
                                  (if (= 0 offset)
                                      (println "	mov	(%rax), %rax")
                                    (println "	lea	"(* 8 offset)"(%rax), %rcx")
                                    (println "	mov	(%rcx), %rax")))))

(define-instruction STORE-OOP	(false 0 true)
  ((LI32 _)			(let ((offset (<LITERAL>-value $1)))
                                  (if-at-expand (feature strict-semantics-for-compiled-set)
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%eax, %ecx")
                                          (println "	lea	"(* 4 offset)"(%eax), %ecx"))
                                        (println "	mov	"$2", %eax") ; this also leaves it as return value in %eax
                                        (println "	mov	%eax, (%ecx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"(* 4 offset)"(%eax), %eax"))
                                    (println "	mov	"$2", (%eax)"))))
  ((LI64 _)			(let ((offset (<LITERAL>-value $1)))
                                  (if-at-expand (feature strict-semantics-for-compiled-set)
                                      (let ()
                                        (if (= 0 offset)
                                            (println "	mov	%rax, %rcx")
                                          (println "	lea	"(* 8 offset)"(%rax), %rcx"))
                                        (println "	mov	"$2", %rax") ; this also leaves it as return value in %rax
                                        (println "	mov	%rax, (%rcx)"))
                                    (unless (= 0 offset)
                                      (println "	lea	"(* 8 offset)"(%rax), %rax"))
                                    (println "	mov	"$2", (%rax)")))))

(define-instruction PUSH	(false 0 false)
  ((_)				(println "	pushq	"$1)))

(define-form define-instruction/comparator (maru-name x86-name)
  `(define-instruction ,maru-name (true 0 true)
     ((R32 STACK-CELL)
      (println "	cmp	"$2", "$1)
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, %eax"))
     ((R32 LI32)
      (if (= 0 (<LITERAL>-value $2))
          (println "	test	"$1", "$1)
        (println "	cmp	"$2", "$1))
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, %eax"))
     ((R64 STACK-CELL)
      (println "	cmp	"$2", "$1)
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, "$1))
     ((R64 LI64)
      (if (= 0 (<LITERAL>-value $2))
          (println "	test	"$1", "$1)
        (println "	cmp	"$2", "$1))
      (println "	" ,x86-name "	%al")
      (println "	movzb	%al, "$1))))

(define-instruction/comparator LT "setl")
(define-instruction/comparator LE "setle")
(define-instruction/comparator EQ "sete")
(define-instruction/comparator GE "setge")
(define-instruction/comparator GT "setg")
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
;;; Compiler Infrastructure
;;;

(define-function %gen (-c- factory args)
  ;; TODO it feels wasteful/unnecessary to allocate an instr instance here...
  ;; at least until we start storing something in the instances
  (let ((instr (factory ())))
    (when (<instruction>-has-input? instr)
      (push args (<compiler>-current-value -c-)))
    (emit-comment 2 "GEN of "instr", args: " args)
    (when (<instruction>-produces-output? instr)
      ;; KLUDGE
      (set (<compiler>-current-value -c-)
           (if (= 4 +word-size-in-bytes+)
               (R32 "%eax")
             (R64 "%rax"))))
    ;; save into the gen buffer
    (array-append (<compiler>-gen-buffer -c-) (cons instr args))
    ()))

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
     (LITERAL expr))

    (else
     ;; (when (variable? expr)
     ;;   (let ((value (<variable>-value expr)))
     ;;     (assert (global-variable? expr))
     ;;     (print-all *debug-output* "*** matched: "expr"="value", type:" (type-of value) "\n")
     ;;     value))
     (comp expr))))

;; FIXME very unfortunate name: expr is lambdas in current maru parlance.
;; rename to compile/expression (?)
(define-function compile/expr-into-temp-or-literal (expr -c-)
  (cond
    ((long? expr)
     (LITERAL expr))
    (else
      (comp expr)
      (let ((temp (alloc-temp -c-)))
        (gen STORE temp)
        temp))))

(define-function compile-call-to-global-function (op -c-)
  (if (feature redefinable-functions-in-target)
      (let ()
        (comp op)
        (compile-call-to-<target-function> -c-))
    (gen CALL (closure-code-label (<variable>-name op))))
  ())

(define-method compile-call-to (slave-value <target-function>) (op -c-)
  (comp op)
  (compile-call-to-<target-function> -c-))

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
  (let ((temp (alloc-temp -c-)))
    (gen STORE temp)
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
  (let ((done (UNIQUE-LABEL)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (gen BF done)))
    (gen DEFLABEL done)))

(define-function compile/or (expr -c-)
  (let ((done (UNIQUE-LABEL)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (when (set expr (cdr expr))
        (gen BT done)))
    (gen DEFLABEL done)))

(define-function compile/if (expr -c-)
  (let ((l/false (UNIQUE-LABEL))
        (l/end (UNIQUE-LABEL)))
    (comp (second expr))
    (gen BF l/false)
    (comp (third expr))
    (gen BR l/end)
    (gen DEFLABEL l/false)
    (list-do stmt (cdddr expr)
      (comp stmt))
    (gen DEFLABEL l/end)))

(define-function compile/while (expr -c-)
  (let ((l/body	(UNIQUE-LABEL))
        (l/cond	(UNIQUE-LABEL)))
    (gen BR l/cond)
    (gen DEFLABEL l/body)
    (list-do stmt (cddr expr)
      (and stmt (comp stmt)))
    (gen DEFLABEL l/cond)
    (comp (second expr))
    (gen BT l/body)))

(define-function compile/return (expr -c-)
  (list-do stmt (cdr expr)
    (comp stmt))
  (gen BR (or (<x86-compiler>-fn-epilogue-label -c-)
              (set (<x86-compiler>-fn-epilogue-label -c-) (UNIQUE-LABEL)))))

(define-function emit-object/C-string (self -c-)
  (let ((label (UNIQUE-LABEL "cstr")))
    (emit RODATA)
    (emit DEFLABEL label)
    (emit ASCIZ self)
    label))

(define-function compile/C-string (expr -c-)
  (assert (= (list-length expr) 2))
  (let ((label (emit-object/C-string (second expr) -c-)))
    (gen LOAD label)))

(define-function compile/lambda (form -c-)
  (let ((expr (eval form)))
    (gen LOAD (compile-expr expr () -c-))))

;;;
;;; Special Operators
;;;

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  (gen op))

;; FIXME? these implement a right-to-left evaluation order, while
;; function calls implement the opposite. note that this is entangled
;; with e.g. the LOAD/STORE instructions above, as they expect arg0 to
;; be loaded in %rax.
(define-function compile/binary-operator (op args -c-)
  (let ((tmp (compile/expr-into-temp-or-literal (cadr args) -c-)))
    (comp (car args))
    (free-temp tmp)
    (gen op tmp)))

(define-function compile/ternary-operator (op args -c-)
  (let ((tmp2 (compile/expr-into-temp-or-literal (caddr args) -c-))
        (tmp1 (compile/expr-into-temp-or-literal (cadr  args) -c-)))
    (comp (car args))
    (free-temp tmp1)
    (free-temp tmp2)
    (gen op tmp1 tmp2)))

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
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((is <fixed> op)
       (let ((handler (cdr (assq op *special-forms*))))
         (or handler (error "No handler for fixed form: " self))
         (handler self -c-)))
      (else
       (compile-call-form op args -c-)))))
