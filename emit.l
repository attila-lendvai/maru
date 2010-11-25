(define-function array-append (array element)
  (set-array-at array (array-length array) element))

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

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
  (print "\nemit: illegal instruction: ")
  (map (lambda (arg) (print " " arg)) op-args)
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

(define-operand LABEL (name) "_"(<LABEL>-name self))
(define-operand GI32 (name)	(<GI32>-name self))
(define-operand LI32 (value)	(<LI32>-value self))
(define-operand TI32 (offset)	(<TI32>-offset self)"(%esp)")

;;; IA32 -- INSTRUCTIONS

(define-instruction PROG)	(define-emit (PROG pair)
				  (while $1
				    (apply emit (car $1))
				    (set $1 (cdr $1))))

(define-instruction GLOBAL)	(define-emit (GLOBAL LABEL)	(println "	.globl "$1))

(define-instruction DATA)	(define-emit (DATA)		(println "	.data"))

(define-instruction ASCIZ)	(define-emit (ASCIZ string)
				  (print "	.asciz ")
				  (dumpln $1))

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

(define-instruction LOAD)	(define-emit (LOAD LI32)	(println "	movl $"$1",%eax"))
(define-instruction LOAD)	(define-emit (LOAD LABEL)	(println "	movl $0,%eax"))

(define-instruction STORE)	(define-emit (STORE TI32)	(println "	movl %eax,"$1))

(define-instruction MOVE)	(define-emit (MOVE TI32 TI32)	(println "	movl "$1",%ecx")
								(println "	movl %ecx,"$2))

(define-instruction CALL)	(define-emit (CALL long)	(println "	call _printf"))

;;; 

(define-function emit-program (program)
  (while program
    (apply emit (car program))
    (set program (cdr program))))

(define-function emit-main (body)
  (let ((main   (LABEL "main")))
    (emit-program
     `((,GLOBAL ,main)
       (,DEFLABEL ,main)
       (,ENTER	24)))
    (let ((i 0) (j (array-length body)))
      (while (< i j)
	(apply emit (array-at body i))
	(set i (+ i 1))))
    (emit-program
     `((,RETURN	24)))))

;; (let ((hw     (LABEL (temp-label-name)))
;;       (main   (LABEL "main"))
;;       (printf (LABEL "printf")))
;;   (emit-program
;;    `((,PROG ((,DATA)
;; 	     (,DEFLABEL ,hw)
;; 	     (,ASCIZ	"hello, world\n")
;; 	     (,TEXT)))
;;      (,GLOBAL ,main)
;;      (,DEFLABEL ,main)
;;      (,ENTER	4)
;;      (,MOVEA	,hw ,(TI32 0))
;;      (,CALL	,printf)
;;      (,RETURN	4))))

;;; 

(define-structure <compiler> (arg-counter arg-limit temp-counter temps asm))

(define-function compiler ()
  (let ((self (new <compiler>)))
    (set (<compiler>-arg-counter self) 0)
    (set (<compiler>-arg-limit self) 0)
    (set (<compiler>-temp-counter self) 0)
    (set (<compiler>-temps self) ())
    (set (<compiler>-asm self) (array))
    self))

(define-function new-arg (comp)
  (let* ((i (<compiler>-arg-counter comp))
	 (t (TI32 i)))
    (set (<compiler>-arg-counter comp) (+ i 4))
    t))

(define-function free-args (comp args)
  (set (<compiler>-arg-limit comp) (<compiler>-arg-counter comp))
  (set (<compiler>-arg-counter comp) 0))

(define-function new-temp (comp)
  (let* ((i (<compiler>-temp-counter comp))
	 (t (TI32 i)))
    (set (<compiler>-temp-counter comp) (+ i 4))
    t))

(define-function alloc-temp (comp)
  (let ((temps (<compiler>-temps comp)))
    (if temps
	(let ((temp (car temps)))
	  (set (<compiler>-temps comp) (cdr temps))
	  temp)
      (new-temp comp))))

(define-function free-temp (comp temp)
  (let ((temps (<compiler>-temps comp)))
    (set (<compiler>-temps comp) (cons temp temps))))

(define-function free-temps (comp temps)
  (while temps
    (free-temp comp (car temps))
    (set temps (cdr temps))))

(define-selector gen)

(define-method gen <symbol> (comp)	(gen comp LOAD (LABEL self)))
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

(define-method gen <pair> (comp)
  (let ((op (car self)))
    (cond
     ((= op '+)		(let ((a (gen (caddr self) comp))
			      (t (alloc-temp comp))
			      (b (gen (cadr self) comp)))
			  (free-temp comp t)
			  (list a
				(list STORE t)
				b
				(list ADD t))))
     ('t		(let ((tmps (map-with gen-tmp (cdr self) comp))
			      (args (map-with gen-arg (cdr self) comp))
			      (func (gen (car self) comp))
			      (narg (list-length args)))
			  (map2-with gen-move tmps args comp)
			  (free-temps comp tmps)
			  (free-args  comp args)
			  (gen comp CALL narg)))
     )))

(let* ((comp (compiler)))
  (gen '(printf "hello, world\n") comp)
  (let ((arg-size (& -16 (+ 15 (<compiler>-arg-limit comp)))))
    (map (lambda (tmp) (set (<TI32>-offset tmp) (+ arg-size (<TI32>-offset tmp))))
	 (<compiler>-temps comp)))
  (emit-main (<compiler>-asm comp)))

;(EAX ADD (LI32:3 LOAD LI32:3) (LI32:3 LOAD LI32:4))
