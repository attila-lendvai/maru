;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that targets static IA-32, aka x86 assembly, using the gcc toolchain.
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
;;;   - see the globals 'operators' and 'forms' for the list of specially
;;;     handled constructs
;;;
;;; Naming:
;;;   - EMIT: directly emits into the output stream
;;;   - GEN: collects instructions into a compiler object for later emission

(switch-to-slave-module)

(define return      (fixed (lambda args (error "(return) encountered in interpreted code"))))
(define address-of  (fixed (lambda args (error "(address-of) encountered in interpreted code"))))

(switch-to-host-module)

(define __MACH__  '( )) ; non-nil for Darwin / Mac OS X   (deal with the convoluted ABI)
(define __UNIX__  '( )) ; nin-nil for Unix, MinGW, etc.   (external symbols have underscore prefix)
(define __LINUX__ '(X)) ; non-nil for Linux, Cygwin, etc. (external symbols have no underscore prefix)

;;;----------------------------------------------------------------

(define __PREFIX__ (if __LINUX__ "" "_"))

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

(define-function align (alignment value)        (& (- alignment) (+ (- alignment 1) value )))

(define-form slave-value (form)
  `(eval-in-module slave ',form))

;;; EXTERN

(define-structure <extern> (name stub))

(define-function extern (name)
  (assert (= <string> (type-of name)) "extern called with a non-string: " name)
  (let ((self (new <extern>)))
    (set (<extern>-name self) name)
    self))

(define-function extern? (obj) (= <extern> (type-of obj)))

(define-function extern->label (extern)
  (concat-symbol (<extern>-name extern) '_stub))

;;; DEFINE-OPERAND

(define-function define-operand/make-setters (type-name fields)
  (if (pair? fields)
      (cons `(set (,(concat-symbol (concat-symbol type-name '-) (car fields)) self) ,(car fields))
            (define-operand/make-setters type-name (cdr fields)))))

(define-form define-operand (name fields . printing)
  (let ((type-name (symbol->type-name name)))
    (eval `(define-structure ,type-name ,fields))
    (eval `(define-function ,name ,fields
             (let ((self (new ,type-name)))
               ,@(define-operand/make-setters type-name fields)
               self)))
    `(define-method do-print ,type-name () (print ,@printing))))

;;; DEFINE-INSTRUCTION

(define-form define-instruction (name)
  (let ((type-name (symbol->type-name name)))
    `(let ()
       (define-structure ,type-name ())
       (define-method do-print ,type-name () (print ,(symbol->string name)))
       (define ,name (new ,type-name)))))

;;; DEFINE-EMIT

(define-generic emit op-args
  ;; EMIT directly emits into the output stream (c.f. with GEN that records)
  (error "no emit defined for: " op-args))

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
       (define-multimethod emit ((,type-name __op__) ,@(%define-emit-params 1 (cdr op-args)))
         ,@body))))

(define-function mangle-label (name)
  (let* ((plain   (symbol->string name))
         (length  (string-length plain))
         (mangled (array)) ; strings don't auto-expand, so we need to use arrays here
         (index   0)
         (outdex  0)
         (putnext (lambda (c)
                    (set-array-at mangled outdex c)
                    (set outdex (+ outdex 1))))
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
           (putnext (digit-for (>> c  4)))
           (putnext (digit-for (&  c 15))))))
      (set index (+ 1 index)))
    (array->string mangled outdex)))

;;; IA32 -- OPERANDS

(let ((counter 0))
  (define-function temp-label-name ()
    (concat-string "L_" (long->string (set counter (+ counter 1))))))

(define-operand LABEL (name)    __PREFIX__ (mangle-label (<LABEL>-name self)))
;; global, literal, and temp pointers
(define-operand GI32 (name)     (<GI32>-name self))
(define-operand LI32 (value)    (<LI32>-value self))
(define-operand TI32 (offset)   (<TI32>-offset self)"(%esp)")

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

(define-emit    (OR TI32)			(println "	orl	"$1", %eax"))

(define-emit    (XOR TI32)			(println "	xorl	"$1", %eax"))

