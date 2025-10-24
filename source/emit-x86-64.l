;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits IA-32 text, aka x86 assembly, that
;;; needs to be fed to the gcc toolchain.
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
;;;   - some literal objects are emitted as valid objects that can participate
;;;     in the heap; see emit-object/<string> and co. for an up-to-date list.
;;;   - probaby more
;;;   - see +special-operators+ and *special-forms* for the list of specially
;;;     handled constructs
;;;
;;; Naming:
;;;   - EMIT: emit instructions into the output stream
;;;   - GEN:  like EMIT, but collect instructions into a buffer for later emission
;;;   - -foo- is an implicit var in the lexenv
;;;   - +foo+ is a constant
;;;   - *foo* is a global

(require "source/emit-early.l")

(define-constant +external-label-prefix+
    (case (target-value +operating-system+)
      (darwin	"_")
      (else	"")))

(define-constant +call-frame-alignmet+
  ;; TODO? on IA-32 this is simply (/ (target-value +word-size-in-bits+) 8)
  16)

(unless (= 64 (target-value +word-size-in-bits+))
  (error "The x86 compiler backend doesn't support target word size "(target-value +word-size-in-bits+)))

;; TODO this is kludgey. why only this one, etc...
(define-constant +word-size-in-bytes+ (target-value +word-size-in-bytes+))

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

