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
;;;
;;; Understands some primitives:
;;;   - RETURN (from the current function)
;;;   - ADDRESS-OF
;;;   - [SET-]OOP-AT, [SET-]STRING-AT
;;;
;;; Naming:
;;;   - EMIT: directly emits into the output stream
;;;   - GEN: collects instructions into a compiler object for later emission

(define __MACH__  '( )) ; non-nil for Darwin / Mac OS X   (deal with the convoluted ABI)
(define __UNIX__  '( )) ; nin-nil for Unix, MinGW, etc.   (external symbols have underscore prefix)
(define __LINUX__ '(X)) ; non-nil for Linux, Cygwin, etc. (external symbols have no underscore prefix)

;;;----------------------------------------------------------------

(define __PREFIX__ (if __LINUX__ "" "_"))

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

(define-function align (alignment value)        (& (- alignment) (+ (- alignment 1) value )))

;;; EXTERN

(define-structure <extern> (name stub))

(define-function extern (name)
  (let ((self (new <extern>)))
    (set (<extern>-name self) name)
    self))

(define-function extern? (obj) (= <extern> (type-of obj)))

(define-function extern->label (extern)
  (concat-symbol (<extern>-name extern) '_stub))

;;; DEFINE-OPERAND

(define-function define-operand-make-setters (type-name fields)
  (if (pair? fields)
      (cons `(set (,(concat-symbol (concat-symbol type-name '-) (car fields)) self) ,(car fields))
            (define-operand-make-setters type-name (cdr fields)))))

(define-form define-operand (name fields . printing)
  (let ((type-name (symbol->type-name name)))
    (eval `(define-structure ,type-name ,fields))
    (eval `(define-function ,name ,fields
             (let ((self (new ,type-name)))
               ,@(define-operand-make-setters type-name fields)
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

(define-multimethod emit ((<pair> program))
  (while program
    (apply emit (car program))
    (set program (cdr program))))

(define-function %define-emit-param-name (index)
  (string->symbol (concat-string "$" (long->string index))))

(define-function %define-emit-params (index types)
  (if (pair? types)
      (cons (list (symbol->type-name (car types)) (%define-emit-param-name index))
            (%define-emit-params (+ index 1) (cdr types)))))

(define-form define-emit (op-args . body)
  (let* ((opsym (car op-args))
         (type-name (symbol->type-name opsym)))
    `(let ()
       ,@(if (not (assq opsym (<module>-env (current-module)))) `((define-instruction ,opsym)))
       (define-multimethod emit ((,type-name op) ,@(%define-emit-params 1 (cdr op-args))) ,@body))))

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
          ((or (= ?/ c)
               (= ?- c)
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

(define-emit    (TEXT)                  (println "	.text"))
(define-emit    (DATA)                  (println "	.data"))
(define-emit    (SECTION string)        (println "	.section "$1))

(define-emit    (INDIRECT LABEL)        (println "	.indirect_symbol "$1))
(define-emit    (GLOBAL LABEL)          (println "	.globl "$1))

(define-emit    (ALIGN long)            (println "	.align " $1))

(define-emit    (LONG long)             (println "	.long	"$1))
(define-emit    (LONG LABEL)            (println "	.long	"$1))

(define-emit    (ASCIZ string)          (print   "	.asciz ") (dumpln $1))

(define-emit    (DEFLABEL LABEL)        (println $1":"))

;; ENTER is slow, so don't use it (LEAVE is fine): http://agner.org/optimize
(define-emit    (ENTER long)            (println "	pushl	%ebp")
                                        (println "	movl	%esp, %ebp")
                                        (println "	subl	$"$1", %esp"))

(define-emit    (LEAVE long)            (println "	leave")
                                        (println "	ret"))

(define-emit    (NEG)                   (println "	negl	%eax"))

(define-emit    (ADD TI32)              (println "	addl	"$1", %eax"))

(define-emit    (SUB TI32)              (println "	subl	"$1", %eax"))

(define-emit    (MUL TI32)              (println "	mull	"$1))

(define-emit    (DIV TI32)              (println "	movl	$0, %edx")
                                        (println "	divl	"$1))

(define-emit    (AND TI32)              (println "	andl	"$1", %eax"))

(define-emit    (OR TI32)               (println "	orl	"$1", %eax"))

(define-emit    (XOR TI32)              (println "	xorl	"$1", %eax"))

(define-emit    (NOT)                   (println "	cmpl	$0, %eax")
                                        (println "	sete	%al")
                                        (println "	movzbl	%al, %eax"))

(define-emit    (LT TI32)               (println "	cmpl	"$1", %eax")
                                        (println "	setl	%al")
                                        (println "	movzbl	%al, %eax"))

(define-emit    (LE TI32)               (println "	cmpl	"$1", %eax")
                                        (println "	setle	%al")
                                        (println "	movzbl	%al, %eax"))

(define-emit    (EQ TI32)               (println "	cmpl	"$1", %eax")
                                        (println "	sete	%al")
                                        (println "	movzbl	%al, %eax"))

(define-emit    (NE TI32)               (println "	cmpl	"$1", %eax")
                                        (println "	setne	%al")
                                        (println "	movzbl	%al, %eax"))

(define-emit    (GT TI32)               (println "	cmpl	"$1", %eax")
                                        (println "	setg	%al")
                                        (println "	movzbl	%al, %eax"))

(define-emit    (SHL TI32)              (println "	movl	"$1", %ecx")
                                        (println "	shll	%cl, %eax"))

(define-emit    (SHR TI32)              (println "	movl	"$1", %ecx")
                                        (println "	shrl	%cl, %eax"))

(define-emit    (BR LABEL)              (println "	jmp	"$1))

(define-emit    (BF LABEL)              (println "	cmpl	$0, %eax")
                                        (println "	je	"$1))

(define-emit    (BT LABEL)              (println "	cmpl	$0, %eax")
                                        (println "	jne	"$1))

(define-emit    (CALL LABEL)            (println "	call	"$1))
(define-emit    (CALL long)             (println "	call	*%eax"))

(define-emit    (LOAD LI32)             (println "	movl	$"$1", %eax"))
(define-emit    (LOAD LABEL)            (println "	movl	$"$1", %eax"))
(define-emit    (LOAD GI32)             (println "	movl	" $1", %eax"))
(define-emit    (LOAD TI32)             (println "	movl	" $1", %eax"))

(define-emit    (STORE TI32)            (println "	movl	%eax, "$1))
(define-emit    (STORE GI32)            (println "	movl	%eax, "$1))

(define-emit    (ADDR GI32)             (println "	movl	$"$1", %eax"))
(define-emit    (ADDR TI32)             (println "	leal	"$1", %eax"))

(define-emit    (MOVE TI32 TI32)        (println "	movl	"$1", %ecx")
                                        (println "	movl	%ecx, "$2))

(define-emit    (COMMENT pair)          (print "## ") (apply println $1))

(define-emit    (CHR-AT TI32)           (println "	movl	"$1", %ecx")
                                        (println "	leal	(%eax, %ecx), %ecx")
                                        (println "	xorl	%eax, %eax")
                                        (println "	movb	(%ecx), %al"))

(define-emit    (SET-CHR-AT TI32 TI32)  (println "	movl	"$1", %ecx")
                                        (println "	leal	(%eax, %ecx), %ecx")
                                        (println "	movl	"$2", %eax")
                                        (println "	movb	%al, (%ecx)"))

(define-emit    (OOP-AT TI32)           (println "	movl	"$1", %ecx")
                                        (println "	leal	(%eax, %ecx, 4), %ecx")
                                        (println "	movl	(%ecx), %eax"))

(define-emit    (SET-OOP-AT TI32 TI32)  (println "	movl	"$1", %ecx")
                                        (println "	leal	(%eax, %ecx, 4), %ecx")
                                        (println "	movl	"$2", %eax")
                                        (println "	movl	%eax, (%ecx)"))

;;;

(define-structure <compiler> (env param-counter arg-counter arg-limit tmp-counter tmp-limit temps epilogue asm pc section))

(define-function compiler (env)
  (let ((self (new <compiler>)))
    (set (<compiler>-env self) env)
    (set (<compiler>-param-counter self) 0)
    (set (<compiler>-arg-counter self) 0)
    (set (<compiler>-arg-limit self) 0)
    (set (<compiler>-tmp-counter self) 0)
    (set (<compiler>-tmp-limit self) 0)
    (set (<compiler>-asm self) (array))
    (set (<compiler>-pc self) 0)
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
  (set-array-at (<compiler>-asm self) (<compiler>-pc self) args)
  (set (<compiler>-pc self) (+ 1 (<compiler>-pc self))))

(define-method gen <undefined>  (comp)  (gen comp LOAD (LI32 0)))
(define-method gen <long>       (comp)  (gen comp LOAD (LI32 self)))

(define-method gen <symbol> (comp)
  (let ((value (cdr (assq self (<compiler>-env comp)))))
    (or value (error "gen: undefined variable: " self))
    (cond
      ((temp? value)   (gen comp LOAD value))
      ((extern? value) (gen comp LOAD (GI32 (LABEL (extern->label value)))))
      (else            (gen comp LOAD (GI32 (LABEL self)))))))

(define-method gen <string> (comp)
  (let ((label (LABEL (temp-label-name))))
    (gen comp DATA)
    (gen comp DEFLABEL label)
    (gen comp ASCIZ self)
    (gen comp TEXT)
    (gen comp LOAD label)))

(define-function gen-tmp-prog (prog comp)
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

(define operators (list->array
  `(()                                                          ; nullary
    ((,-  ,NEG) (,not ,NOT))                                    ; unary
    ((,+  ,ADD) (,-   ,SUB) (,* ,MUL) (,/ ,DIV)                 ; binary
     (,&  ,AND) (,|   ,OR ) (,^ ,XOR)
     (,<  ,LT ) (,<=  ,LE)  (,= ,EQ ) (,!= ,NE ) (,> ,GT )
     (,<< ,SHL) (,>>  ,SHR)
     (,oop-at         ,OOP-AT) (,string-at         ,CHR-AT))
    ((,set-oop-at ,SET-OOP-AT) (,set-string-at ,SET-CHR-AT))    ; ternary
    )))

(define-function gen-let-binding (binding comp)
  (let ((name (car binding))
        (temp (gen-tmp-prog (cdr binding) comp)))
    ;x;(print "COMPILER ENV " (<compiler>-env comp))
    (set (<compiler>-env comp) (cons (cons name temp) (<compiler>-env comp)))
    ;x;(println " -> " (<compiler>-env comp))
    temp))

(define-function gen-let (expr comp)
  (let ((outer (<compiler>-env comp))
        (temps (map-with gen-let-binding (cadr expr) comp)))
    (list-do stmt (cddr expr) (gen stmt comp))
    (list-do temp temps (free-temp comp temp))
    (set (<compiler>-env comp) outer)))

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
    (list-do stmt (cddr expr) (gen stmt comp))
    (gen comp DEFLABEL test)
    (gen (cadr expr) comp)
    (gen comp BT body)))

(define-function gen-set (expr comp)
  (let ((name (cadr  expr))
        (valu (caddr expr)))
    (gen valu comp)
    (let ((var (cdr (assq name (<compiler>-env comp)))))
      (or var (error "set: undefined variable: " name))
      (cond
        ((temp? var)   (gen comp STORE var))
        ((extern? var) (gen comp STORE (GI32 (LABEL (extern->label var)))))
        (else          (gen comp STORE (GI32 (LABEL name))))))))

(define-function gen-lambda (expr comp)
  (error "gen: lambda forms are not supported"))

(define-function gen-return (expr comp)
  (list-do stmt (cdr expr) (gen stmt comp))
  (gen comp BR (or (<compiler>-epilogue comp) (set (<compiler>-epilogue comp) (LABEL (temp-label-name))))))

(define-function gen-address-of (expr comp)
  (let ((name (cadr expr)))
    (or (symbol? name) (error "address-of: non-identifier argument: "name))
    (let ((var (cdr (assq name (<compiler>-env comp)))))
      (if (temp? var)
          (gen comp ADDR var)
        (gen comp ADDR (GI32 (LABEL name)))))))

(define forms (list
  (cons  let            gen-let)
  (cons  and            gen-and)
  (cons  or             gen-or)
  (cons  if             gen-if)
  (cons  while          gen-while)
  (cons  set            gen-set)
  (cons  lambda         gen-lambda)
  (cons 'return         gen-return)
  (cons 'address-of     gen-address-of)))

(define-method gen <pair> (comp)
  (let* ((fn-name (car self))
         (args    (cdr self))
         (arity   (list-length args))
         (op      (cadr (assq fn-name (array-at operators arity)))))
    (if op
        ((array-at generators arity) op args comp)
      (if (set op (cdr (assq fn-name forms)))
          (op self comp)
        (let* ((tmp-locs (map-with gen-tmp args comp))
               (arg-locs (map-with gen-arg args comp))
               (op       (cdr (assq fn-name (<compiler>-env comp))))
               (op-type  (type-of op)))
          (if (= <expr> op-type)
              (let* ((defn   (<expr>-defn op))
                     (params (car defn)))
              ;; TODO this is broken, at least for dotted lists
              (when (pair? params) ; ignore (lambda args ...) format, e.g. println
                (let ((nparam (list-length params)))
                  (or (= nparam arity)
                      (error "gen: calling " op
                             " with the wrong number of arguments: " args
                             ", expecting " nparam))))))
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

(define-method gen-definition <string> (name comp)
  (let ((temp (LABEL (temp-label-name))))
    (gen comp DATA)
    (gen comp DEFLABEL temp)
    (gen comp ASCIZ self)
    (gen comp ALIGN 4)
    (gen comp DEFLABEL (LABEL name))
    (gen comp LONG temp)
    (gen comp TEXT)))

(define-method gen-definition <extern> (name comp)
  (let ((extern-label (LABEL (<extern>-name self)))
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

(define-function gen-param (name comp)
  (let ((param (new-param comp)))
    (set (<compiler>-env comp) (cons (cons name param) (<compiler>-env comp)))
    param))

(define-method gen-definition <form> (name comp)
  (gen comp COMMENT (list "form "name)))

(define-method gen-definition <expr> (name ocomp)
  (let* ((main? (= 'main name))
         (defn (<expr>-defn self))
         (body (cdr defn))
         (comp (compiler (<compiler>-env ocomp)))
         (entry-label (LABEL (concat-string (symbol->string name) (if main? "" "_body"))))
         (params (map-with gen-param (car defn) comp)))
    (list-do e body (gen e comp))
    (let* ((arg-size (align 16             (<compiler>-arg-limit comp) ))
           (tmp-size (align 16 (+ arg-size (<compiler>-tmp-limit comp))))
           (frm-size (align 16 (+ 8 tmp-size))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp)))) (<compiler>-temps comp))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ frm-size (<TI32>-offset tmp)))) params)
      (emit TEXT)
      (when main?
        (emit GLOBAL entry-label))
      (emit DEFLABEL entry-label)
      (emit COMMENT (list "frame "arg-size" "(<compiler>-tmp-limit comp)" "tmp-size" "frm-size))
      (emit ENTER (- frm-size 8))
      (for (i 0 (<compiler>-pc comp))
        (apply emit (array-at (<compiler>-asm comp) i)))
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

(define-function gen-env-to (env limit)
  (let ((comp (compiler env)))
    (while (not (= (caar env) limit))
      (println "## defn " (caar env))
      (warn (caar env) "\n")
      ;x;(println (<expr>-defn (cdar env)))
      (gen-definition (cdar env) (caar env) comp)
      (set env (cdr env)))
    (for (i 0 (<compiler>-pc comp)) (apply emit (array-at (<compiler>-asm comp) i)))))

(define-form compile-begin () `(define compile-environment-marker ()))

(define-function compile-end ()
  (gen-env-to (cdr (<module>-env (current-module))) 'compile-environment-marker))