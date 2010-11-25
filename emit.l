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
    (concat-string "L" (long->string (set counter (+ counter 1))))))

(define-operand LABEL (name) "_"(<LABEL>-name self))
(define-operand GI32 (name)	(<GI32>-name self))
(define-operand LI32 (value)	(<LI32>-value self))
(define-operand TI32 (offset)	(<TI32>-offset self)"(%esp)")

;;; IA32 -- INSTRUCTIONS

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

(define-instruction CALL)	(define-emit (CALL LABEL)	(println "	call "$1))

;;; 

(define-function emit-program (program)
  (while program
    (apply emit (car program))
    (set program (cdr program))))

(let ((hw     (LABEL (temp-label-name)))
      (main   (LABEL "main"))
      (printf (LABEL "printf")))
  (emit-program
   `((,DATA)
     (,DEFLABEL ,hw)
     (,ASCIZ	"hello, world\n")
     (,TEXT)
     (,GLOBAL ,main)
     (,DEFLABEL ,main)
     (,ENTER	4)
     (,MOVEA	,hw ,(TI32 0))
     (,CALL	,printf)
     (,RETURN	4))))