;; this is faster than (emit COMMENT ...) by skipping the evaluation early
(define-form emit-comment (level . args)
  `(when (<= ,level *compiler-verbosity*)
     (emit COMMENT (list ,@args))))

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
(define-operand GI64 () (name)		self.name)
(define-operand LI64 () (value)		"$"self.value)
(define-operand TI64 () (offset)	self.offset"(%rsp)")
(define-operand GR32 () (name)		self.name)
(define-operand GR64 () (name)		self.name)

(define-function UNIQUE-LABEL args
  (LABEL (unique-name (or (first args) "L"))))

;;;
;;; IA32 -- INSTRUCTIONS
;;;
(define-emit    (COMMENT pair)			(when (<= 1 *compiler-verbosity*) (print "# ") (apply println $1)))

(define-emit    (TEXT)				(println "	.text"))
(define-emit    (DATA)				(println "	.section .data"))
(define-emit    (RODATA)			(println "	.section .rodata"))
;;(define-emit    (SECTION string)		(println "	.section "$1))

;;(define-emit    (INDIRECT LABEL)		(println "	.indirect_symbol "$1))
(define-emit    (TYPE _ _)			(println "	.type "$1", "$2))
(define-emit    (ALIAS _ _)			(println "	.set "$1", "$2))
(define-emit    (EXPORT LABEL)			(println "	.globl "$1))
(define-emit    (ALIGN long)			(println "	.align " $1))
;; TODO rename to WORD? bring closer to the llvm backend
(define-emit    (LONG _)			(println "	.8byte	"$1))
(define-emit    (PTR _)				(println "	.8byte	"$1))
(define-emit    (ASCIZ string)			(print   "	.asciz ") (dumpln $1))
;; TODO rename to DEFINE? that would be less unique
(define-emit    (DEFLABEL LABEL)		(println $1":"))

;; ENTER is slow, so don't use it (LEAVE is fine): https://stackoverflow.com/questions/5959890/enter-vs-push-ebp-mov-ebp-esp-sub-esp-imm-and-leave-vs-mov-esp-ebp
(define-emit    (ENTER long)			(println "	push	%rbp")
						(println "	mov	%rsp, %rbp")
						(unless (= 0 $1)
                                                  (println "	sub	$"$1", %rsp")))

(define-emit    (LEAVE long)			(println "	leave")
						(println "	ret"))

(define-emit    (SEXT GR32 GR64)		(println "	movslq	"$1", "$2))

(define-emit    (NEG)				(println "	neg	%rax"))

(define-emit    (ADD TI64)			(println "	add	"$1", %rax"))

(define-emit    (ADD LI64)			(unless (= 0 (<LI64>-value $1))
                                                  (println "	add	"$1", %rax")))

(define-emit    (SUB TI64)			(println "	sub	"$1", %rax"))

(define-emit    (SUB LI64)			(unless (= 0 (<LI64>-value $1))
                                                  (println "	sub	"$1", %rax")))

(define-emit    (MUL TI64)			(println "	mulq	"$1))

(define-emit    (MUL LI64)			(cond
                                                  ((= (<LI64>-value $1) 1)) ; nothing to do
                                                  ;; TODO emit shifts when possible
						  (else
                                                   (println "	mov	"$1", %rcx")
						   (println "	mulq	%rcx"))))

(define-emit    (DIV TI64)			(println "	xor	%rdx, %rdx")
						(println "	divq	"$1))

(define-emit    (DIV LI64)			(cond
                                                  ((= (<LI64>-value $1) 1)
                                                   ;; remainder is zero, %rax is unchanged
                                                   (println "	xor	%rdx, %rdx"))
                                                  ;; TODO emit shifts when possible
                                                  (else
                                                   (println "	xor	%rdx, %rdx") ; the upper side of 64 bit operand
						   (println "	mov	"$1", %rcx") ; divisor
						   (println "	divq	%rcx"))))    ; divl is unsigned division

(define-emit    (AND TI64)			(println "	and	"$1", %rax"))
(define-emit    (AND LI64)			(unless (= -1 (<LI64>-value $1))
                                                  (println "	and	"$1", %rax")))
(define-emit    (OR  TI64)			(println "	or	"$1", %rax"))
(define-emit    (OR  LI64)			(unless (= 0 (<LI64>-value $1))
                                                  (println "	or	"$1", %rax")))
(define-emit    (XOR TI64)			(println "	xor	"$1", %rax"))
(define-emit    (XOR LI64)			(unless (= 0 (<LI64>-value $1))
                                                  (println "	xor	"$1", %rax")))
(define-emit    (BITWISE-NOT)			(println "	not	%rax"))

(define-emit    (LOGIC-NOT)			(println "	test	%rax, %rax")
						(println "	sete	%al")
						(println "	movzb	%al, %rax"))

(define-form define-emit/comparator (maru-name x86-name)
  (unless (defined? maru-name)
    ;; TODO KLUDGE we need to do this early, otherwise the expanded define-emit's would define it twice in their own expand-time
    (eval `(define-instruction ,maru-name)))
  `(let ()
     (define-emit (,maru-name TI64)
       (println "	cmp	"$1", %rax")
       (println "	" ,x86-name "	%al")
       (println "	movzb	%al, %rax"))
     (define-emit (,maru-name LI64)
       (println "	cmp	"$1", %rax")
       (println "	" ,x86-name "	%al")
       (println "	movzb	%al, %rax"))))

(define-emit/comparator LT "setl")
(define-emit/comparator LE "setle")
(define-emit/comparator EQ "sete")
(define-emit/comparator GE "setge")
(define-emit/comparator GT "setg")
;;(define-emit/comparator NE "setne")

(define-emit    (ASL TI64)			(println "	mov	"$1", %rcx")
						(println "	sal	%cl, %rax"))

(define-emit    (ASL LI64)			(unless (= 0 (<LI64>-value $1))
                                                  (println "	shl	"$1", %rax")))

(define-emit    (ASR TI64)			(println "	mov	"$1", %rcx")
						(println "	sar	%cl, %rax"))

(define-emit    (ASR LI64)			(unless (= 0 (<LI64>-value $1))
                                                  (println "	sar	"$1", %rax")))

(define-emit    (BR LABEL)			(println "	jmp	"$1))

(define-emit    (BF LABEL)			(println "	test	%rax, %rax")
						(println "	je	"$1))

(define-emit    (BT LABEL)			(println "	test	%rax, %rax")
						(println "	jne	"$1))

(define-emit    (CALLPTR _)			(println "	call	*%rax"))
;; TODO arg2 is arg-locs. what for? for the arity? delme?
(define-emit    (CALL LABEL _)			(println "	call	"$1))

(define-emit    (LOAD LI64)			(if (= 0 (<LI64>-value $1))
                                                    (println "	xorq	%rax, %rax")
                                                  (println "	mov	"$1", %rax")))
(define-emit    (LOAD TI64)			(println "	mov	"$1", %rax"))
(define-emit    (LOAD GR64)			(println "	mov	"$1", %rax"))
(define-emit    (LOAD LABEL)			(println "	lea	"$1"(%rip), %rax"))

(define-emit    (LOAD GI64)			(println "	lea	"$1"(%rip), %rax")
						(println "	mov	(%rax), %rax"))

(define-emit    (STORE GI64)			(println "	lea	"$1"(%rip), %rbx")
						(println "	mov	%rax, (%rbx)"))

(define-emit    (STORE GR64)			(println "	mov	%rax, ("$1")"))

(define-emit    (STORE _)			(println "	mov	%rax, "$1))

(define-emit    (ADDR GI64)			(println "	lea	"$1"(%rip), %rax"))
(define-emit    (ADDR _)			(println "	lea	"$1", %rax"))

(define-emit    (MOVE TI64 TI64)		(println "	mov	"$1", %rcx")
						(println "	mov	%rcx, "$2))

(define-emit    (MOVE _ _)			(println "	movq	"$1", "$2))

;; TODO what about sign extension? maybe we will need a separate set of LOAD and STORE for signed and unsigned?
;; in haskell the signed ones are called integer, and the unsigned one are called word.
;; for now these are all unsigned, i.e. not sign extended.
(define-emit    (LOAD-I8 TI64)			(println "	mov	"$1", %rcx")
						(println "	lea	(%rax, %rcx), %rcx")
						(println "	xor	%rax, %rax")
						(println "	movb	(%rcx), %al"))

(define-emit    (LOAD-I8 LI64)			(let ((offset (<LI64>-value $1)))
                                                  (if (= 0 offset)
                                                      (println "	mov	%rax, %rcx")
                                                    (println "	lea	"offset"(%rax), %rcx")))
						(println "	xor	%rax, %rax")
						(println "	movb	(%rcx), %al"))

(define-emit    (STORE-I8 TI64 _)		(if-at-expand feature/strict-semantics-for-compiled-set
						    ;; NOTE this works out just fine for a TI64, too, because we are little-endian.
                                                    (let ()
                                                      (println "	mov	"$1", %rcx")
						      (println "	lea	(%rax, %rcx), %rcx")
                                                      (println "	xor	%rax, %rax")
                                                      (println "	movb	"$2", %al")
						      (println "	movb	%al, (%rcx)"))
;;                                                  (println "	mov	"$1", %rcx")
                                                  (println "	lea	"$1"(%rip), %rcx")
						  (println "	lea	(%rax, %rcx), %rax")
						  (println "	movb	"$2", (%rax)")))

(define-emit    (STORE-I8 LI64 _)		(let ((offset (<LI64>-value $1)))
                                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                                      (let ()
                                                        (if (= 0 offset)
                                                            (println "	mov	%rax, %rcx")
                                                          (println "	lea	"offset"(%rax), %rcx"))
                                                        (println "	xor	%rax, %rax")
                                                        (println "	movb	"$2", %al") ; this also leaves it as return value in %rax
						        (println "	movb	%al, (%rcx)"))
                                                    (unless (= 0 offset)
                                                      (println "	lea	"offset"(%rax), %rax"))
                                                    (println "	movb	"$2", (%rax)"))))

(define-emit    (LOAD-OOP TI64)			(println "	mov	"$1", %rcx")
						(println "	lea	(%rax, %rcx, "+word-size-in-bytes+"), %rcx")
						(println "	mov	(%rcx), %rax"))

(define-emit    (LOAD-OOP LI64)			(let ((offset (<LI64>-value $1)))
                                                  (if (= 0 offset)
                                                      (println "	mov	(%rax), %rax")
                                                    (println "	lea	"(* +word-size-in-bytes+ offset)"(%rax), %rcx")
                                                    (println "	mov	(%rcx), %rax"))))

(define-emit    (STORE-OOP TI64 _)		(if-at-expand feature/strict-semantics-for-compiled-set
                                                    (let ()
                                                      (println "	mov	"$1", %rcx")
						      (println "	lea	(%rax, %rcx, "+word-size-in-bytes+"), %rcx")
                                                      (println "	mov	"$2", %rax")
						      (println "	mov	%rax, (%rcx)"))
                                                  (println "	mov	"$1", %rcx")
						  (println "	lea	(%rax, %rcx, "+word-size-in-bytes+"), %rax")
                                                  (println "	mov	"$2", (%rax)")))

(define-emit    (STORE-OOP LI64 _)		(let ((offset (<LI64>-value $1)))
                                                  (if-at-expand feature/strict-semantics-for-compiled-set
                                                      (let ()
                                                        (if (= 0 offset)
                                                            (println "	mov	%rax, %rcx")
                                                          (println "	lea	"(* +word-size-in-bytes+ offset)"(%rax), %rcx"))
                                                        (println "	mov	"$2", %rax") ; this also leaves it as return value in %rax
                                                        (println "	mov	%rax, (%rcx)"))
                                                    (unless (= 0 offset)
                                                      (println "	lea	"(* +word-size-in-bytes+ offset)"(%rax), %rax"))
                                                    (println "	mov	"$2", (%rax)"))))

;;;
;;; Compiler Infrastructure
;;;
(define-constant +param-registers+ ''("%rdi" "%rsi" "%rdx" "%rcx" "%r8" "%r9"))

(define-record <x86-compiler> <compiler>
  (param-offset
   ;; params-spilled? ; did we already copy our args to the stack?
   ;; params-must-be-spilled
   arg-registers
   arg-offset ; only the args that spilled to the stack
   arg-limit
   fn-epilogue-label))

(define-function x86-compiler (level)
  (make <x86-compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (gen-buffer			(array))

    (param-offset		0)
    ;; (params-must-be-spilled	false)
    (arg-registers		+param-registers+)
    (arg-offset			0)
    (arg-limit			0)))

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit-comment 2 "COMPILE of "__obj__)
     (compile __obj__ -c-)))

(define compiler x86-compiler)

(define-function new-temp (-c-)
  (TI64 (* (new-temp-index -c-) +word-size-in-bytes+)))

(define-function %free-temp (-c- obj)
  (when (is <TI64> obj)
    (push (<compiler>-temps -c-) obj)))

(define-form gen args
  `(array-append (<compiler>-gen-buffer -c-) (list ,@args)))

