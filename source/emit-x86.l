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

(define-constant +external-label-prefix+
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
(define-operand LABEL () (name)		+maru-label-prefix+ (mangle-label self.name))		; a label that we generate
(define-operand EXTERNAL-LABEL LABEL ()	+external-label-prefix+ self.name)			; a label in the global C namespace
;; global, literal, and temp pointers
(define-operand GI32 () (name)		self.name)
(define-operand LI32 () (value)		"$"self.value)
(define-operand TI32 () (offset)	self.offset"(%esp)")

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
(define-emit    (ALIAS _ _)			(println "	.set "$1", "$2))
(define-emit    (EXPORT LABEL)			(println "	.globl "$1))
(define-emit    (ALIGN long)			(println "	.align " $1))
;; TODO rename to WORD and PTR, bring closer to the llvm backend
(define-emit    (LONG _)			(println "	.4byte	"$1))
(define-emit    (PTR _)				(println "	.4byte	"$1))
(define-emit    (ASCIZ string)			(print   "	.asciz ") (dumpln $1))
;; TODO rename to DEFINE
(define-emit    (DEFLABEL LABEL)		(println $1":"))

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
;; TODO arg2 is arg-locs. what for? for the arity? delme?
(define-emit    (CALL LABEL _)			(println "	call	"$1))

(define-emit    (LOAD LI32)			(if (= 0 (<LI32>-value $1))
                                                    (println "	xorl	%eax, %eax")
                                                  (println "	movl	"$1", %eax")))
(define-emit    (LOAD LABEL)			(println "	movl	$"$1", %eax"))
(define-emit    (LOAD _)			(println "	movl	"$1", %eax"))

(define-emit    (STORE _)			(println "	movl	%eax, "$1))

(define-emit    (ADDR GI32)			(println "	movl	$"$1", %eax"))
(define-emit    (ADDR _)			(println "	leal	"$1", %eax"))

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
                                                      (println "	movl	(%eax), %eax")
                                                    (println "	leal	"(* 4 offset)"(%eax), %ecx")
                                                    (println "	movl	(%ecx), %eax"))))

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
                                                        (println "	movl	"$2", %eax") ; this also leaves it as return value in %eax
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

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit COMMENT (list "COMPILE of "__obj__))
     (compile __obj__ -c-)))

(define compiler x86-compiler)

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
      (set c.param-offset (+ offset 4))
      temp)))

(define-function new-arg (c)
  (with-instance-accessors c <x86-compiler>
    (let* ((offset	c.arg-offset)
           (temp	(TI32 offset)))
      (set c.arg-offset (+ offset 4))
      temp)))

(define-function free-args (c args)
  (with-instance-accessors c <x86-compiler>
    (when (< c.arg-limit c.arg-offset)
      (set c.arg-limit c.arg-offset))
    (set c.arg-offset 0)))

;;;
;;; Emitting objects
;;;

;; KLUDGE this shouldn't be done by hand, but automated based on the type meta-data

(define-function emit-object/C-string (self)
  (let ((label (UNIQUE-LABEL "cstr")))
    (emit RODATA)
    (emit DEFLABEL label)
    (emit ASCIZ self)
    label))

;; these will be functions instantiated later. reason: to calculate
;; some stuff and capture the result into closures. this is a poor
;; man's staged computation to speed up object emission.
(define emit-object/header)
(define emit-object/<string>)
(define emit-object/box-<long>)
(define emit-object/<long>)
(define emit-object/<target-function>)

