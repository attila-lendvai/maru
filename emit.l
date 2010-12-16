#!./eval

(define __MACH__ 't)

(define __PREFIX__ (if __MACH__ "_" ""))

(define-function array-append (array element)
  (set-array-at array (array-length array) element))

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

(define-function align (alignment value)	(& (- alignment) (+ (- alignment 1) value )))

;;; EXTERN

(define-structure <extern> (name stub))

(define-function extern (name)
  (let ((self (new <extern>)))
    (set (<extern>-name self) name)
    self))

(define-function extern? (obj) (= <extern> (type-of obj)))

;;; DEFINE-OPERAND

(define-function define-operand-make-setters (tname fields)
  (if (pair? fields)
      (cons `(set (,(concat-symbol (concat-symbol tname '-) (car fields)) self) ,(car fields))
	    (define-operand-make-setters tname (cdr fields)))))

(define-form define-operand (name fields . printing)
  (let* ((sname (symbol->string name))
	 (tname (string->symbol (concat-string "<" (concat-string sname ">")))))
    (eval `(define-structure ,tname ,fields))
    (eval `(define-function ,name ,fields
	     (let ((self (new ,tname)))
	       ,@(define-operand-make-setters tname fields)
	       self)))
    `(define-method do-print ,tname () (print ,@printing))))

;;; DEFINE-INSTRUCTION

(define-form define-instruction (name)
  (let* ((sname (symbol->string name))
	 (tname (string->symbol (concat-string "<" (concat-string sname ">")))))
    `(let ()
       (define-structure ,tname ())
       (define-method do-print ,tname () (print ,sname))
       (define ,name (new ,tname)))))

;;; DEFINE-EMIT

(define-generic emit op-args
  (print "\nemit: illegal instruction: "op-args)
  (error "aborted"))

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
  (let* ((sname (symbol->string (car op-args)))
	 (tname (string->type-name sname)))
    `(define-multimethod emit ((,tname op) ,@(%define-emit-params 1 (cdr op-args))) ,@body)))

(define-function digit-for (c)
  (if (< c 10)
      (+ c 0x30)
    (+ c 0x37)))

(define-function mangle-label (name)
  (let* ((plain  (symbol->string name))
	 (mangled (array))
	 (index   0)
	 (size    (string-length plain)))
    (while (< index size)
      (let ((c (string-at plain index)))
	(cond
	  ((or (and (<= 0x61 c) (<= c 0x7a))
	       (and (<= 0x41 c) (<= c 0x5a))
	       (and (<= 0x30 c) (<= c 0x39)))	(array-append mangled c))
	  ((= ?_ c)				(let ()
						  (array-append mangled c)
						  (array-append mangled c)))
	  (else					(let ()
						  (array-append mangled 0x5f)
						  (array-append mangled (digit-for (>> c  4)))
						  (array-append mangled (digit-for (&  c 15)))))))
      (set index (+ 1 index)))
    (array->string mangled)))
      
;;; IA32 -- OPERANDS

(let ((counter 0))
  (define-function temp-label-name ()
    (concat-string "_L_" (long->string (set counter (+ counter 1))))))

(define-operand LABEL (name) 	__PREFIX__(mangle-label (<LABEL>-name self)))
(define-operand GI32 (name)	(<GI32>-name self))
(define-operand LI32 (value)	(<LI32>-value self))
(define-operand TI32 (offset)	(<TI32>-offset self)"(%esp)")

(define-function temp? (obj)	(= <TI32> (type-of obj)))

;;; IA32 -- INSTRUCTIONS

(define-instruction GLOBAL)	(define-emit (GLOBAL LABEL)	(println "	.globl "$1))
(define-instruction SECTION)	(define-emit (SECTION string)	(println "	.section "$1))
(define-instruction INDIRECT)	(define-emit (INDIRECT LABEL)	(println "	.indirect_symbol "$1))
(define-instruction DATA)	(define-emit (DATA)		(println "	.data"))
(define-instruction ALIGN)	(define-emit (ALIGN long)	(println "	.align " $1))
(define-instruction ASCIZ)	(define-emit (ASCIZ string)	(print   "	.asciz ") (dumpln $1))
(define-instruction LONG)	(define-emit (LONG long)	(println "	.long "$1))
				(define-emit (LONG LABEL)	(println "	.long "$1))
(define-instruction TEXT)	(define-emit (TEXT)		(println "	.text"))
(define-instruction DEFLABEL)	(define-emit (DEFLABEL LABEL)	(println $1":"))

(define-instruction ENTER)	(define-emit (ENTER long)
				  (println "	pushl %ebp")
				  (println "	movl %esp,%ebp")
				  (println "	subl $"$1",%esp"))

(define-instruction LEAVE)	(define-emit (LEAVE long)
				  (println "	addl $"$1",%esp")
				  (println "	leave")
				  (println "	ret"))

(define-instruction ADD)	(define-emit (ADD TI32)		(println "	addl "$1",%eax"))

(define-instruction SUB)	(define-emit (SUB TI32)		(println "	subl "$1",%eax"))

(define-instruction MUL)	(define-emit (MUL TI32)		(println "	mull "$1))

(define-instruction AND)	(define-emit (AND TI32)		(println "	andl "$1",%eax"))

(define-instruction OR)		(define-emit (OR TI32)		(println "	orl "$1",%eax"))

(define-instruction NOT)	(define-emit (NOT)		(println "	cmpl $0,%eax")
								(println "	sete %al")
								(println "	movzbl %al,%eax"))

(define-instruction LESS)	(define-emit (LESS TI32)	(println "	cmpl "$1",%eax")
								(println "	setl %al")
								(println "	movzbl %al,%eax"))

(define-instruction LESSEQ)	(define-emit (LESSEQ TI32)	(println "	cmpl "$1",%eax")
								(println "	setle %al")
								(println "	movzbl %al,%eax"))

(define-instruction EQUAL)	(define-emit (EQUAL TI32)	(println "	cmpl "$1",%eax")
								(println "	sete %al")
								(println "	movzbl %al,%eax"))

(define-instruction NOTEQ)	(define-emit (NOTEQ TI32)	(println "	cmpl "$1",%eax")
								(println "	setne %al")
								(println "	movzbl %al,%eax"))

(define-instruction GREATER)	(define-emit (GREATER TI32)	(println "	cmpl "$1",%eax")
								(println "	setg %al")
								(println "	movzbl %al,%eax"))

(define-instruction SHL)	(define-emit (SHL TI32)		(println "	movl "$1",%ecx")
								(println "	shll %cl,%eax"))

(define-instruction SHR)	(define-emit (SHR TI32)		(println "	movl "$1",%ecx")
								(println "	shrl %cl,%eax"))

(define-instruction BR)		(define-emit (BR LABEL)		(println "	jmp "$1))

(define-instruction BF)		(define-emit (BF LABEL)		(println "	cmpl $0,%eax")
								(println "	je "$1))

(define-instruction BT)		(define-emit (BT LABEL)		(println "	cmpl $0,%eax")
								(println "	jne "$1))

(define-instruction CALL)	(define-emit (CALL LABEL)	(println "	call "$1))
				(define-emit (CALL long)	(println "	call *%eax"))

(define-instruction LOAD)	(define-emit (LOAD LI32)	(println "	movl $"$1",%eax"))
				(define-emit (LOAD LABEL)	(println "	movl $"$1",%eax"))
				(define-emit (LOAD GI32)	(println "	movl " $1",%eax"))
				(define-emit (LOAD TI32)	(println "	movl " $1",%eax"))

(define-instruction STORE)	(define-emit (STORE TI32)	(println "	movl %eax,"$1))
				(define-emit (STORE GI32)	(println "	movl %eax,"$1))

(define-instruction ADDR)	(define-emit (ADDR GI32)	(println "	movl $"$1",%eax"))
				(define-emit (ADDR TI32)	(println "	leal "$1",%eax"))

(define-instruction MOVE)	(define-emit (MOVE TI32 TI32)	(println "	movl "$1",%ecx")
								(println "	movl %ecx,"$2))

(define-instruction COMMENT)	(define-emit (COMMENT pair)	(print "## ") (apply println $1))

(define-instruction CHR-AT)	(define-emit (CHR-AT TI32)	(println "	movl "$1",%ecx")
								(println "	leal (%eax,%ecx),%ecx")
								(println "	xorl %eax,%eax")
								(println "	movb (%ecx),%al"))

(define-instruction SET-CHR-AT)	(define-emit (SET-CHR-AT TI32 TI32)	(println "	movl "$1",%ecx")
									(println "	leal (%eax,%ecx),%ecx")
									(println "	movl "$2",%eax")
									(println "	movb %al,(%ecx)"))

(define-instruction OOP-AT)	(define-emit (OOP-AT TI32)	(println "	movl "$1",%ecx")
								(println "	leal (%eax,%ecx,4),%ecx")
								(println "	movl (%ecx),%eax"))

(define-instruction SET-OOP-AT)	(define-emit (SET-OOP-AT TI32 TI32)	(println "	movl "$1",%ecx")
									(println "	leal (%eax,%ecx,4),%ecx")
									(println "	movl "$2",%eax")
									(println "	movl %eax,(%ecx)"))

;;; 

(define-structure <compiler> (env param-counter arg-counter arg-limit tmp-counter tmp-limit temps epilogue asm))

(define-function compiler (env)
  (let ((self (new <compiler>)))
    (set (<compiler>-env self) env)
    (set (<compiler>-param-counter self) 0)
    (set (<compiler>-arg-counter self) 0)
    (set (<compiler>-arg-limit self) 0)
    (set (<compiler>-tmp-counter self) 0)
    (set (<compiler>-tmp-limit self) 0)
    (set (<compiler>-asm self) (array))
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

(define-function free-temp (comp temp)
  (push (<compiler>-temps comp) temp))

(define-function free-temps (comp temps)
  (list-do temp temps (free-temp comp temp)))

;;; GEN

(define-selector gen)

(define-method gen <undefined> (comp)
  (gen comp LOAD (LI32 0)))

(define-method gen <symbol> (comp)
  (let ((value (cdr (assq self (<compiler>-env comp)))))
    (or value (error "gen: undefined variable: " self))
    (if (extern? value)
	(gen comp LOAD (GI32 (LABEL (concat-symbol self '$stub))))
      (if (temp? value)
	  (gen comp LOAD value)
	(gen comp LOAD (GI32 (LABEL self)))))))

(define-method gen <long>   (comp)	(gen comp LOAD (LI32 self)))

(define-method gen <string> (comp)
  (let ((label (LABEL (temp-label-name))))
    (gen comp DATA)
    (gen comp DEFLABEL label)
    (gen comp ASCIZ self)
    (gen comp TEXT)
    (gen comp LOAD label)))

(define-method gen <compiler> args
  ;;(println "## insn " args)
  (array-append (<compiler>-asm self) args))

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
  (error "no generate-nullary implementation"))

(define-function generate-unary (op args comp)
  (gen (car args) comp)
  (gen comp op))

(define-function generate-binary (op args comp)
  (let ((tmp (gen-tmp (cadr args) comp)))
    (gen (car  args) comp)
    (free-temp comp tmp)
    (gen comp op tmp)))

(define-function generate-tertiary (op args comp)
  (let ((tmp2 (gen-tmp (caddr args) comp))
	(tmp1 (gen-tmp (cadr  args) comp)))
    (gen (car  args) comp)
    (free-temp comp tmp1)
    (free-temp comp tmp2)
    (gen comp op tmp1 tmp2)))

(define generators (list->array (list generate-nullary generate-unary generate-binary generate-tertiary)))

(define operators
  (list->array
   `(()
     ((,not ,NOT))
     ((,+ ,ADD) (,- ,SUB) (,* ,MUL)
      (,& ,AND) (,| ,OR)
      (,< ,LESS) (,<= ,LESSEQ) (,= ,EQUAL) (,!= ,NOTEQ) (,> ,GREATER)
      (,<< ,SHL) (,>> ,SHR)
      (,oop-at ,OOP-AT) (char-at ,CHR-AT))
     ((,set-oop-at ,SET-OOP-AT) (set-char-at ,SET-CHR-AT))
     )))

;; (define-function gen-lambda (expr ocomp)
;;   (let ((args (cadr expr))
;; 	(body (cddr expr))
;; 	(comp (compiler (<compiler>-env ocomp)))
;; 	(name (LABEL (temp-label-name))))
;;     (list-do e body (cddr expr) (gen e comp))
;;     (let* ((arg-size (align 16             (<compiler>-arg-limit comp) ))
;; 	   (tmp-size (align 16 (+ arg-size (<compiler>-tmp-limit comp)))))
;;       (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp))))
;; 	   (<compiler>-temps comp))
;;       (emit TEXT)
;;       (emit GLOBAL name)
;;       (emit DEFLABEL name)
;;       (emit COMMENT (list arg-size" "(<compiler>-tmp-limit comp)" "tmp-size))
;;       (emit ENTER tmp-size)
;;       (array-do insn (<compiler>-asm comp) (apply emit insn))
;;       (emit LEAVE tmp-size))
;;     (gen ocomp LOAD (LI32 name))))

(define-function gen-let-binding (binding comp)
  (let ((name (car binding))
	(temp (gen-tmp-prog (cdr binding) comp)))
    (set (<compiler>-env comp) (cons (cons name temp) (<compiler>-env comp)))
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
      (or var (error "set: undefined variable: "name))
      (if (temp? var)
	  (gen comp STORE var)
	(gen comp STORE (GI32 (LABEL name)))))))

(define-function gen-return (expr comp)
  (list-do stmt (cdr expr) (gen stmt comp))
  (gen comp BR (or (<compiler>-epilogue comp) (set (<compiler>-epilogue comp) (LABEL (temp-label-name))))))

(define-function gen-quote  (expr comp)	(error "quoted object in compiled code: " expr))
(define-function gen-define (expr comp)	(error "definition in compiled code: " expr))
(define-function gen-lambda (expr comp)	(error "unevaluated lambda in compiled code: " expr))

(define-function gen-address-of (expr comp)
  (let ((name (cadr expr)))
    (or (symbol? name) (error "address-of: non-identifier argument: "name))
    (let ((var (cdr (assq name (<compiler>-env comp)))))
      (if (temp? var)
	  (gen comp ADDR var)
	(gen comp ADDR (GI32 (LABEL name)))))))

(define forms
  (list
   (cons  let		gen-let)
   (cons  and	 	gen-and)
   (cons  or	 	gen-or)
   (cons  if	 	gen-if)
   (cons  while	 	gen-while)
   (cons  set	 	gen-set)
   (cons 'return 	gen-return)
   (cons  quote	 	gen-quote)
   (cons  define 	gen-define)
   (cons 'lambda 	gen-lambda)
   (cons 'address-of	gen-address-of)
   ))

(define-method gen <pair> (comp)
  ;;(println "GEN "self)
  (let* ((head  (car self))
	 (arity (- (list-length self) 1))
	 (op    (cadr (assq head (array-at operators arity)))))
    (if op
	((array-at generators arity) op (cdr self) comp)
      (set op (cdr (assq head forms)))
      (if op
	  (op self comp)
	(let ((tmps (map-with gen-tmp (cdr self) comp))
	      (args (map-with gen-arg (cdr self) comp))
	      (func (gen (car self) comp))
	      (narg (list-length args)))
	  (map2-with gen-move tmps args comp)
	  (free-temps comp tmps)
	  (free-args  comp args)
	  (gen comp CALL narg)))
      )))

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
  (let ((nlabel (LABEL                name        ))
	(slabel (LABEL (concat-symbol name '$stub))))
    (if __MACH__
	(let ()
	  (gen comp SECTION "__IMPORT,__pointers,non_lazy_symbol_pointers")
	  (gen comp DEFLABEL slabel)
	  (gen comp INDIRECT nlabel)
	  (gen comp LONG 0)
	  (gen comp TEXT))
      (gen comp DATA)
      (gen comp DEFLABEL slabel)
      (gen comp LONG nlabel)
      (gen comp TEXT))))

(define-function gen-param (name comp)
  (let ((param (new-param comp)))
    (set (<compiler>-env comp) (cons (cons name param) (<compiler>-env comp)))
    param))

(define-method gen-definition <form> (name comp)
  (gen comp COMMENT (list "form "name)))

(define-method gen-definition <expr> (name ocomp)
  (let* ((main (= 'main name))
	 (defn (<expr>-defn self))
	 (body (cdr defn))
	 (comp (compiler (<compiler>-env ocomp)))
	 (tnam (if main (LABEL name) (LABEL (temp-label-name))))
	 (vnam (if main ()           (LABEL name)))
	 (params (map-with gen-param (car defn) comp)))
    (list-do e body (gen e comp))
    (let* ((arg-size (align 16             (<compiler>-arg-limit comp) ))
	   (tmp-size (align 16 (+ arg-size (<compiler>-tmp-limit comp))))
	   (frm-size (align 16 (+ 8 tmp-size))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp)))) (<compiler>-temps comp))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ frm-size (<TI32>-offset tmp)))) params)
      (emit TEXT)
      (and main (emit GLOBAL tnam))
      (emit DEFLABEL tnam)
      (emit COMMENT (list "frame "arg-size" "(<compiler>-tmp-limit comp)" "tmp-size" "frm-size))
      (emit ENTER (- frm-size 8))
      (array-do insn (<compiler>-asm comp) (apply emit insn))
      (and (<compiler>-epilogue comp)
	   (emit DEFLABEL (<compiler>-epilogue comp)))
      (emit LEAVE (- frm-size 8)))
    (or main
      (let ()
	(gen ocomp DATA)
	(gen ocomp GLOBAL vnam)
	(gen ocomp DEFLABEL vnam)
	(gen ocomp LONG tnam)
	(gen ocomp TEXT)))))

;;; 

(define-function gen-env-to (env limit)
  (let ((comp (compiler env)))
    (while (not (= (caar env) limit))
      (println "## defn " (caar env))
      (gen-definition (cdar env) (caar env) comp)
      (set env (cdr env)))
    (array-do insn (<compiler>-asm comp) (apply emit insn))))

(define-form compile-begin () `(define compile-environment-marker ()))

(define-function compile-end ()
  (gen-env-to (cdr (current-environment)) 'compile-environment-marker))
