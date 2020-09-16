;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits IA-32 text, aka x86 assembly, using the gcc toolchain.
;;;
;;; Status: it should successfully compile eval.l into eval.s,
;;; that in turn can be compiled by the gcc toolchain into an executable eval binary.
;;;

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

(define-constant +label-prefix+ (cond
                                  ((= target/os "darwin") "_")
                                  (else "")))

(define-constant +call-frame-alignmet+ (cond
                                         ((= target/os "darwin") 16)
                                         (else (/ target/word-size-in-bits 8))))

(let ((word-size target/word-size-in-bits))
  (unless (= 32 word-size)
    (error "The x86 compiler backend doesn't support target word size " word-size)))

;;; DEFINE-OPERAND

(define-function define-operand/make-setters (type-name fields)
  (if (pair? fields)
      (cons `(set (,(concat-symbol (concat-symbol type-name '-) (car fields)) self) ,(car fields))
            (define-operand/make-setters type-name (cdr fields)))))

(define-form define-operand (name fields . printing)
  (let ((type-name (symbol->type-name name)))
    (eval `(define-record ,type-name () ,fields))
    (eval `(define-function ,name ,fields
             (let ((self (new ,type-name)))
               ,@(define-operand/make-setters type-name fields)
               self)))
    `(define-method do-print ,type-name () (print ,@printing))))

;;; DEFINE-INSTRUCTION

(define-form define-instruction (name)
  (let ((type-name (symbol->type-name name)))
    `(let ()
       (define-type ,type-name)
       (define-method do-print ,type-name () (print ,(symbol->string name)))
       (define ,name (new ,type-name)))))

;;; DEFINE-EMIT

(define-form emit args
  `(emit-instruction ,@args))

(define-generic emit-instruction op-args
  (error "no emit-instruction defined for: " op-args))

(define-function %define-emit-param-name (index)
  (string->symbol (concat-string "$" (long->string index))))

(define-function %define-emit-params (index types)
  (when (pair? types)
    (cons (list (symbol->type-name (car types)) (%define-emit-param-name index))
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
  (let* ((plain   (symbol->string name))
         (length  (string-length plain))
         (mangled (array)) ; strings don't auto-expand, so we need to use arrays here
         (index   0)
         (outdex  0)
         (putnext (lambda (c)
                    (set-array-at mangled outdex c)
                    (incr outdex)))
         (digit-for (lambda (c)
                      (if (< c 10)
                          (+ c ?0)
                          (+ c (- ?A 10))))))
    (while (< index length)
      (let ((c (string-at plain index)))
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
           (putnext (digit-for (bitwise-asr c 4)))
           (putnext (digit-for (bitwise-and c 0xf))))))
      (incr index))
    (array->string mangled)))

;;; IA32 -- OPERANDS

(define-operand LABEL (name)    +label-prefix+ (mangle-label (<LABEL>-name self)))
;; global, literal, and temp pointers
(define-operand GI32 (name)     (<GI32>-name self))
(define-operand LI32 (value)    (<LI32>-value self))
(define-operand TI32 (offset)   (<TI32>-offset self)"(%esp)")

(define-function UNIQUE-LABEL ()
  (LABEL (unique-name "L_")))

(define-function temp? (obj)    (= <TI32> (type-of obj)))

;;; IA32 -- INSTRUCTIONS

(define-emit    (TEXT)				(println "	.text"))
(define-emit    (DATA)				(println "	.data"))
(define-emit    (SECTION string)		(println "	.section "$1))

(define-emit    (INDIRECT LABEL)		(println "	.indirect_symbol "$1))
(define-emit    (GLOBAL LABEL)			(println "	.globl "$1))

(define-emit    (ALIGN long)			(println "	.align " $1))

(define-emit    (LONG long)			(println "	.long	"$1))
(define-emit    (LONG LABEL)			(println "	.long	"$1))

(define-emit    (ASCIZ string)			(print   "	.asciz ") (dumpln $1))

(define-emit    (DEFLABEL LABEL)		(println $1":"))

;; ENTER is slow, so don't use it (LEAVE is fine): http://agner.org/optimize
(define-emit    (ENTER long)			(println "	pushl	%ebp")
						(println "	movl	%esp, %ebp")
						(println "	subl	$"$1", %esp"))

(define-emit    (LEAVE long)			(println "	leave")
						(println "	ret"))

(define-emit    (NEG)				(println "	negl	%eax"))

(define-emit    (ADD TI32)			(println "	addl	"$1", %eax"))

(define-emit    (SUB TI32)			(println "	subl	"$1", %eax"))

(define-emit    (MUL TI32)			(println "	mull	"$1))

(define-emit    (DIV TI32)			(println "	movl	$0, %edx")
						(println "	divl	"$1))

(define-emit    (AND TI32)			(println "	andl	"$1", %eax"))
(define-emit    (OR  TI32)			(println "	orl	"$1", %eax"))
(define-emit    (XOR TI32)			(println "	xorl	"$1", %eax"))
(define-emit    (BITWISE-NOT)			(println "	notl	%eax"))

(define-emit    (LOGIC-NOT)			(println "	cmpl	$0, %eax")
						(println "	sete	%al")
						(println "	movzbl	%al, %eax"))

(define-emit    (LT TI32)			(println "	cmpl	"$1", %eax")
						(println "	setl	%al")
						(println "	movzbl	%al, %eax"))

(define-emit    (LE TI32)			(println "	cmpl	"$1", %eax")
						(println "	setle	%al")
						(println "	movzbl	%al, %eax"))

(define-emit    (EQ TI32)			(println "	cmpl	"$1", %eax")
						(println "	sete	%al")
						(println "	movzbl	%al, %eax"))

(define-emit    (NE TI32)			(println "	cmpl	"$1", %eax")
						(println "	setne	%al")
						(println "	movzbl	%al, %eax"))

(define-emit	(GE TI32)			(println "	cmpl	"$1", %eax")
						(println "	setge	%al")
						(println "	movzbl	%al, %eax"))

(define-emit    (GT TI32)			(println "	cmpl	"$1", %eax")
						(println "	setg	%al")
						(println "	movzbl	%al, %eax"))

(define-emit    (SLA TI32)			(println "	movl	"$1", %ecx")
						(println "	shll	%cl, %eax"))

(define-emit    (SRA TI32)			(println "	movl	"$1", %ecx")
						(println "	sarl	%cl, %eax"))

(define-emit    (BR LABEL)			(println "	jmp	"$1))

(define-emit    (BF LABEL)			(println "	cmpl	$0, %eax")
						(println "	je	"$1))

(define-emit    (BT LABEL)			(println "	cmpl	$0, %eax")
						(println "	jne	"$1))

(define-emit    (CALL long)			(println "	call	*%eax"))
(define-emit    (CALL LABEL)			(println "	call	"$1))

(define-emit    (LOAD LI32)			(println "	movl	$"$1", %eax"))
(define-emit    (LOAD LABEL)			(println "	movl	$"$1", %eax"))
(define-emit    (LOAD GI32)			(println "	movl	" $1", %eax"))
(define-emit    (LOAD TI32)			(println "	movl	" $1", %eax"))

(define-emit    (STORE TI32)			(println "	movl	%eax, "$1))
(define-emit    (STORE GI32)			(println "	movl	%eax, "$1))

(define-emit    (ADDR GI32)			(println "	movl	$"$1", %eax"))
(define-emit    (ADDR TI32)			(println "	leal	"$1", %eax"))

(define-emit    (MOVE TI32 TI32)		(println "	movl	"$1", %ecx")
						(println "	movl	%ecx, "$2))

(define-emit    (COMMENT pair)			(when *compiler-verbose* (print "## ") (apply println $1)))

(define-emit    (LOAD-I8 TI32)			(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx), %ecx")
						(println "	xorl	%eax, %eax")
						(println "	movb	(%ecx), %al"))

(define-emit    (STORE-I8 TI32 TI32)		(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx), %ecx")
						(println "	movl	"$2", %eax")
						(println "	movb	%al, (%ecx)"))

(define-emit    (LOAD-OOP TI32)			(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx, 4), %ecx")
						(println "	movl	(%ecx), %eax"))

(define-emit    (STORE-OOP TI32 TI32)		(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx, 4), %ecx")
						(println "	movl	"$2", %eax")
						(println "	movl	%eax, (%ecx)"))

;;;

(define-record <compiler> () (level param-counter arg-counter arg-limit tmp-counter tmp-limit temps epilogue gen-buffer gen-buffer-index))

(define-function compiler (level)
  (let ((self (new <compiler>)))
    (set (<compiler>-level		self) level)
    (set (<compiler>-param-counter	self) 0)
    (set (<compiler>-arg-counter	self) 0)
    (set (<compiler>-arg-limit		self) 0)
    (set (<compiler>-tmp-counter	self) 0)
    (set (<compiler>-tmp-limit		self) 0)
    (set (<compiler>-gen-buffer		self) (array))
    (set (<compiler>-gen-buffer-index	self) 0)
    self))

(define-function %save-into-gen-buffer (-c- . args)
  (set-array-at (<compiler>-gen-buffer -c-) (<compiler>-gen-buffer-index -c-) args)
  (incr (<compiler>-gen-buffer-index -c-)))

(define-form gen args
  `(%save-into-gen-buffer -c- ,@args))

(define-function emit-gen-buffer (-c-)
  (for (i 0 (<compiler>-gen-buffer-index -c-))
    (apply emit-instruction (array-at (<compiler>-gen-buffer -c-) i))))

(define-function new-param (comp)
  (let* ((i (<compiler>-param-counter comp))
         (t (TI32 i)))
    (set (<compiler>-param-counter comp) (+ i 4))
    t))

(define-function new-arg (comp)
  (let* ((i (<compiler>-arg-counter comp))
         (t (TI32 i)))
    (set (<compiler>-arg-counter comp) (+ i 4))
    t))

(define-function free-args (comp args)
  (and (< (<compiler>-arg-limit comp) (<compiler>-arg-counter comp))
       (set (<compiler>-arg-limit comp) (<compiler>-arg-counter comp)))
  (set (<compiler>-arg-counter comp) 0))

(define-function new-temp (comp)
  (let* ((i (<compiler>-tmp-counter comp))
         (t (TI32 i)))
    (set (<compiler>-tmp-counter comp) (+ i 4))
    (and (< (<compiler>-tmp-limit comp) (<compiler>-tmp-counter comp))
         (set (<compiler>-tmp-limit comp) (<compiler>-tmp-counter comp)))
    t))

(define-function alloc-temp (comp)
  (or (pop (<compiler>-temps comp))
      (new-temp comp)))

(define-function free-temp (comp temp)          (push (<compiler>-temps comp) temp))
(define-function free-temps (comp temps)        (list-do temp temps (free-temp comp temp)))

;;; COMPILE

(define-form comp (obj)
  `(compile ,obj -c-))

(define-selector compile)

(define-method compile <undefined>  (-c-)  (gen LOAD (LI32 (slave-value slave:target-boolean/false))))
(define-method compile <long>       (-c-)  (gen LOAD (LI32 self)))

(define-method compile <variable> (-c-)
  (let ((value self.value))
    (cond
      ((temp? value)
       (gen LOAD value))
      ((and (global-variable? self)
            (= 'slave:true self.name))
       (gen LOAD (LI32 (slave-value slave:target-boolean/true))))
      ((and (global-variable? self)
            (subtype? (type-of value) <type>))
       (gen LOAD (LI32 (eval-in-module slave `(slave:<type>-slave-id ,value)))))
      (else
       (gen LOAD (GI32 (LABEL self.name)))))))

(define-method compile <string> (-c-)
  (let ((label (UNIQUE-LABEL)))
    (gen DATA)
    (gen DEFLABEL label)
    (gen ASCIZ self)
    (gen TEXT)
    (gen LOAD label)))

(define-function compile/prog-into-temp (prog -c-)
  (assert (pair? prog) "compile/prog-into-temp: prog is empty") ; against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  (while (pair? prog)
    (comp (car prog))
    (set prog (cdr prog)))
  (let ((temp (alloc-temp -c-)))
    (gen STORE temp)
    temp))

(define-function compile/expr-into-temp (expr -c-)
  (comp expr)
  (let ((temp (alloc-temp -c-)))
    (gen STORE temp)
    temp))

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  (gen op))

(define-function compile/binary-operator (op args -c-)
  (let ((tmp (compile/expr-into-temp (cadr args) -c-)))
    (comp (car args))
    (free-temp -c- tmp)
    (gen op tmp)))

(define-function compile/ternary-operator (op args -c-)
  (let ((tmp2 (compile/expr-into-temp (caddr args) -c-))
        (tmp1 (compile/expr-into-temp (cadr  args) -c-)))
    (comp (car args))
    (free-temp -c- tmp1)
    (free-temp -c- tmp2)
    (gen op tmp1 tmp2)))

(define +operator-compilers+ (list->array (list () compile/unary-operator compile/binary-operator compile/ternary-operator)))

;; a vector of assoc lists indexed by operator arity
(define +special-operators+
    (let ((table
           `(;; nullary
             ()
             ;; unary
             ((slave:-  ,NEG) (slave:not ,LOGIC-NOT) (slave:bitwise-not ,BITWISE-NOT))
             ;; binary
             ((slave:+  ,ADD) (slave:-   ,SUB) (slave:* ,MUL) (slave:/ ,DIV)
              (slave:bitwise-and ,AND) (slave:bitwise-or ,OR) (slave:bitwise-xor ,XOR)
              (slave:<  ,LT ) (slave:<=  ,LE ) (slave:= ,EQ ) (slave:!= ,NE) (slave:>= ,GE) (slave:> ,GT)
              (slave:bitwise-asl ,SLA) (slave:bitwise-asr  ,SRA)
              (slave:byte-at		,LOAD-I8)
              (slave:string-at		,LOAD-I8)
              (slave:oop-at		,LOAD-OOP))
             ;; ternary
             ((slave:set-byte-at	,STORE-I8)
              (slave:set-string-at	,STORE-I8)
              (slave:set-oop-at		,STORE-OOP)))))
      (list->array
       (map (lambda (arity-line)
              (map (lambda (entry)
                     (let* ((op-name (car entry))
                            (op (eval-in-module slave op-name)))
                       ;; NOTE this is not (slave-value slave:<subr>), because it's the eval.exe of the
                       ;; previous stage that instantiates these subr's, and it instantiates them
                       ;; with the type that is encoded into the executable (which should be in sync
                       ;; with the definitions in the boot.l of that stage, which in turn is what we
                       ;; see here at runtime).
                       ;;(assert (= (type-of op) <subr>) "an operator is not (= (type-of op) <subr>)")
                       (cons op (cdr entry))))
                   arity-line))
            table))))

(define-function compile/let-binding (binding comp)
  ;; we unconditionally initialize empty bindings to () to avoid hidden bugs,
  ;; at a small cost of initializing temp locations even when it wouldn't be necessary.
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
    (free-temps -c- temps)))

(define-function compile/and (expr -c-)
  (let ((done (UNIQUE-LABEL)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (and (set expr (cdr expr)) (gen BF done)))
    (gen DEFLABEL done)))

(define-function compile/or (expr -c-)
  (let ((done (UNIQUE-LABEL)))
    (set expr (cdr expr))
    (while expr
      (comp (car expr))
      (and (set expr (cdr expr)) (gen BT done)))
    (gen DEFLABEL done)))

(define-function compile/if (expr -c-)
  (let ((a (UNIQUE-LABEL))
        (b (UNIQUE-LABEL)))
    (comp (cadr expr))
    (gen BF a)
    (comp (caddr expr))
    (gen BR b)
    (gen DEFLABEL a)
    (list-do stmt (cdddr expr)
      (comp stmt))
    (gen DEFLABEL b)))

(define-function compile/while (expr -c-)
  (let ((body (UNIQUE-LABEL))
        (test (UNIQUE-LABEL)))
    (gen BR test)
    (gen DEFLABEL body)
    (list-do stmt (cddr expr)
      (and stmt (comp stmt)))
    (gen DEFLABEL test)
    (comp (cadr expr))
    (gen BT body)))

(define-function compile/set (expr -c-)
  (let* ((var (cadr expr))
         (val (<variable>-value var)))
    (comp (caddr expr))
    (cond
      ((temp? val)   (gen STORE val))
      (else          (gen STORE (GI32 (LABEL (<variable>-name var))))))))

(define-function compile/lambda (expr comp)
  (error "gen: lambda forms are not supported"))

(define-function compile/return (expr -c-)
  (list-do stmt (cdr expr)
    (comp stmt))
  (gen BR (or (<compiler>-epilogue -c-)
              (set (<compiler>-epilogue -c-) (UNIQUE-LABEL)))))

(define-function compile/address-of (expr -c-)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (if (temp? val)
          (gen ADDR val)
        (gen ADDR (GI32 (LABEL (<variable>-name var))))))))

(define +special-forms+ (list
  (cons (slave-value slave:let)            compile/let)
  (cons (slave-value slave:and)            compile/and)
  (cons (slave-value slave:or)             compile/or)
  (cons (slave-value slave:if)             compile/if)
  (cons (slave-value slave:while)          compile/while)
  (cons (slave-value slave:set)            compile/set)
  (cons (slave-value slave:lambda)         compile/lambda)
  (cons (slave-value slave:return)         compile/return)
  (cons (slave-value slave:address-of)     compile/address-of)))

(define-method compile <pair> (-c-)
  (let* ((op		(first self))
         (op-is-a-var?	(variable? op))
         (args		(rest self))
         (arity		(list-length args))
         (handler	()))
    (cond
      ((set handler (and op-is-a-var?
                         (cadr (assq (<variable>-value op) (array-at +special-operators+ arity)))))
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((set handler (cdr (assq op +special-forms+)))
       (handler self -c-))
      (else
       (let ((ff-name ())
             (op-is-simple? ())
             (arg-tmps (map-with compile/expr-into-temp args -c-)))
         (when (and op-is-a-var?
                    (global-variable? op))
           (let ((value		(<variable>-value op))
                 (n-params	()))
             (cond
               ((expr? value)
                (set op-is-simple? true)
                (set n-params (<expr>-n-required-parameters value)))
               ((= (type-of value) <foreign-function>)
                (set ff-name (<foreign-function>-name value))
                (unless (<foreign-function>-vararg? value)
                  (set n-params (list-length (<foreign-function>-parameter-types value)))))
               (else
                (error "Don't know how to emit call to global value "value", in variable "op)))
             (when (and n-params
                        (not (= n-params arity)))
               (error "compile: calling " value
                      " with the wrong number of arguments: " args
                      ", while expecting " n-params))))

         (let ((op-tmp (unless (or op-is-simple?
                                   ff-name)
                         (compile/expr-into-temp op -c-)))
               (arg-locs (map (lambda (_) (new-arg -c-)) args)))
           ;; set up the stack for the call
           (map (lambda (a b) (gen MOVE a b)) arg-tmps arg-locs)
           (free-temps -c- arg-tmps)

           (cond
             (ff-name
              (gen CALL (LABEL ff-name)))
             (op-is-simple?
              (comp op)
              (gen CALL arity))
             (else
              (gen LOAD op-tmp)
              (gen CALL arity)))

           (free-args  -c- arg-locs)
           (when op-tmp
             (free-temp -c- op-tmp))))))))

;;; COMPILE-DEFINITION

(define-selector compile-definition)

(define-method compile-definition <form>		(name -c-)	(gen COMMENT (list "form "name)))
(define-method compile-definition <type>		(name -c-)	(gen COMMENT (list "type "name))) ; we don't need (slave-value slave:<type>) here because <type> is "reused" by the slave from the host
(define-method compile-definition <undefined>		(name -c-)	(compile-definition 0 name -c-))
(define-method compile-definition <foreign-function>	(name -c-)	(gen COMMENT (list "foreign function "name))) ; it will be handled at the call site

(define-method compile-definition <long> (name -c-)
  (gen DATA)
  (gen DEFLABEL (LABEL name))
  (gen LONG self)
  (gen TEXT))

;; (define-method compile-definition <string> (name -c-)
;;   (let ((temp (UNIQUE-LABEL)))
;;     (gen DATA)
;;     (gen DEFLABEL temp)
;;     (gen ASCIZ self)
;;     (gen ALIGN 4)
;;     (gen DEFLABEL (LABEL name))
;;     (gen LONG temp)
;;     (gen TEXT)))

(define-method compile-definition <expr> (name parent-comp)
  (let* ((main? (= 'slave:main name))
         (body (<expr>-body self))
         (-c- (compiler (+ 1 (<compiler>-level parent-comp))))
         (entry-label (LABEL (concat-string (symbol->string name) (if main? "" "_body"))))
         (init-param (lambda (var)
                       (set (<variable>-value var) (new-param -c-))))
         (params (map init-param (<expr>-parameters self))))
    (list-do e body
      (and e (comp e)))
    ;; TODO investigate: probably only the frm-size needs to be aligned (on darwin)
    (let* ((arg-size (align +call-frame-alignmet+             (<compiler>-arg-limit -c-) ))
           (tmp-size (align +call-frame-alignmet+ (+ arg-size (<compiler>-tmp-limit -c-))))
           (frm-size (align +call-frame-alignmet+ (+ tmp-size 8))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp)))) (<compiler>-temps -c-))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ frm-size (<TI32>-offset tmp)))) params)
      (emit TEXT)
      (when main?
        (emit GLOBAL entry-label))
      (emit DEFLABEL entry-label)
      (emit COMMENT (list "frame "arg-size" "(<compiler>-tmp-limit -c-)" "tmp-size" "frm-size))
      (emit ENTER (- frm-size 8))
      (emit-gen-buffer -c-)
      (and (<compiler>-epilogue -c-)
           (emit DEFLABEL (<compiler>-epilogue -c-)))
      (emit LEAVE (- frm-size 8)))
    (unless main?
      (let ((-c- parent-comp))
        (gen DATA)
        (gen GLOBAL (LABEL name))
        (gen DEFLABEL (LABEL name))
        (gen LONG entry-label)
        (gen TEXT)))))

;;;

(define-function compile-env (env)
  (warn "begin compiling\n")
  (let* ((vars  (<env>-bindings env))
         (-c-  (compiler 0)))
    (for (i 0 (array-length vars))
      (let* ((var   (array-at vars i))
             (name  (<variable>-name  var))
             (value (<variable>-value var)))
        (emit COMMENT (list "defn " name))
        (warn name ", ")
        (compile-definition value name -c-)))
    (warn "\n")
    (emit-gen-buffer -c-)))