(define-function emit-gen-buffer (-c-)
  (array-do entry (<compiler>-gen-buffer -c-)
    (emit-comment 3 "emit-gen-buffer, inst: " entry)
    (apply emit-instruction entry)))

;; (define-function new-param (c)
;;   (with-instance-accessors c <x86-compiler>
;;     (let ((reg (pop c.param-registers)))
;;       (if reg
;;           (let ()
;;             (assert (string? reg))
;;             (GR64 reg))
;;         (let ((offset	c.param-offset))
;;           (set c.param-offset (+ offset +word-size-in-bytes+))
;;           (TI64 offset))))))

(define-function new-arg (c)
  (with-instance-accessors c <x86-compiler>
    (let ((reg (pop c.arg-registers)))
      (if reg
          (let ()
            (assert (string? reg))
            (GR64 reg))
        (let ((offset	c.arg-offset))
          (set c.arg-offset (+ offset +word-size-in-bytes+))
          (TI64 offset))))))

(define-function free-args (c args)
  (with-instance-accessors c <x86-compiler>
    (when (< c.arg-limit c.arg-offset)
      (set c.arg-limit c.arg-offset))
    (set c.arg-offset 0)
    (set c.arg-registers +param-registers+)))

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
(define emit-object/<long>)
(define emit-object/<target-function>)