(define-function initialize-object-emitters ()
  (set emit-object/header
       (let ((flags		(slave-value (+ <header>-flags/used <header>-flags/opaque)))
             ;; TODO FIXME adding another level of let, or using let*
             ;; results in confused bindings and/or closure capturing.
             ;;(canary-value	(slave-value +canary-value+))
             (canary-emitter	(if (slave-value feature/object-canary)
                                    (lambda () (emit LONG (slave-value +canary-value+)))
                                  (lambda ()))))
         (lambda (type-id)
           (emit RODATA)
           (emit ALIGN 4)
           ;; the gc header. we don't even emit the fields that shouldn't be read by anyone.
           ;; (emit LONG -42)                   ; next
           ;; (emit LONG -42)                   ; chunk size
           (emit LONG flags)
           (emit LONG type-id)
           (canary-emitter))))

  (set emit-object/box-<long>
       (eval `(lambda (val)
                ,(expand '(box <long> val) *slave-env*))))

  (set emit-object/<long>
       ;; TODO it should be something like: (target-value <string>). see others, too.
       (let ((type-id (slave-value (<type>-slave-id <long>))))
         (cond
           ((slave-value (is <immediate-type> <long>))
            (lambda (self -c-)
              (emit-object/box-<long> self)))
           ((slave-value (and (is <boxed-type> <long>)
                              (<boxed-type>-one-word? <long>)))
            (lambda (self -c-)
              (emit-object/header type-id)
              (let ((object-label (UNIQUE-LABEL "olong")))
                (emit DEFLABEL object-label)
                (emit LONG self)
                object-label)))
           (else
            (error "emit-object/<long>: unexpected slave representation for <long>")))))

  (set emit-object/<string>
       (let ((type-id (slave-value (<type>-slave-id <string>))))
         (lambda (self -c-)
           (safety 1 (assert (is <string> self)))
           ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
           (let ((elements	(emit-object/C-string self))
                 (size		(emit-object/<long> (string-length self) -c-))
                 (object-label	(UNIQUE-LABEL "ostr")))
             (emit-object/header type-id)
             (emit DEFLABEL object-label)
             (emit PTR size)
             (emit PTR elements)
             object-label))))

  (set emit-object/<target-function>
       (let* ((type-id		(slave-value (<type>-slave-id <target-function>)))
              (null-value	(slave-value (<immediate-type>-tag-value <undefined>)))
              (name-factory	(when (slave-value feature/track-expr-names)
                                  (lambda (name -c-)
                                    (if name
                                        (emit-object/<string> (symbol->string name) -c-)
                                      null-value))))
              (feature/profiler	(slave-value feature/profiler)))
         (lambda (name entry-label -c-)
           (let ((object-label	(if name
                                    (LABEL (if feature/redefinable-functions-in-target
                                               (concat-string (symbol->string name) "__obj")
                                             name))
                                  (UNIQUE-LABEL "oclosure"))))
             (emit-object/header type-id)
             (emit DEFLABEL object-label)
             (emit PTR entry-label)
             (when name-factory
               (emit PTR (name-factory name -c-)))
             (when feature/profiler
               ;; TODO a counter in the read-only space?
               (emit PTR (emit-object/<long> 0 -c-)))
             object-label)))))

;;;
;;; Compiling lambdas
;;;

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

(define-function emit-expr-code (self entry-point-label parent-comp)
  (emit COMMENT (list "emitting <expr> "self", code: "(<expr>-body self)))
  (let* ((body		(<expr>-body self))
         (-c-		(x86-compiler (+ 1 (<compiler>-level parent-comp))))
         (init-param	(lambda (var)
                          (set (<variable>-value var) (new-param -c-))))
         (param-locs	(map init-param (<expr>-parameters self))))
    (list-do e body
      (and e (comp e)))
    ;; TODO investigate: probably only the frm-size needs to be aligned (on darwin)
    (let* ((arg-size (align +call-frame-alignmet+             (<x86-compiler>-arg-limit -c-)))
           (tmp-size (align +call-frame-alignmet+ (+ arg-size (* (<compiler>-temp-limit -c-)
                                                                 (target-value +word-size-in-bytes+)))))
           (frm-size (align +call-frame-alignmet+ (+ tmp-size 8))))
      (map (lambda (el) (set (<TI32>-offset el) (+ arg-size (<TI32>-offset el)))) (<compiler>-temps -c-))
      (map (lambda (el) (set (<TI32>-offset el) (+ frm-size (<TI32>-offset el)))) param-locs)
      (emit COMMENT (list "frame "arg-size" "(<compiler>-temp-limit -c-)" "tmp-size" "frm-size))
      ;; emitting begins
      (emit TEXT)
      (emit DEFLABEL entry-point-label)
      (emit ENTER (- frm-size 8))
      (emit-gen-buffer -c-)
      (awhen (<x86-compiler>-fn-epilogue-label -c-)
        (emit DEFLABEL it))
      (emit LEAVE (- frm-size 8))))
  entry-point-label)

(define-function closure-code-label (name)
  ;; KLUDGE object "names" (i.e. addresses) should be tied together
  ;; explicitly, not through giving them the "right" name
  (LABEL (concat-string (symbol->string name) "__code")))

(define-function compile-expr (self name -c-)
  (emit COMMENT (list "compiling fn "name", "self))
  (let ((entry-point (if name
                         (closure-code-label name)
                       (UNIQUE-LABEL "code"))))
    (emit-expr-code self entry-point -c-)
    (emit-object/<target-function> name entry-point -c-)))

;;;
;;; Compiling calls
;;;

(define-function compile-call (op args raw? -c-)
  (safety 2 (assert (or (pair? op) (variable? op))))
  ;; NOTE this implements a left-to-right evaluation order, including the operator.
  ;; i.e. moving this op-tmp means changing the evaluation order!
  (let ((op-tmp		(when (pair? op)
                          ;; optimization:
                          ;; we can spare a STORE/LOAD when we know that op
                          ;; doesn't evaluate anything; i.e. we can delay
                          ;; its evaluation, i.e. a simple LOAD, to the
                          ;; final, COMPILE-CALL-TO step.
                          (compile/expr-into-temp-or-literal op -c-)))
        (arg-tmps	(map-with compile/expr-into-temp-or-literal args -c-))
        (arg-locs	(map (lambda (_) (new-arg -c-)) args)))
    ;; set up the stack for the call
    (map (lambda (a b) (gen MOVE a b)) arg-tmps arg-locs)
    (free-temps arg-tmps)

    (let* ((op-value	(or op-tmp
                            (and (variable? op)
                                 (<variable>-value op))))
           (n-params	(if raw?
                            (let ()
                              (gen LOAD op-value)
                              (gen CALLPTR arg-locs)
                              ())
                          (compile-call-to op-value op arg-locs -c-)))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))

    (free-args -c- arg-locs)
    (free-temp op-tmp)))

(define-function compile-call-to-object (arg-locs -c-)
  ;; TODO assert the type to be <target-function>
  ;; TODO assert nr of args = params
  (gen LOAD-OOP (LI32 0)) ; TODO unreified way of reading the program-code slot
  (gen CALLPTR arg-locs)
  ())

(define-function compile-call-to-global-function (op arg-locs -c-)
  (if feature/redefinable-functions-in-target
      (let ()
        (comp op)
        (compile-call-to-object arg-locs -c-))
    (gen CALL (closure-code-label (<variable>-name op)) arg-locs))
  ())

(define-method compile-call-to <TI32> (op arg-locs -c-)
  (gen LOAD self)
  (compile-call-to-object arg-locs -c-))

;; this case is handled early in compile-call
;; (define-method compile-call-to <pair> (op arg-locs -c-)
;;   (comp op)
;;   (compile-call-to-object arg-locs -c-))

(define-method compile-call-to <expr> (op arg-locs -c-)
  ;; NOTE the fact that a literal <expr> is found in a variable's
  ;; value slot at compile time implies that it's a global definition.
  (compile-call-to-global-function op arg-locs -c-)
  (expr-n-required-parameters self))

(define-method compile-call-to <C-function> (op arg-locs -c-)
  (gen CALL (EXTERNAL-LABEL (<C-function>-name self)) arg-locs)
  (unless (<C-function>-vararg? self)
    (list-length (<C-function>-parameter-types self))))

(define-method compile-call-to (slave-value <selector>) (op arg-locs -c-)
  (compile-call-to-global-function op arg-locs -c-)
  ;; TODO extract and return n-params
  ())

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
    (accessible-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ((temp? value)
       (gen STORE value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (gen STORE (GI32 (EXTERNAL-LABEL (<C-variable>-name value)))))
      (else
       (gen STORE (GI32 (LABEL (<variable>-name var))))))))

(define-function compile/lambda (form -c-)
  (let ((expr (eval form)))
    (gen LOAD (compile-expr expr () -c-))))

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
  (let ((label (emit-object/C-string (second expr))))
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
      (println "	movl	"(pop args)", %"(pop regs))))
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
  ;;(cons (target-value C-call)		(lambda (expr -c-) (compile-call (second expr) (cddr expr) true -c-)))
  (cons (target-value stack-pointer-on-entry)	(lambda (expr -c-) (gen ADDR "4(%ebp)")))
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
  (accessible-variable-or-die self -c-)
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
          (gen LOAD (LI32 (EXTERNAL-LABEL (<C-function>-name value)))))
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (gen LOAD (GI32 (EXTERNAL-LABEL (<C-variable>-name value)))))
         ((and (not feature/redefinable-functions-in-target)
               (is <expr> value))
          (gen LOAD (LI32 (LABEL self.name))))
         (else
          (gen LOAD (GI32 (LABEL self.name))))))
      (else
       (error "compile of <variable> failed for " self ", holding the value " value)))))

(define-method compile <string> (-c-)
  (let ((object-label (emit-object/<string> self -c-)))
    (gen LOAD object-label)))

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
       (compile-call op args false -c-)))))

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

;; kinda KLUDGE
;; this is used when emitting the literal dispatch tables of <selectors>
(define-method compile-definition <array> (name -c-)
  (let ((compiled (compile-array self -c-))
        (array-label (UNIQUE-LABEL "arr")))
    (emit RODATA)
    (emit DEFLABEL array-label)
    (array-do el compiled
      (emit PTR el))
    (emit DATA)
    (emit DEFLABEL (LABEL name))
    (emit PTR array-label)))

(define-method compile-definition <expr> (name -c-)
  (let ((object-label (compile-expr self name -c-)))
    (when (member? name '(main _start))
      ;; KLUDGE export special casing
      (let ((external-label (EXTERNAL-LABEL name)))
        (emit ALIAS external-label (closure-code-label name))
        (emit EXPORT external-label)))
    (when feature/redefinable-functions-in-target
      (let ((label (LABEL name)))
        (emit DATA)
        (emit DEFLABEL label)
        (emit PTR object-label)))))

(define-method emit-prelude <x86-compiler> ()
  (verbosity 1 (warn "\nCompiling to IA-32\n\n"))
  (initialize-object-emitters))
