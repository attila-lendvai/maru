#!./eval

(define-function array-append (array element)
  (set-array-at array (array-length array) element))

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

;;; EXTERN

(define-structure <extern> (name stub))

(define-function extern (name)
  (let ((self (new <extern>)))
    (set (<extern>-name self) name)
    self))

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

;;; IA32 -- INSTRUCTIONS

(define-instruction PROG)	(define-emit (PROG pair)
				  (while $1
				    (apply emit (car $1))
				    (set $1 (cdr $1))))

(define-instruction GLOBAL)	(define-emit (GLOBAL LABEL)	(println "	.globl "$1))
(define-instruction SECTION)	(define-emit (SECTION string)	(println "	.section "$1))
(define-instruction INDIRECT)	(define-emit (INDIRECT LABEL)	(println "	.indirect_symbol "$1))
(define-instruction DATA)	(define-emit (DATA)		(println "	.data"))
(define-instruction ASCIZ)	(define-emit (ASCIZ string)	(print   "	.asciz ") (dumpln $1))
(define-instruction LONG)	(define-emit (LONG long)	(println "	.long "$1))
(define-instruction TEXT)	(define-emit (TEXT)		(println "	.text"))
(define-instruction DEFLABEL)	(define-emit (DEFLABEL LABEL)	(println $1":"))

(define-instruction ENTER)	(define-emit (ENTER long)
				  (let ((frame-size (& -32 (+ $1 39))))
				    (println "	pushl %ebp")
				    (println "	movl %esp,%ebp")
				    (println "	subl $"(- frame-size 8)",%esp")))

(define-instruction RETURN)	(define-emit (RETURN long)
				  (let ((frame-size (& -32 (+ $1 39))))
				    (println "	addl $"(- frame-size 8)",%esp")
				    (println "	leave")
				    (println "	ret")))

(define-instruction MOVEA)	(define-emit (MOVEA LABEL TI32)	(println "	movl $"$1","$2))

(define-instruction ADD)	(define-emit (ADD TI32)		(println "	addl "$1",%eax"))

(define-instruction CALL)	(define-emit (CALL LABEL)	(println "	call "$1))
				(define-emit (CALL long)	(println "	call *%eax"))

(define-instruction LOAD)	(define-emit (LOAD LI32)	(println "	movl $"$1",%eax"))
				(define-emit (LOAD LABEL)	(println "	movl $"$1",%eax"))
				(define-emit (LOAD GI32)	(println "	movl " $1",%eax"))

(define-instruction STORE)	(define-emit (STORE TI32)	(println "	movl %eax,"$1))

(define-instruction MOVE)	(define-emit (MOVE TI32 TI32)	(println "	movl "$1",%ecx")
								(println "	movl %ecx,"$2))

;;; 

(define-function emit-main (body)
  (let ((main   (LABEL "main")))
    (emit GLOBAL main)
    (emit DEFLABEL main)
    (emit ENTER	24)
    (array-do insn body (apply emit insn))
    (emit RETURN 24)))

;;; 

(define-structure <compiler> (arg-counter arg-limit temp-counter temps stubs asm))

(define-function compiler ()
  (let ((self (new <compiler>)))
    (set (<compiler>-arg-counter self) 0)
    (set (<compiler>-arg-limit self) 0)
    (set (<compiler>-temp-counter self) 0)
    (set (<compiler>-asm self) (array))
    self))

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
  (TI32 (post-incr (<compiler>-temp-counter comp) 4)))

(define-function alloc-temp (comp)
  (or (pop (<compiler>-temps comp))
      (new-temp comp)))

(define-function free-temp (comp temp)
  (push (<compiler>-temps comp) temp))

(define-function free-temps (comp temps)
  (list-do temp temps (free-temp comp temp)))

(define-selector gen)

(define-method gen <symbol> (comp)	(gen comp LOAD (LABEL self)))
(define-method gen <long>   (comp)	(gen comp LOAD (LI32 self)))

(define-function new-stub (comp name)
  (let ((nlabel (LABEL                name        ))
	(slabel (LABEL (concat-symbol name '$stub))))
    (gen comp SECTION "__IMPORT,__pointers,non_lazy_symbol_pointers")
    (gen comp DEFLABEL slabel)
    (gen comp INDIRECT nlabel)
    (gen comp LONG 0)
    (gen comp TEXT)
    (GI32 slabel)))

(define-method gen <extern> (comp)
  (let ((stub (or (<extern>-stub self)
		  (set (<extern>-stub self)
		       (new-stub comp (<extern>-name self))))))
    (gen comp LOAD stub)))

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

(define operators	(list->array (list () () (list (cons '+ ADD)))))
(define generators	(list->array (list generate-nullary generate-unary generate-binary)))

(define-method gen <pair> (comp)
  (let* ((head  (car self))
	 (arity (- (list-length self) 1))
	 (op    (cdr (assq head (array-at operators arity)))))
    (if op
	((array-at generators arity) op (cdr self) comp)
      (let ((tmps (map-with gen-tmp (cdr self) comp))
	    (args (map-with gen-arg (cdr self) comp))
	    (func (gen (car self) comp))
	    (narg (list-length args)))
	(map2-with gen-move tmps args comp)
	(free-temps comp tmps)
	(free-args  comp args)
	(gen comp CALL narg)))
    ))
  
(define-function gen-main (expr)
  (let* ((comp (compiler)))
    (gen expr comp)
    (let ((arg-size (& -16 (+ 15 (<compiler>-arg-limit comp)))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp))))
	   (<compiler>-temps comp)))
    (emit-main (<compiler>-asm comp))))

(gen-main (list (extern 'printf) "%d\n" '(+ 3 4)))

; (EAX ADD (LI32:3 LOAD LI32:3) (LI32:3 LOAD LI32:4))
