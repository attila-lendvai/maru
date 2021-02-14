;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits IA-32 text, aka x86 assembly, using the gcc toolchain.
;;;
;;; Status: it should successfully compile eval.l into eval.s,
;;; that in turn can be compiled by the gcc toolchain into an executable eval binary.
;;;

;;; TODO
;;;  - factor out the C ffi stuff into a separate file

;;; It can compile a subset of Maru.
;;;
;;; Limitations and peculiarities:
;;;   - no closures
;;;   - no variable number of args for functions
;;;   - only supports the following literals: Long, String (no lists, quoted literals, etc)
;;;   - string literals are compiled into .asciz, which means that they
;;;     are *not* tagged Maru objects on the heap; i.e. (t/print "foo") will
;;;     go astray because "foo" will be emitted as a null terminated string of
;;;     ascii bytes (instead of a Maru object of type <string>).
;;;   - probaby more
;;;   - see +special-operators+ and +special-forms+ for the list of specially
;;;     handled constructs
;;;
;;; Naming:
;;;   - EMIT: emit instructions into the output stream
;;;   - GEN:  like EMIT, but collect instructions into a buffer for later emission
;;;   - -foo- is an implicit var in the lexenv
;;;   - +foo+ is a constant
;;;   - *foo* is a global

(define-constant +global-label-prefix+
    (case (target-value +operating-system+)
      (darwin	"_")
      (else	"")))

(define-constant +call-frame-alignmet+
    (case (target-value +operating-system+)
      (darwin	16)
      (else	(/ (target-value +word-size-in-bits+)
                   8))))

(unless (= 32 (target-value +word-size-in-bits+))
  (error "The x86 compiler backend doesn't support target word size "(target-value +word-size-in-bits+)))

;;; DEFINE-INSTRUCTION