(define-emit    (NOT)				(println "	cmpl	$0, %eax")
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

(define-emit    (COMMENT pair)			(print "## ") (apply println $1))

(define-emit    (CHR-AT TI32)			(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx), %ecx")
						(println "	xorl	%eax, %eax")
						(println "	movb	(%ecx), %al"))

(define-emit    (SET-CHR-AT TI32 TI32)		(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx), %ecx")
						(println "	movl	"$2", %eax")
						(println "	movb	%al, (%ecx)"))

(define-emit    (OOP-AT TI32)			(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx, 4), %ecx")
						(println "	movl	(%ecx), %eax"))

(define-emit    (SET-OOP-AT TI32 TI32)		(println "	movl	"$1", %ecx")
						(println "	leal	(%eax, %ecx, 4), %ecx")
						(println "	movl	"$2", %eax")
						(println "	movl	%eax, (%ecx)"))

;;;

(define-structure <compiler> (level param-counter arg-counter arg-limit tmp-counter tmp-limit temps epilogue gen-buffer gen-buffer-index))

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

;;; GEN

(define-selector gen)

(define-method gen <compiler> args
  ;; GEN collects the instructions to be EMIT'ed at a later time
  ;;(print "## insn ") (dumpln args)
  (set-array-at (<compiler>-gen-buffer self) (<compiler>-gen-buffer-index self) args)
  (set (<compiler>-gen-buffer-index self) (+ 1 (<compiler>-gen-buffer-index self))))

(define-function emit-gen-buffer (comp)
  (for (i 0 (<compiler>-gen-buffer-index comp))
    (apply emit (array-at (<compiler>-gen-buffer comp) i))))

(define-method gen <undefined>  (comp)  (gen comp LOAD (LI32 0)))
(define-method gen <long>       (comp)  (gen comp LOAD (LI32 self)))

(define-method gen <variable> (comp)
  (let ((value (<variable>-value self)))
    (cond
      ((temp? value)   (gen comp LOAD value))
      ((extern? value) (gen comp LOAD (GI32 (LABEL (extern->label value)))))
      (else            (gen comp LOAD (GI32 (LABEL (<variable>-name self))))))))

(define-method gen <string> (comp)
  (let ((label (LABEL (temp-label-name))))
    (gen comp DATA)
    (gen comp DEFLABEL label)
    (gen comp ASCIZ self)
    (gen comp TEXT)
    (gen comp LOAD label)))

(define-function gen-prog-into-temp (prog comp)
  (assert (pair? prog) "gen-prog-into-temp: prog is empty") ; against silently storing an uninitialized EAX while compiling e.g. (let (x) ...)
  (while (pair? prog)
    (gen (car prog) comp)
    (set prog (cdr prog)))
  (let ((t (alloc-temp comp)))
    (gen comp STORE t)
    t))

(define-function gen-tmp (expr comp)
  (gen expr comp)
  (let ((t (alloc-temp comp)))
    (gen comp STORE t)
    t))

(define-function gen-arg (expr comp)
  (new-arg comp))

(define-function gen-move (a b comp)
  (gen comp MOVE a b))

(define-function generate-nullary (op args comp)
  (gen comp op))

(define-function generate-unary (op args comp)
  (gen (car args) comp)
  (gen comp op))

(define-function generate-binary (op args comp)
  (let ((tmp (gen-tmp (cadr args) comp)))
    (gen (car  args) comp)
    (free-temp comp tmp)
    (gen comp op tmp)))

(define-function generate-ternary (op args comp)
  (let ((tmp2 (gen-tmp (caddr args) comp))
        (tmp1 (gen-tmp (cadr  args) comp)))
    (gen (car  args) comp)
    (free-temp comp tmp1)
    (free-temp comp tmp2)
    (gen comp op tmp1 tmp2)))

(define generators (list->array (list generate-nullary generate-unary generate-binary generate-ternary)))

;; a vector of assoc lists indexed by operator arity
(define operators
    (let ((table
           `(;; nullary
             ()
             ;; unary
             ((slave:-  ,NEG) (slave:not ,NOT))
             ;; binary
             ((slave:+  ,ADD) (slave:-   ,SUB) (slave:* ,MUL) (slave:/ ,DIV)
              (slave:&  ,AND) (slave:|   ,OR ) (slave:^ ,XOR)
              (slave:<  ,LT ) (slave:<=  ,LE ) (slave:= ,EQ ) (slave:!= ,NE) (slave:>= ,GE) (slave:> ,GT)
              (slave:<< ,SLA) (slave:>>  ,SRA)
              (slave:oop-at     ,OOP-AT)     (slave:string-at     ,CHR-AT))
             ;; ternary
             ((slave:set-oop-at ,SET-OOP-AT) (slave:set-string-at ,SET-CHR-AT)))))
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
                       (assert (= (type-of op) <subr>) "an operator is not (= (type-of op) <subr>)")
                       (cons op (cdr entry))))
                   arity-line))
            table))))

(define-function gen-let-binding (binding comp)
  ;; we unconditionally initialize empty bindings to () to avoid hidden bugs,
  ;; at a small cost of initializing temp locations even when it wouldn't be necessary.
  (unless (pair? binding)
    (set binding (list binding ())))
  (unless (cdr binding)
    (set binding (list (car binding) ())))
  (let ((var (car binding))
        (tmp (gen-prog-into-temp (cdr binding) comp)))
    (assert (= (type-of var) <variable>) "gen-let-binding: encountered a non-variable: " var)
    (set (<variable>-value var) tmp)))

(define-function gen-let (expr comp)
  (let ((temps (map-with gen-let-binding (caddr expr) comp)))
    (list-do stmt (cdddr expr) (gen stmt comp))
    (list-do temp temps (free-temp comp temp))))

(define-function gen-and (expr comp)
  (let ((done (LABEL (temp-label-name))))
    (set expr (cdr expr))
    (while expr
      (gen (car expr) comp)
      (and (set expr (cdr expr)) (gen comp BF done)))
    (gen comp DEFLABEL done)))

(define-function gen-or (expr comp)
  (let ((done (LABEL (temp-label-name))))
    (set expr (cdr expr))
    (while expr
      (gen (car expr) comp)
      (and (set expr (cdr expr)) (gen comp BT done)))
    (gen comp DEFLABEL done)))

(define-function gen-if (expr comp)
  (let ((a (LABEL (temp-label-name)))
        (b (LABEL (temp-label-name))))
    (gen (cadr expr) comp)
    (gen comp BF a)
    (gen (caddr expr) comp)
    (gen comp BR b)
    (gen comp DEFLABEL a)
    (list-do stmt (cdddr expr) (gen stmt comp))
    (gen comp DEFLABEL b)))

(define-function gen-while (expr comp)
  (let ((body (LABEL (temp-label-name)))
        (test (LABEL (temp-label-name))))
    (gen comp BR test)
    (gen comp DEFLABEL body)
    (list-do stmt (cddr expr)
      (and stmt (gen stmt comp)))
    (gen comp DEFLABEL test)
    (gen (cadr expr) comp)
    (gen comp BT body)))

(define-function gen-set (expr comp)
  (let* ((var (cadr expr))
         (val (<variable>-value var)))
    (gen (caddr expr) comp)
    (cond
      ((temp? val)   (gen comp STORE val))
      ((extern? val) (gen comp STORE (GI32 (LABEL (extern->label val))))) ; TODO maybe this shouldn't even be supported?
      (else          (gen comp STORE (GI32 (LABEL (<variable>-name var))))))))

(define-function gen-lambda (expr comp)
  (error "gen: lambda forms are not supported"))

(define-function gen-return (expr comp)
  (list-do stmt (cdr expr) (gen stmt comp))
  (gen comp BR (or (<compiler>-epilogue comp) (set (<compiler>-epilogue comp) (LABEL (temp-label-name))))))

(define-function gen-address-of (expr comp)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (if (temp? val)
          (gen comp ADDR val)
        (gen comp ADDR (GI32 (LABEL (<variable>-name var))))))))

(define forms (list
  (cons (slave-value slave:let)            gen-let)
  (cons (slave-value slave:and)            gen-and)
  (cons (slave-value slave:or)             gen-or)
  (cons (slave-value slave:if)             gen-if)
  (cons (slave-value slave:while)          gen-while)
  (cons (slave-value slave:set)            gen-set)
  (cons (slave-value slave:lambda)         gen-lambda)
  (cons (slave-value slave:return)         gen-return)
  (cons (slave-value slave:address-of)     gen-address-of)))

(define-method gen <pair> (comp)
  (let* ((fn-name (car self))
         (args    (cdr self))
         (arity   (list-length args))
         (op      (and (variable? fn-name)
                       (cadr (assq (<variable>-value fn-name) (array-at operators arity))))))
    (if op
        ((array-at generators arity) op args comp)
      (if (set op (cdr (assq fn-name forms)))
          (op self comp)
        (let* ((tmp-locs (map-with gen-tmp args comp))
               (arg-locs (map-with gen-arg args comp))
               ;;(op       (cdr (assq fn-name (<compiler>-env comp))))
               ;;(op-type  (type-of op))
               )
          ;; TODO this is useful, reinstate
          ;; (if (= <expr> op-type)
          ;;     (let* ((defn   (<expr>-defn op))
          ;;            (params (car defn)))
          ;;     ;; TODO this is broken, at least for dotted lists
          ;;     (when (pair? params) ; ignore (lambda args ...) format, e.g. println
          ;;       (let ((nparam (list-length params)))
          ;;         (or (= nparam arity)
          ;;             (error "gen: calling " op
          ;;                    " with the wrong number of arguments: " args
          ;;                    ", expecting " nparam))))))
          (gen fn-name comp)
          (map2-with gen-move tmp-locs arg-locs comp)
          (free-temps comp tmp-locs)
          (free-args  comp arg-locs)
          (gen comp CALL arity))))))

;;; GEN-DEFINITION

(define-selector gen-definition)

(define-method gen-definition <long> (name comp)
  (gen comp DATA)
  (gen comp DEFLABEL (LABEL name))
  (gen comp LONG self)
  (gen comp TEXT))

;; (define-method gen-definition <string> (name comp)
;;   (let ((temp (LABEL (temp-label-name))))
;;     (gen comp DATA)
;;     (gen comp DEFLABEL temp)
;;     (gen comp ASCIZ self)
;;     (gen comp ALIGN 4)
;;     (gen comp DEFLABEL (LABEL name))
;;     (gen comp LONG temp)
;;     (gen comp TEXT)))

(define-method gen-definition <extern> (name comp)
  (let ((extern-label (LABEL self.name))
        (our-label    (LABEL (extern->label self))))
    (if __MACH__
        (let ()
          (gen comp SECTION "__IMPORT,__pointers,non_lazy_symbol_pointers")
          (gen comp DEFLABEL our-label)
          (gen comp INDIRECT extern-label)
          (gen comp LONG 0)
          (gen comp TEXT))
      (gen comp DATA)
      (gen comp DEFLABEL our-label)
      (gen comp LONG extern-label)
      (gen comp TEXT))))

(define-method gen-definition <form> (name comp)
  (gen comp COMMENT (list "form "name)))

(define-function gen-param (var comp)
  (set (<variable>-value var) (new-param comp)))

(define-method gen-definition <expr> (name ocomp)
  (let* ((main? (= 'slave:main name))
         (defn (<expr>-defn self))
         (body (cddr defn))
         (comp (compiler (+ 1 (<compiler>-level ocomp))))
         (entry-label (LABEL (concat-string (symbol->string name) (if main? "" "_body"))))
         (params (map-with gen-param (cadr defn) comp)))
    (list-do e body
      (and e (gen e comp)))
    (let* ((arg-size (align 16             (<compiler>-arg-limit comp) ))
           (tmp-size (align 16 (+ arg-size (<compiler>-tmp-limit comp))))
           (frm-size (align 16 (+ tmp-size 8))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp)))) (<compiler>-temps comp))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ frm-size (<TI32>-offset tmp)))) params)
      (emit TEXT)
      (when main?
        (emit GLOBAL entry-label))
      (emit DEFLABEL entry-label)
      (emit COMMENT (list "frame "arg-size" "(<compiler>-tmp-limit comp)" "tmp-size" "frm-size))
      (emit ENTER (- frm-size 8))
      (emit-gen-buffer comp)
      (and (<compiler>-epilogue comp)
           (emit DEFLABEL (<compiler>-epilogue comp)))
      (emit LEAVE (- frm-size 8)))
    (unless main?
      (let ()
        (gen ocomp DATA)
        (gen ocomp GLOBAL (LABEL name))
        (gen ocomp DEFLABEL (LABEL name))
        (gen ocomp LONG entry-label)
        (gen ocomp TEXT)))))

;;;

(define-function gen-env (env)
  (warn "begin compiling\n")
  (let* ((vars  (<env>-bindings env))
         (comp  (compiler 0))
         (index (array-length vars)))
    (while (<= 0 (set index (- index 1)))
      (let* ((var (array-at vars index))
             (name  (<variable>-name  var))
             (value (<variable>-value var)))
        (println "## defn " name)
        (warn name ", ")
        (gen-definition value name comp)))
    (warn "\n")
    (emit-gen-buffer comp)))

;;;
;;; definitions visible in the slave
;;;
(switch-to-slave-module)

(define-function compile-begin ()
  (set *globals* (environment *globals*)))

(define-function compile-end ()
  (let ((env *globals*))
    (set *globals* (<env>-parent env))
    (eval-in-module host `(host:gen-env (host:quote ,env)))))

(define-form define-externs args
  `(let ()
     ,@(map (lambda (libc-name)
              (let ((maru-name (concat-symbol 'libc/ libc-name)))
                `(define ,maru-name (eval-in-module host (list 'host:extern ,(symbol->string libc-name))))))
            args)))
