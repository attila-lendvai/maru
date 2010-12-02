#!./eval

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

;;; IA32 -- OPERANDS

(let ((counter 0))
  (define-function temp-label-name ()
    (concat-string "_L_" (long->string (set counter (+ counter 1))))))

(define-operand LABEL (name) 	"_"(<LABEL>-name self))
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

(define-instruction LESS)	(define-emit (LESS TI32)	(println "	cmpl "$1",%eax")
								(println "	setl %al")
								(println "	movzbl %al,%eax"))

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

(define-instruction MOVE)	(define-emit (MOVE TI32 TI32)	(println "	movl "$1",%ecx")
								(println "	movl %ecx,"$2))

(define-instruction COMMENT)	(define-emit (COMMENT pair)	(print "# ") (apply println $1))

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
  (array-append (<compiler>-asm self) args))

(define-function gen-tmp (expr comp)
  (let ((x (gen expr comp))
	(t (alloc-temp comp)))
    (gen comp STORE t)
    t))

(define-function gen-arg (expr comp)
  (new-arg comp))

(define-function gen-move (a b comp)
  (gen comp MOVE a b))

(define-function generate-nullary (op args comp)
  (error "no generate-nullary implementation"))

(define-function generate-unary (op args comp)
  (error "no generate-unary implementation"))

(define-function generate-binary (op args comp)
  (let ((tmp (gen-tmp (cadr args) comp)))
    (gen (car  args) comp)
    (free-temp comp tmp)
    (gen comp op tmp)))

(define operators	(list->array `(() () ((,+ ,ADD) (,- ,SUB) (,< ,LESS)))))
(define generators	(list->array (list generate-nullary generate-unary generate-binary)))

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
	(temp (gen-tmp (cadr binding) comp)))
    (set (<compiler>-env comp) (cons (cons name temp) (<compiler>-env comp)))
    temp))

(define-function gen-let (expr comp)
  (let ((temps (map-with gen-let-binding (cadr expr) comp)))
    (list-do stmt (cddr expr) (gen stmt comp))
    (list-do temp temps (free-temp comp temp))))

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
      (gen comp STORE var))))

(define-function gen-return (expr comp)
  (list-do stmt (cdr expr) (gen stmt comp))
  (gen comp BR (or (<compiler>-epilogue comp) (set (<compiler>-epilogue comp) (LABEL (temp-label-name))))))

(define forms		(list
			  (cons  let gen-let)
			  (cons  if gen-if)
			  (cons  while gen-while)
			  (cons  set gen-set)
			  (cons 'return gen-return)
			 ;(cons 'lambda gen-lambda)
			  ))

(define-method gen <pair> (comp)
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
    (gen comp SECTION "__IMPORT,__pointers,non_lazy_symbol_pointers")
    (gen comp DEFLABEL slabel)
    (gen comp INDIRECT nlabel)
    (gen comp LONG 0)
    (gen comp TEXT)))

(define-function gen-param (name comp)
  (let ((param (new-param comp)))
    (set (<compiler>-env comp) (cons (cons name param) (<compiler>-env comp)))
    param))

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
      (emit COMMENT (list arg-size" "(<compiler>-tmp-limit comp)" "tmp-size" "frm-size))
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
      (gen-definition (cdar env) (caar env) comp)
      (set env (cdr env)))
    (array-do insn (<compiler>-asm comp) (apply emit insn))))

(define-function compile-environment ()
  (gen-env-to (cdr (current-environment)) 'compile-environment))

;;; ----------------------------------------------------------------

(define printf	(extern 'printf))

(define-function fibs (n) (if (< n 2) 1 (+ 1 (+ (fibs (- n 1)) (fibs (- n 2))))))

(define-function main ()
  (for (i 0 10) (printf "%d\n" i))
  (printf "%d %d %d %d %d\n" (if) (if  1) (if  1 2) (if  1 2 3) (if  1 2 3 4))
  (printf "%d %d %d %d %d\n" (if) (if ()) (if () 5) (if () 5 6) (if () 5 6 7))
  (printf "%d\n" (fibs 5)))

(compile-environment)