(define-form define-instruction (name)
  (let ((type-name (symbol->type-name name)))
    `(let ()
       (define-type ,type-name)
       (define-print-method ,type-name (print-all -stream- ,(symbol->string name)))
       (define ,name (new ,type-name)))))

;;; DEFINE-EMIT

(define-form emit args
  `(emit-instruction ,@args))

(define-generic emit-instruction)

(define-function %define-emit-param-name (index)
  (string->symbol (concat-string "$" (number->string index))))

(define-function %define-emit-params (index types)
  (when (pair? types)
    (cons (list (awhen (and (not (= (first types) '_))
                              (first types))
                  (symbol->type-name it))
                (%define-emit-param-name index))
          (%define-emit-params (+ index 1) (cdr types)))))

(define-form define-emit (op-args . body)
  (let* ((op-name (car op-args))
         (type-name (symbol->type-name op-name)))
    `(let ()
       ,@(unless (defined? op-name)
           `((define-instruction ,op-name)))
       (define-multimethod emit-instruction ((,type-name __op__) ,@(%define-emit-params 1 (cdr op-args)))
         ,@body))))

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

;;;
;;; IA32 -- OPERANDS
;;;
(define-operand LABEL () (name)		+maru-label-prefix+ (mangle-label (<LABEL>-name self)))		; a label that we generate
(define-operand GLOBAL-LABEL LABEL ()	+global-label-prefix+ (<LABEL>-name self))			; a label in the global C namespace
;; global, literal, and temp pointers
(define-operand GI32 () (name)		(<GI32>-name self))
(define-operand LI32 () (value)		"$"(<LI32>-value self))
(define-operand TI32 () (offset)	(<TI32>-offset self)"(%esp)")

(define-function UNIQUE-LABEL args
  (LABEL (unique-name (or (first args) "L"))))

(define-function temp?		(obj)	(= <TI32> (type-of obj)))
(define-function literal?	(obj)	(= <LI32> (type-of obj)))

;;;
;;; IA32 -- INSTRUCTIONS
;;;
(define-emit    (COMMENT pair)			(when *compiler-verbose* (print "## ") (apply println $1)))

(define-emit    (TEXT)				(println "	.text"))
(define-emit    (DATA)				(println "	.data"))
(define-emit    (RODATA)			(println "	.section .rodata"))
;;(define-emit    (SECTION string)		(println "	.section "$1))

;;(define-emit    (INDIRECT LABEL)		(println "	.indirect_symbol "$1))
(define-emit    (EXPORT LABEL)			(println "	.globl "$1))
(define-emit    (EXPORT GLOBAL-LABEL)		(println "	.globl "$1)) ; TODO add support for inheritance for multimethods, and delete the specializations on GLOBAL-LABEL

(define-emit    (ALIGN long)			(println "	.align " $1))

(define-emit    (LONG long)			(println "	.4byte	"$1))
(define-emit    (LONG LABEL)			(println "	.4byte	"$1))

(define-emit    (ASCIZ string)			(print   "	.asciz ") (dumpln $1))

(define-emit    (DEFLABEL LABEL)		(println $1":"))
(define-emit    (DEFLABEL GLOBAL-LABEL)		(println $1":"))

;; ENTER is slow, so don't use it (LEAVE is fine): https://stackoverflow.com/questions/5959890/enter-vs-push-ebp-mov-ebp-esp-sub-esp-imm-and-leave-vs-mov-esp-ebp
(define-emit    (ENTER long)			(println "	pushl	%ebp")
						(println "	movl	%esp, %ebp")
						(unless (= 0 $1)
                                                  (println "	subl	$"$1", %esp")))

(define-emit    (LEAVE long)			(println "	leave")
						(println "	ret"))

(define-emit    (NEG)				(println "	negl	%eax"))

(define-emit    (ADD TI32)			(println "	addl	"$1", %eax"))

(define-emit    (ADD LI32)			(unless (= 0 (<LI32>-value $1))
                                                  (println "	addl	"$1", %eax")))

(define-emit    (SUB TI32)			(println "	subl	"$1", %eax"))

(define-emit    (SUB LI32)			(unless (= 0 (<LI32>-value $1))
                                                  (println "	subl	"$1", %eax")))

(define-emit    (MUL TI32)			(println "	mull	"$1))

(define-emit    (MUL LI32)			(cond
                                                  ((= (<LI32>-value $1) 1)) ; nothing to do
                                                  ;; TODO emit shifts when possible
						  (else
                                                   (println "	movl	"$1", %ecx")
						   (println "	mull	%ecx"))))

(define-emit    (DIV TI32)			(println "	xorl	%edx, %edx")
						(println "	divl	"$1))

(define-emit    (DIV LI32)			(cond
                                                  ((= (<LI32>-value $1) 1)
                                                   ;; remainder is zero, %eax is unchanged
                                                   (println "	xorl	%edx, %edx"))
                                                  ;; TODO emit shifts when possible
                                                  (else
                                                   (println "	movl	$0, %edx")
						   (println "	movl	"$1", %ecx")
						   (println "	divl	%ecx"))))

(define-emit    (AND TI32)			(println "	andl	"$1", %eax"))
(define-emit    (AND LI32)			(unless (= -1 (<LI32>-value $1))
                                                  (println "	andl	"$1", %eax")))
(define-emit    (OR  TI32)			(println "	orl	"$1", %eax"))
(define-emit    (OR  LI32)			(unless (= 0 (<LI32>-value $1))
                                                  (println "	orl	"$1", %eax")))
(define-emit    (XOR TI32)			(println "	xorl	"$1", %eax"))
(define-emit    (XOR LI32)			(unless (= 0 (<LI32>-value $1))
                                                  (println "	xorl	"$1", %eax")))
(define-emit    (BITWISE-NOT)			(println "	notl	%eax"))

(define-emit    (LOGIC-NOT)			(println "	cmpl	$0, %eax")
						(println "	sete	%al")
						(println "	movzbl	%al, %eax"))

(define-form define-emit/comparator (maru-name x86-name)
  (unless (defined? maru-name)
    ;; TODO KLUDGE we need to do this early, otherwise the expanded define-emit's would define it twice in their own expand-time
    (eval `(define-instruction ,maru-name)))
  `(let ()
     (define-emit (,maru-name TI32)
       (println "	cmpl	"$1", %eax")
       (println "	" ,x86-name "	%al")
       (println "	movzbl	%al, %eax"))
     (define-emit (,maru-name LI32)
       (println "	cmpl	"$1", %eax")
       (println "	" ,x86-name "	%al")
       (println "	movzbl	%al, %eax"))))

(define-emit/comparator LT "setl")
(define-emit/comparator LE "setle")
(define-emit/comparator EQ "sete")
(define-emit/comparator GE "setge")
(define-emit/comparator GT "setg")
;;(define-emit/comparator NE "setne")

(define-emit    (ASL TI32)			(println "	movl	"$1", %ecx")
						(println "	sall	%cl, %eax"))

(define-emit    (ASL LI32)			(unless (= 0 (<LI32>-value $1))
                                                  (println "	shll	"$1", %eax")))

(define-emit    (ASR TI32)			(println "	movl	"$1", %ecx")
						(println "	sarl	%cl, %eax"))

(define-emit    (ASR LI32)			(unless (= 0 (<LI32>-value $1))
                                                  (println "	sarl	"$1", %eax")))

(define-emit    (BR LABEL)			(println "	jmp	"$1))

(define-emit    (BF LABEL)			(println "	cmpl	$0, %eax")
						(println "	je	"$1))

(define-emit    (BT LABEL)			(println "	cmpl	$0, %eax")
						(println "	jne	"$1))

(define-emit    (CALLPTR _)			(println "	call	*%eax"))
(define-emit    (CALL LABEL _)			(println "	call	"$1))
(define-emit    (CALL GLOBAL-LABEL _)		(println "	call	"$1))

(define-emit    (LOAD LI32)			(if (= 0 (<LI32>-value $1))
                                                    (println "	xorl	%eax, %eax")
                                                  (println "	movl	"$1", %eax")))
(define-emit    (LOAD LABEL)			(println "	movl	$"$1", %eax"))
(define-emit    (LOAD GI32)			(println "	movl	"$1", %eax"))
(define-emit    (LOAD TI32)			(println "	movl	"$1", %eax"))

(define-emit    (STORE TI32)			(println "	movl	%eax, "$1))
(define-emit    (STORE GI32)			(println "	movl	%eax, "$1))

(define-emit    (ADDR GI32)			(println "	movl	$"$1", %eax"))
(define-emit    (ADDR TI32)			(println "	leal	"$1", %eax"))

(define-emit    (MOVE TI32 TI32)		(println "	movl	"$1", %ecx")
						(println "	movl	%ecx, "$2))

(define-emit    (MOVE LI32 TI32)		(println "	movl	"$1", "$2))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; in haskell the signed ones are called integer, and the unsigned one are called word.
;; for now these are all unsigned, i.e. not sign extended.
(define-emit    (LOAD-I8 TI32)			(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx), %ecx")
						(println "	xorl	%eax, %eax")
						(println "	movb	(%ecx), %al"))

(define-emit    (LOAD-I8 LI32)			(let ((offset (<LI32>-value $1)))
                                                  (if (= 0 offset)
                                                      (println "	movl	%eax, %ecx")
                                                    (println "	leal	"offset"(%eax), %ecx")))
						(println "	xorl	%eax, %eax")
						(println "	movb	(%ecx), %al"))

(define-emit    (STORE-I8 TI32 _)		(if-at-expand feature/strict-semantics-for-compiled-set
						    ;; NOTE this works out just fine for a TI32, too, because we are little-endian.
                                                    (let ()
                                                      (println "	movl	"$1", %ecx")
						      (println "	leal	(%eax, %ecx), %ecx")
                                                      (println "	xor	%eax, %eax")
                                                      (println "	movb	"$2", %al")
						      (println "	movb	%al, (%ecx)"))
                                                  (println "	movl	"$1", %ecx")
						  (println "	leal	(%eax, %ecx), %eax")
						  (println "	movb	"$2", (%eax)")))

(define-emit    (STORE-I8 LI32 _)		(let ((offset (<LI32>-value $1)))
                                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                                      (let ()
                                                        (if (= 0 offset)
                                                            (println "	movl	%eax, %ecx")
                                                          (println "	leal	"offset"(%eax), %ecx"))
                                                        (println "	xor	%eax, %eax")
                                                        (println "	movb	"$2", %al") ; this also leaves it as return value in %eax
						        (println "	movb	%al, (%ecx)"))
                                                    (unless (= 0 offset)
                                                      (println "	leal	"offset"(%eax), %eax"))
                                                    (println "	movb	"$2", (%eax)"))))

(define-emit    (LOAD-OOP TI32)			(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx, 4), %ecx")
						(println "	movl	(%ecx), %eax"))

(define-emit    (LOAD-OOP LI32)			(let ((offset (<LI32>-value $1)))
                                                  (if (= 0 offset)
                                                      (println "	movl	%eax, %ecx")
                                                    (println "	leal	"(* 4 offset)"(%eax), %ecx")))
						(println "	movl	(%ecx), %eax"))

(define-emit    (STORE-OOP TI32 _)		(if-at-expand feature/strict-semantics-for-compiled-set
                                                    (let ()
                                                      (println "	movl	"$1", %ecx")
						      (println "	leal	(%eax, %ecx, 4), %ecx")
                                                      (println "	movl	"$2", %eax")
						      (println "	movl	%eax, (%ecx)"))
                                                  (println "	movl	"$1", %ecx")
						  (println "	leal	(%eax, %ecx, 4), %eax")
                                                  (println "	movl	"$2", (%eax)")))

(define-emit    (STORE-OOP LI32 _)		(let ((offset (<LI32>-value $1)))
                                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                                      (let ()
                                                        (if (= 0 offset)
                                                            (println "	movl	%eax, %ecx")
                                                          (println "	leal	"(* 4 offset)"(%eax), %ecx"))
                                                        (println "	movl	"$2", %eax") ; this also leaves it aas return value in %eax
                                                        (println "	movl	%eax, (%ecx)"))
                                                    (unless (= 0 offset)
                                                      (println "	leal	"(* 4 offset)"(%eax), %eax"))
                                                    (println "	movl	"$2", (%eax)"))))

;;;
;;; Compiler Infrastructure
;;;
(define-record <x86-compiler> <compiler>
  (param-offset
   arg-offset
   arg-limit
   fn-epilogue-label))

(define-function x86-compiler (level)
  (make <x86-compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (gen-buffer			(array))

    (param-offset		0)
    (arg-offset			0)
    (arg-limit			0)))

;; KLUDGE
(define *compiler-factory* x86-compiler)

(define-function new-temp (-c-)
  (TI32 (* (new-temp-index -c-) (eval-at-expand (target-value +word-size-in-bytes+)))))

(define-function %free-temp (-c- obj)
  (when (is <TI32> obj)
    (push (<compiler>-temps -c-) obj)))

(define-form gen args
  `(array-append (<compiler>-gen-buffer -c-) (list ,@args)))

(define-function emit-gen-buffer (-c-)
  (array-do entry (<compiler>-gen-buffer -c-)
    (apply emit-instruction entry)))

(define-function new-param (c)
  (with-instance-accessors c <x86-compiler>
    (let* ((offset	c.param-offset)
           (temp	(TI32 offset)))
      (incr c.param-offset 4)
      temp)))

(define-function new-arg (c)
  (with-instance-accessors c <x86-compiler>
    (let* ((index	c.arg-offset)
           (temp	(TI32 index)))
      (incr c.arg-offset 4)
      temp)))

(define-function free-args (c args)
  (with-instance-accessors c <x86-compiler>
    (when (< c.arg-limit c.arg-offset)
      (set c.arg-limit c.arg-offset))
    (set c.arg-offset 0)))

;;;
;;; Compiling lambdas
;;;

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit COMMENT (list "COMPILE of "__obj__))
     (compile __obj__ -c-)))

(define-function compile/prog-into-temp (prog -c-)
  (assert (pair? prog) "compile/prog-into-temp: prog is empty") ; this is against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  ;; NOTE it's tempting here to check for single-element prog's, and turning them into a compile/expr-into-temp-or-literal
  ;; but our single caller, namely compile/let, requires a temp location, even when initialized to literal values.
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-temp -c-)))
    (gen STORE temp)
    temp))

(define-function compile/expr-into-temp-or-literal (expr -c-)
  (cond
    ((long? expr)
     (LI32 expr))
    (else
      (comp expr)
      (let ((temp (alloc-temp -c-)))
        (gen STORE temp)
        temp))))

(define-function compile-expr (self name indirection-allowed? parent-comp)
  (emit COMMENT (list "compiling fn "name", body: "(<expr>-body self)))
  ;; KLUDGE __libc_csu_init & co.
  (let* ((main?		(member? name '(main __libc_csu_init __libc_csu_fini __libc_start_main)))
         (indirect?	(and (not main?)
                             indirection-allowed?
                             feature/redefinable-functions-in-target))
         (body (<expr>-body self))
         (-c- (x86-compiler (+ 1 (<compiler>-level parent-comp))))
         (entry-label (if main?
                          (GLOBAL-LABEL name)
                        (LABEL (concat-string (symbol->string name)
                                              (if indirect? "_body" "")))))
         (init-param (lambda (var)
                       (set (<variable>-value var) (new-param -c-))))
         (params (map init-param (<expr>-parameters self))))
    (list-do e body
      (and e (comp e)))
    ;; TODO investigate: probably only the frm-size needs to be aligned (on darwin)
    (let* ((arg-size (align +call-frame-alignmet+             (<x86-compiler>-arg-limit -c-) ))
           (tmp-size (align +call-frame-alignmet+ (+ arg-size (* (<compiler>-temp-limit -c-)
                                                                 (target-value +word-size-in-bytes+)))))
           (frm-size (align +call-frame-alignmet+ (+ tmp-size 8))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp)))) (<compiler>-temps -c-))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ frm-size (<TI32>-offset tmp)))) params)
      (emit TEXT)
      (when main?
        (emit EXPORT entry-label))
      (emit DEFLABEL entry-label)
      (emit COMMENT (list "frame "arg-size" "(<compiler>-temp-limit -c-)" "tmp-size" "frm-size))
      (emit ENTER (- frm-size 8))
      (emit-gen-buffer -c-)
      (awhen (<x86-compiler>-fn-epilogue-label -c-)
        (emit DEFLABEL it))
      (emit LEAVE (- frm-size 8)))
    (when indirect?
      (let ((label (LABEL name)))
        (emit DATA)
        (emit EXPORT label)
        (emit DEFLABEL label)
        (emit LONG entry-label)))))

;;;
;;; Compiling calls
;;;

(define-function compile-call (op args -c-)
  ;; NOTE this implements a left-to-right evaluation order, including the operator.
  ;; i.e. moving this op-tmp means changing the evaluation order!
  (let ((op-tmp	(when (pair? op)
                  ;; we can spare a STORE/LOAD when we know that op
                  ;; doesn't evaluate anything; i.e. we can reorder
                  ;; its evaluation, which is a simple LOAD, to the
                  ;; final, COMPILE-CALL-TO step.
                  (compile/expr-into-temp-or-literal op -c-)))
        (arg-tmps	(map-with compile/expr-into-temp-or-literal args -c-))
        (arg-locs	(map (lambda (_) (new-arg -c-)) args)))
    ;; set up the stack for the call
    (map (lambda (a b) (gen MOVE a b)) arg-tmps arg-locs)
    (free-temps arg-tmps)

    (let ((n-params	(compile-call-to (cond
                                           (op-tmp		op-tmp)
                                           ((variable? op)	(<variable>-value op))
                                           (else		op))
                                         op arg-locs -c-))
          (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))

    (free-args -c- arg-locs)
    (free-temp op-tmp)))

(define-method compile-call-to <TI32> (op arg-locs -c-)
  (gen LOAD self)
  (gen CALLPTR arg-locs)
  ())

(define-method compile-call-to <pair> (op arg-locs -c-)
  (comp op)
  (gen CALLPTR arg-locs)
  ())

(define-method compile-call-to <expr> (op arg-locs -c-)
  ;; NOTE the fact that a literal <expr> is found in a variable's
  ;; value slot at compile time implies that it's a global definition.
  (if feature/redefinable-functions-in-target
      (let ()
        (comp op)
        (gen CALLPTR arg-locs))
    (gen CALL (LABEL (symbol->string (<variable>-name op))) arg-locs))
  ;; TODO FIXME self.n-required-parameters should work
  (<expr>-n-required-parameters self))

(define-method compile-call-to <C-function> (op arg-locs -c-)
  (gen CALL (GLOBAL-LABEL (<C-function>-name self)) arg-locs)
  (unless (<C-function>-vararg? self)
    (list-length (<C-function>-parameter-types self))))

(define-method compile-call-to (slave-value <selector>) (op arg-locs -c-)
  (gen CALL (LABEL (symbol->string (eval-in-slave `(<selector>-name ,self)))) arg-locs)
  ;; TODO extract and return n-params
  ())