(define-function initialize-object-emitters ()
  (set emit-object/header
       (let ((flags		(slave-value (+ <header>-flags/used <header>-flags/opaque)))
             ;; TODO FIXME adding another level of let, or using let*
             ;; results in confused bindings and/or closure capturing.
             ;; TODO undo the inlining once eval/closures/bug/1 is fixed
             ;;(canary-value	(slave-value +canary-value+))
             (canary-emitter	(if (slave-value feature/object-canary)
                                    (lambda () (emit LONG (slave-value +canary-value+)))
                                  (lambda ()))))
         (lambda (type type-id)
           (emit-comment 1 "object header")
           ;; NOTE cannot use RODATA because the header and the object
           ;; payload must be consequtive, but the payload values must
           ;; be relocatable.
           (emit DATA)
           (emit ALIGN +word-size-in-bytes+)

           ;; NEXT and CHUNK-SIZE should only ever be read by the GC,
           ;; but this here is the emission of read-only literals. the
           ;; GC should never walk these objects, therefore we can
           ;; skip emitting the first two words of the header.

           ; next         ; not emitted
           ; chunk size   ; not emitted
           (emit LONG flags)
           (emit-comment 2 "type: "type)
           (emit LONG type-id)
           (canary-emitter)
           ; the object pointer points here
           )))

  (set emit-object/<long>
       ;; TODO it should be something like: (target-value <string>). see others, too.
       (cond
         ((slave-value (is <immediate-type> <long>))
          (lambda (self -c-)
            ;; instead of a label (a pointer) we return with an immediate tagged mword
            (eval-in-slave `(box <long> ,self))))
         ((slave-value (and (is <boxed-type> <long>)
                            (<boxed-type>-one-word? <long>)))
          (let ((type-id (slave-value (<type>-slave-id <long>))))
            (lambda (self -c-)
              (emit-object/header <long> type-id)
              (let ((object-label (UNIQUE-LABEL "olong")))
                (emit DEFLABEL object-label)
                (emit LONG self)
                object-label))))
         (else
          (error "emit-object/<long>: unexpected slave representation for <long>"))))

  (set emit-object/<string>
       (let ((type-id (slave-value (<type>-slave-id <string>))))
         (lambda (self -c-)
           (safety 1 (assert (is <string> self)))
           ;; NOTE self here is a host string object, i.e. it's not according to the slave layout
           (let ((elements	(emit-object/C-string self))
                 (size		(emit-object/<long> (string-length self) -c-))
                 (object-label	(UNIQUE-LABEL "ostr")))
             (emit-object/header <string> type-id)
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
              (profiler?	(slave-value feature/profiler)))
         (lambda (name entry-label -c-)
           (let ((object-label	(if name
                                    (LABEL (if feature/redefinable-functions-in-target
                                               (concat-string (symbol->string name) "__obj")
                                             name))
                                  (UNIQUE-LABEL "oclosure")))
                 (name		(when name-factory
                                  ;; NOTE this must happen first due
                                  ;; to the order of emission.
                                  (name-factory name -c-)))
                 (counter	(when profiler?
                                  (emit-object/<long> 0 -c-))))
             (emit-object/header <target-function> type-id)
             (emit DEFLABEL object-label)
             (emit PTR entry-label)
             (when name
               (emit PTR name))
             (when counter
               (emit PTR counter))
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
     (LI64 expr))
    (else
      (comp expr)
      (let ((temp (alloc-temp -c-)))
        (gen STORE temp)
        temp))))

;; When a function calls another function then it will need to
;; overwrite the registers where it has received its own params. A
;; simple solution is to spill the params to the stack when we
;; encounter the first function call.
;; (define-function spill-params (expr -c-)
;;   (emit-comment 1 "spilling "(list-length (<expr>-parameters expr))" params to the stack")
;;   (map (lambda (var)
;;          (let ((loc (<variable>-value var)))
;;            (unless (is <TI64> loc)
;;              (let ((reg (<variable>-value var))
;;                    (temp (pop (<x86-compiler>-param-spill-locs -c-))))
;;                (assert temp)
;;                (assert (is <GR64> reg))
;;                (set (<variable>-value var) temp)
;;                (gen MOVE reg temp)))))
;;        (<expr>-parameters expr)))

(define-function emit-expr-code (self entry-point-label parent-comp)
  ;; NOTE printing the code as-is, i.e. without escaping, may break the comment syntax
  (emit-comment 1 "emitting "self", at level: "(<compiler>-level parent-comp))
  (emit-comment 3 ", code: "(<expr>-body self))
  (let* ((word-size (eval-at-expand
                     (target-value +word-size-in-bytes+)))
         (body	(<expr>-body self))
         (-c-	(x86-compiler (+ 1 (<compiler>-level parent-comp))))
         (param-locs
           (let ((param-regs +param-registers+))
             (map (lambda (var)
                    ;; KLUDGE this writes some internal compiler state (the
                    ;; location of this param on the stack) into the source
                    ;; code.
                    (aif (pop param-regs)
                        (let ((spill-loc (new-temp -c-)))
                          ;; preallocate spill locations; used by MAYBE-SPILL-PARAMS
                          (set (<variable>-value var) spill-loc)
                          (GR64 it))
                      (let ((offset (<x86-compiler>-param-offset -c-)))
                        (incr (<x86-compiler>-param-offset -c-) word-size)
                        ;; this extends the stack frame size as needed
                        (TI64 offset))))
                  (<expr>-parameters self)))))

    ;; Unconditionally spill the params to the stack.
    (emit-comment 1 "spilling "(list-length param-locs)" params to the stack")
    (map (lambda (param-loc var)
           (when (is <GR64> param-loc)
             (let ((spilled-loc (<variable>-value var)))
               (gen MOVE param-loc spilled-loc))))
         param-locs (<expr>-parameters self))

    ;; Compile the fn body first into the gen buffer (COMP is a form,
    ;; we cannot map it).
    (list-do el body
      (comp el))

    ;; Calculate the frame and emit the entire fn
    (let* ((arg-size	(<x86-compiler>-arg-limit -c-))
           (temp-size	(+ arg-size
                           (* (<compiler>-temp-limit -c-)
                              word-size)))
           (frame-size	(align +call-frame-alignmet+
                               ;; the pushed %ebp and the return address (?)
                               (+ temp-size
                                  (* 2 +word-size-in-bytes+))))
           (frame-body-size (- frame-size (* 2 word-size))))
      ;; Now that we know the frame size, fix up the offsets of the
      ;; temps allocated on the stack.
      (map (lambda (el)
             (incr (<TI64>-offset el) arg-size))
           (<compiler>-temps -c-))
      ;; Params could also be accessed through %ebp, but for that we
      ;; would need another operand class. Let's just offset them by
      ;; the frame size and use %esp through simple TI64.
      (map (lambda (loc)
             (when (is <TI64> loc) ; the first few loc's are in registers
               (incr (<TI64>-offset loc) frame-size)))
           param-locs)
      ;; actual emitting begins
      (emit TEXT)
      (emit DEFLABEL entry-point-label)
      (emit-comment 1 "params: "(list-length (<expr>-parameters self))
                    ", frame-size: "frame-size"("(/ frame-size word-size)
                    "), arg-size: " arg-size  "("(/ arg-size word-size)
                    "), temp-size: "temp-size "("(/ temp-size word-size)")")
      (emit ENTER frame-body-size)
      (emit-gen-buffer -c-)
      (awhen (<x86-compiler>-fn-epilogue-label -c-)
        (emit DEFLABEL it))
      (emit LEAVE frame-body-size)))
  entry-point-label)

(define-function closure-code-label (name)
  ;; KLUDGE object "names" (i.e. addresses) should be tied together
  ;; explicitly, not through giving them the "right" name
  (LABEL (concat-string (symbol->string name) "__code")))

(define-function compile-expr (self name -c-)
  (emit-comment 1 "compiling fn "name", "self)
  (let ((entry-point (if name
                         (closure-code-label name)
                       (UNIQUE-LABEL "code"))))
    (emit-expr-code self entry-point -c-)
    (emit-object/<target-function> name entry-point -c-)))

;;;
;;; Compiling calls
;;;

(define-function compile-call-form (op args raw? -c-)
  (emit-comment 2 "compile-call: "op", args: "args", raw?: "raw?)
  (safety 2 (assert (or (pair? op) (variable? op))))
  ;; (set (<x86-compiler>-params-must-be-spilled -c-) true)
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
                            (if (variable? op)
                                (<variable>-value op)
                              op)))
           (n-params	(if raw?
                            (let ()
                              (gen LOAD op-value)
                              (gen CALLPTR arg-locs)
                              ())
                          (emit-comment 2 "compile-call-to: "op-value)
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
  (gen LOAD-OOP (LI64 0)) ; TODO unreified way of reading the program-code slot
  (gen CALLPTR arg-locs)
  ())

(define-function compile-call-to-global-function (op arg-locs -c-)
  (if feature/redefinable-functions-in-target
      (let ()
        (comp op)
        (compile-call-to-object arg-locs -c-))
    (gen CALL (closure-code-label (<variable>-name op)) arg-locs))
  ())

(define-method compile-call-to <target-function> (op arg-locs -c-)
  (comp op)
  (compile-call-to-object arg-locs -c-))

(define-method compile-call-to <TI64> (op arg-locs -c-)
  (gen LOAD self)
  (compile-call-to-object arg-locs -c-))

(define-method compile-call-to <GR64> (op arg-locs -c-)
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
  (case (<C-function>-return-type self)
    ;; TODO introduce a proper infrastructure for this
    (int
     (gen SEXT (GR32 "%eax") (GR64 "%rax")))
    (short
     (error "TODO sign-extend a short to 64 bits")))
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
      ((or (is <TI64> value)
           (is <GR64> value))
       (gen STORE value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (gen STORE (GI64 (EXTERNAL-LABEL (<C-variable>-name value)))))
      (else
       (gen STORE (GI64 (LABEL (<variable>-name var))))))))

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
         (gen ADDR (GI64 (LABEL (<variable>-name var)))))
        ((is <TI64> val)
         (gen ADDR val))
        ;; ((is <GR64> val)
        ;;  (maybe-spill-params -c-)
        ;;  (gen ADDR (<variable>-value var)))
        (else
         (error "address-of: don't know how to compile for variable " var ", holding the value " val))))))

(define-function compile/C-string (expr -c-)
  ;; just an optimization to compile string literals into a C string
  ;; when they would be immediately converted anyway.
  (assert (= (list-length expr) 2))
  (let ((label (emit-object/C-string (second expr))))
    (gen LOAD label)))

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
  ;;(cons (target-value C-call)		(lambda (expr -c-) (compile-call-form (second expr) (cddr expr) true -c-)))
  (cons (target-value stack-pointer-on-entry)
        (lambda (expr -c-)
          ;; the function prologue we also employ is like this:
          ;;
          ;; push	%rbp
          ;; mov	%rsp, %rbp
          ;; sub	$36, %rsp
          ;; ...
          ;;
          ;; so, the 8(%rbp) is to undo the push %rbp, so that we
          ;; regain the %rsp value at the entry point to the function.
          (gen ADDR "8(%rbp)")))
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

(define-method compile <undefined>  (-c-)  (gen LOAD (LI64 (target-value false))))
(define-method compile <long>       (-c-)  (gen LOAD (LI64 self)))

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (is <GR64> value)
           (is <LI64> value)
           (is <TI64> value))
       (gen LOAD value))
      ((global-variable? self)
       (cond
         ((= 'true self.name)
          (gen LOAD (LI64 (target-value true))))
         ((subtype? (type-of value) <type>)
          (gen LOAD (LI64 (eval-in-slave `(<type>-slave-id ,value)))))
         ((is <C-function> value) ; handles the situation when e.g. libc/strcmp is passed as a comparator fn for array-binary-search
          (gen LOAD (EXTERNAL-LABEL (<C-function>-name value))))
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (gen LOAD (GI64 (EXTERNAL-LABEL (<C-variable>-name value)))))
         ((and (not feature/redefinable-functions-in-target)
               (is <expr> value))
          (gen LOAD (LABEL self.name)))
         (else
          (gen LOAD (GI64 (LABEL self.name))))))
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
    (when (<= 2 *compiler-verbosity*)
      (emit-comment 1 "call of op: "op", op-is-a-var? "op-is-a-var?", args: " args))
    ;; TODO add compiler-macros. use them to optimize stuff on the lisp semantic level
    (cond
      ((set handler (second (assq op-value (array-at +special-operators+ arity))))
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((is <fixed> op)
       (let ((handler (cdr (assq op *special-forms*))))
         (or handler (error "No handler for fixed form: " self))
         (handler self -c-)))
      (else
       (compile-call-form op args false -c-)))))

;;;
;;; COMPILE-DEFINITION
;;;
(define-method compile-definition <type>		(name -c-)	(emit COMMENT (list "type "name))) ; we don't need (target-value <type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition (target-value false) name -c-))
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
    (emit DATA)
    (emit DEFLABEL array-label)
    (array-do el compiled
      (emit PTR el))
    (emit DEFLABEL (LABEL name))
    (emit PTR array-label)))

(define-method compile-definition <expr> (name -c-)
  (assert name)
  (let ((object-label (compile-expr self name -c-))
        (code-label   (closure-code-label name)))
    (if (member? name '(main _start)) ; KLUDGE special case the entry points
        (let ((external-label (EXTERNAL-LABEL name)))
          (emit ALIAS external-label code-label)
          (emit EXPORT external-label))
      (emit EXPORT code-label))
    (emit TYPE code-label "@function")
    (when feature/redefinable-functions-in-target
      (let ((label (LABEL name)))
        (emit DATA)
        (emit DEFLABEL label)
        (emit PTR object-label)))))

(define-method emit-prelude <x86-compiler> ()
  (verbosity 1 (warn "\nCompiling to x86-64\n\n"))
  (initialize-object-emitters))

(require "source/emit-late.l")
