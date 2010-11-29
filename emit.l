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

;;; IA32 -- INSTRUCTIONS

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

(define-instruction LEAVE)	(define-emit (LEAVE long)
				  (let ((frame-size (& -32 (+ $1 39))))
				    (println "	addl $"(- frame-size 8)",%esp")
				    (println "	leave")
				    (println "	ret")))

(define-instruction ADD)	(define-emit (ADD TI32)		(println "	addl "$1",%eax"))

(define-instruction CALL)	(define-emit (CALL LABEL)	(println "	call "$1))
				(define-emit (CALL long)	(println "	call *%eax"))

(define-instruction LOAD)	(define-emit (LOAD LI32)	(println "	movl $"$1",%eax"))
				(define-emit (LOAD LABEL)	(println "	movl $"$1",%eax"))
				(define-emit (LOAD GI32)	(println "	movl " $1",%eax"))

(define-instruction STORE)	(define-emit (STORE TI32)	(println "	movl %eax,"$1))

(define-instruction MOVE)	(define-emit (MOVE TI32 TI32)	(println "	movl "$1",%ecx")
								(println "	movl %ecx,"$2))

(define-instruction COMMENT)	(define-emit (COMMENT pair)	(println "# "$1))

;;; 

(define-function emit-main (frame-size body)
  (let ((main   (LABEL "main")))
    (emit TEXT)
    (emit GLOBAL main)
    (emit DEFLABEL main)
    (emit ENTER	frame-size)
    (array-do insn body (apply emit insn))
    (emit COMMENT (list "frame-size "frame-size))
    (emit LEAVE frame-size)))

;;; 

(define-structure <compiler> (env arg-counter arg-limit tmp-counter tmp-limit temps stubs asm))

(define-function compiler (env)
  (let ((self (new <compiler>)))
    (set (<compiler>-env self) env)
    (set (<compiler>-arg-counter self) 0)
    (set (<compiler>-arg-limit self) 0)
    (set (<compiler>-tmp-counter self) 0)
    (set (<compiler>-tmp-limit self) 0)
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

(define-selector gen)

(define-method gen <symbol> (comp)
  (let ((value (cdr (assq self (<compiler>-env comp)))))
    (or value (error "gen: undefined variable: " self))
    (if (extern? value)
	(gen value comp)
      (gen comp LOAD (LABEL self)))))

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

(define operators	(list->array `(() () ((+ ,ADD)))))
(define generators	(list->array (list generate-nullary generate-unary generate-binary)))

(define-function gen-lambda (expr ocomp)
  (let ((args (cadr expr))
	(body (cddr expr))
	(comp (compiler (<compiler>-env ocomp)))
	(name (LABEL (temp-label-name))))
    (list-do e body (cddr expr) (gen e comp))
    (let* ((arg-size (align 16             (<compiler>-arg-limit comp) ))
	   (tmp-size (align 16 (+ arg-size (<compiler>-tmp-limit comp)))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp))))
	   (<compiler>-temps comp))
      (emit TEXT)
      (emit GLOBAL name)
      (emit DEFLABEL name)
      (emit ENTER tmp-size)
      (array-do insn (<compiler>-asm comp) (apply emit insn))
      (emit LEAVE tmp-size))
    (gen ocomp LOAD (LI32 name))))

(define forms		(list (cons 'lambda gen-lambda)))

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

(define-function align (alignment value)	(& (- alignment) (+ (- alignment 1) value )))

(define-function gen-main (env exprs)
  (let ((comp (compiler env)))
    (list-do expr exprs (gen expr comp))
    (let* ((arg-size (align 16             (<compiler>-arg-limit comp) ))
	   (tmp-size (align 16 (+ arg-size (<compiler>-tmp-limit comp)))))
      (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp))))
	   (<compiler>-temps comp))
      (gen comp COMMENT (list "arg-size "arg-size" tmp-size "tmp-size" tmp-limit "(<compiler>-tmp-limit comp)))
      (emit-main tmp-size (<compiler>-asm comp)))))

(define env
  (list
   (cons 'printf (extern 'printf))
   (cons 'main   (lambda () (printf "hello, world\n")))
   ))

;; (gen-env env)
;; 
;; (exit 0)

(gen-main env
 `((printf "hello, world\n")
   (printf "%d\n" (+ 3 4))
   (printf "bye\n")
   (printf "%d\n" 111 ((lambda () 42)) 222)
   ))

; (EAX ADD (LI32:3 LOAD LI32:3) (LI32:3 LOAD LI32:4))