;;;
;;; Compiling string literals
;;;

(define-function emit-string-as-C-string (self -c-)
  (let ((label (UNIQUE-LABEL "cstr")))
    (emit RODATA)
    (emit DEFLABEL label)
    (emit ASCIZ self)
    label))

(define-function emit-object-header (type-id)
  (let ((object-label	(UNIQUE-LABEL "ostr")))
    (emit RODATA)
    (emit ALIGN 4)
    ;; the gc header. we don't even emit the fields that shouldn't be read by anyone.
    ;; (emit LONG -42)                   ; next
    ;; (emit LONG -42)                   ; chunk size
    (emit LONG (slave-value (+ <header>-flags/used <header>-flags/opaque))) ; flags
    (emit LONG type-id)
    (when (slave-value feature/object-canary)
      (emit LONG (slave-value +canary-value+)))
    ;; start of the gc chunk payload
    (emit DEFLABEL object-label)
    object-label))

(assert (eval-in-slave '(is <immediate-type> <long>)) "emit-string-as-object only supports immediate <long> representation for now")

(define-function emit-string-as-object (self -c-)
  ;; KLUDGE this shouldn't be done by hand, but automated based on the type meta-data
  ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
  (let ((elements-label	(emit-string-as-C-string self -c-))
        (object-label	(emit-object-header (eval-in-slave `(<type>-slave-id (type-of ,self))))))
    ;; start of the gc chunk payload; as per the slots of <string>
    ;; FIXME this only works when <long> is an immediate
    (emit LONG (eval-in-slave `(box <long> ,(string-length self))))
    (emit LONG elements-label)
    object-label))

;;;
;;; Special Forms
;;;
(define-function compile/let-binding (binding comp)
  ;; we unconditionally initialize empty bindings to () to avoid hidden bugs,
  ;; at a small cost of initializing temp locations even when it wouldn't be necessary.
  ;; TODO cleanup! expand now brings let bindings to a normal form (to ease encode's job). think this through...
  (unless (pair? binding)
    (set binding (list binding ())))
  (unless (cdr binding)
    (set binding (list (car binding) ())))
  (let ((var (car binding))
        (tmp (compile/prog-into-temp (cdr binding) comp)))
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

(define-function compile/set (expr -c-)
  (let* ((var	(second expr))
         (value	(<variable>-value var)))
    (lexical-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ((temp? value)
       (gen STORE value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (gen STORE (GI32 (GLOBAL-LABEL (<C-variable>-name value)))))
      (else
       (gen STORE (GI32 (LABEL (<variable>-name var))))))))

(define-function compile/lambda (form -c-)
  (let ((name (unique-name "closure-"))
        (expr (eval form)))
    (compile-expr expr name false -c-)
    (gen LOAD (if feature/redefinable-functions-in-target
                  (GI32 (LABEL name))
                (LI32 (LABEL name))))))

(define-function compile/return (expr -c-)
  (list-do stmt (cdr expr)
    (comp stmt))
  (gen BR (or (<x86-compiler>-fn-epilogue-label -c-)
              (set (<x86-compiler>-fn-epilogue-label -c-) (UNIQUE-LABEL)))))

(define-function compile/address-of (expr -c-)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (cond
        ((global-variable? var)
         (gen ADDR (GI32 (LABEL (<variable>-name var)))))
        ((temp? val)
         (gen ADDR val))
        (else
         (error "address-of: don't know how to compile for variable " var ", holding the value " val))))))

(define-function compile/C-string (expr -c-)
  ;; just an optimization to compile string literals into a C string
  ;; when they would be immediately converted anyway.
  (assert (= (list-length expr) 2))
  (let ((label (emit-string-as-C-string (second expr) -c-)))
    (gen LOAD label)))

;;;
;;; linux syscalls
;;;
;;; TODO this should go into a separate file and only loaded as needed

(eval-in-slave `(define linux-syscall (fixed (lambda args (print "linux-syscall encountered in interpreted code with args " args "\n") (abort)))))

(define-emit    (LINUX-SYSCALL pair)
  (let ((args	$1)
        (regs	+linux/syscall-registers/32+))
    (while args
      (println "	movl	"(pop args)", "(pop regs))))
  (println "	int	$0x80"))

;; TODO add a <target-function> for this? or add a macro whose
;; expansion contains a literal x86 asm LINUX-SYSCALL instruction that
;; is passed through all the way to emit?
(define-function compile/linux-syscall (expr -c-)
  (let ((args		(cdr expr))
        (arg-locs	()))
    (while args
      (push arg-locs (compile/expr-into-temp-or-literal (pop args) -c-)))
    (free-temps arg-locs)
    (gen LINUX-SYSCALL (list-reverse! arg-locs))))

;;;
;;; +special-forms+
;;;
(define +special-forms+ (list
  (cons (target-value let)		compile/let)
  (cons (target-value and)		compile/and)
  (cons (target-value or)		compile/or)
  (cons (target-value if)		compile/if)
  (cons (target-value while)		compile/while)
  (cons (target-value set)		compile/set)
  (cons (target-value lambda)		compile/lambda)
  (cons (target-value return)		compile/return)
  (cons (target-value address-of)	compile/address-of)
  (cons (target-value linux-syscall)	compile/linux-syscall)
  (cons (target-value C-string)		compile/C-string)
  ))

;;;
;;; Special Operators
;;;

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  (gen op))

;; FIXME? these implement a right-to-left evaluation order, while
;; function calls implement the opposite. note that this is entangled
;; with e.g. the LOAD/STORE instructions above, as they expect arg0 to
;; be loaded in %eax.
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

;; a vector of assoc lists indexed by operator arity
(define +special-operators+
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
              (oop-at		,LOAD-OOP))
             ;; ternary
             ((set-char-at	,STORE-I8)
              (set-byte-at	,STORE-I8)
              (set-oop-at	,STORE-OOP)))))
      (list->array
       (map (lambda (arity-line)
              (map (lambda (entry)
                     (let* ((op-name (car entry))
                            (op (eval-in-target op-name)))
                       (assert op "operator not found while building +special-operators+: "op)
                       (cons op (cdr entry))))
                   arity-line))
            table))))

(define-method compile <undefined>  (-c-)  (gen LOAD (LI32 (target-value false))))
(define-method compile <long>       (-c-)  (gen LOAD (LI32 self)))

(define-method compile <variable> (-c-)
  (lexical-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (temp? value)
           (literal? value))
       (gen LOAD value))
      ((global-variable? self)
       (cond
         ((= 'true self.name)
          (gen LOAD (LI32 (target-value true))))
         ((subtype? (type-of value) <type>)
          (gen LOAD (LI32 (eval-in-slave `(<type>-slave-id ,value)))))
         ((is <C-function> value) ; handles the situation when e.g. libc/strcmp is passed as a comparator fn for array-binary-search
          (gen LOAD (LI32 (GLOBAL-LABEL (<C-function>-name value)))))
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (gen LOAD (GI32 (GLOBAL-LABEL (<C-variable>-name value)))))
         ((and (not feature/redefinable-functions-in-target)
               (is <expr> value))
          (gen LOAD (LI32 (LABEL self.name))))
         (else
          (gen LOAD (GI32 (LABEL self.name))))))
      (else
       (error "compile of <variable> failed for " self ", holding the value " value)))))

(define-method compile <string> (-c-)
  (let ((object-label (emit-string-as-object self -c-)))
    (gen LOAD object-label)))

;; this is used when emitting the literal dispatch tables of <selectors>
(define-method compile <array> (-c-)
  (let ((label (UNIQUE-LABEL "arr")))
    (emit RODATA)
    (emit DEFLABEL label)
    (array-do el self
      (cond
        ((not el)
         (emit LONG 0))
        ((and (is <variable> el)
              (is <expr> (<variable>-value el)))
         (emit LONG (LABEL (<variable>-name el))))
        (else (error "don't know how to emit constant array element "el))))
    (gen LOAD label)))

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
    (emit COMMENT (list "call of op: "op", op-is-a-var? "op-is-a-var?", args: " args))
    ;; TODO add compiler-macros. use them to optimize stuff on the lisp semantic level
    (cond
      ((set handler (second (assq op-value (array-at +special-operators+ arity))))
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((set handler (cdr (assq op +special-forms+)))
       (handler self -c-))
      (else
       (compile-call op args -c-)))))

;;;
;;; COMPILE-DEFINITION
;;;
(define-method compile-definition <type>		(name -c-)	(emit COMMENT (list "type "name))) ; we don't need (target-value <type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition 0 name -c-))
(define-method compile-definition <C-function>		(name -c-)	(emit COMMENT (list "C function "name))) ; it will be handled at the call site
(define-method compile-definition <C-variable>		(name -c-)	(emit COMMENT (list "C variable "name))) ; it will be handled at the site of reference

(define-method compile-definition <long> (name -c-)
  (emit DATA)
  (emit DEFLABEL (LABEL name))
  (emit LONG self))

;; (define-method compile-definition <string> (name -c-)
;;   (let ((temp (UNIQUE-LABEL "str")))
;;     (emit DATA)
;;     (emit DEFLABEL temp)
;;     (emit ASCIZ self)
;;     (emit ALIGN 4)
;;     (emit DEFLABEL (LABEL name))
;;     (emit LONG temp)
;;     ))

(define-method compile-definition <expr> (name parent-comp)
  (compile-expr self name true parent-comp))

(define-method emit-prelude <x86-compiler> ()
  (verbosity 1 (warn "\nCompiling to IA-32\n\n")))
