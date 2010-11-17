;;; literal

(define-structure <literal> (value))

(define-method do-print <literal> ()
  (print "<literal ")
  (dump (<literal>-value self))
  (print ">"))

(define-function literal (value)
  (let ((self (new <literal>)))
    (set (<literal>-value	self) value)
    self))

;;; variable

(define-structure <variable> (location name value level offset next))

(define-method do-print <variable> ()
  (print "["(<variable>-name self))
  (print ":"(<variable>-level self))
  (print "."(<variable>-offset self))
  (print "="(<variable>-location self))
  (print "]"))

(define-function variable (name value level offset next)
  (let ((self (new <variable>)))
    (set (<variable>-name	self) name)
    (set (<variable>-value	self) value)
    (set (<variable>-level	self) level)
    (set (<variable>-offset	self) offset)
    (set (<variable>-next	self) next)
    self))

;;; operator

(define-structure <operator> (operation arguments))

(define-method do-print <operator> ()
  (print "{"(<operator>-operation self))
  (print " "(<operator>-arguments self))
  (print "}"))

(define-function operator (operation arguments)
  (let ((self (new <operator>)))
    (set (<operator>-operation	self) operation)
    (set (<operator>-arguments	self) arguments)
    self))

;;; compiler

(define-structure <compiler> (scope level next-local max-local program))

(define-method do-print <compiler> ()
  (print "<compiler:"(<compiler>-level self)"."(<compiler>-max-local self)","(<compiler>-scope self)">"))

(define-function compiler (scope level)
  (let ((self (new <compiler>)))
    (set (<compiler>-scope	self) scope)
    (set (<compiler>-level	self) level)
    (set (<compiler>-next-local self) 0)
    (set (<compiler>-max-local  self) 0)
    self))

(define-function push-local (compiler name)
  (let ((index (<compiler>-next-local compiler)))
    (set (<compiler>-next-local compiler) (+ index 1))
    (let ((local (variable name () (<compiler>-level compiler) index (<compiler>-scope compiler))))
      (set (<compiler>-scope compiler) local))))

(define-function pop-local (compiler)
  (let ((index (<compiler>-next-local compiler)))
    (set (<compiler>-next-local compiler) (- index 1))
    (let ((local (<compiler>-scope compiler)))
      (set (<compiler>-scope compiler) (<variable>-next local)))))

(define-function define-variable (compiler name value)
  (let ((variable (variable name value (<compiler>-level compiler) () (<compiler>-scope compiler))))
    (println compiler" --> "variable)
    (set (<compiler>-scope compiler) variable)))

(define-selector encode-expr)

(define-method encode-expr <symbol> (compiler)	(variable self 'VALUE 'LEVEL 'INDEX 'NEXT))

(define-method encode-expr <long>   (compiler)	(literal self))
(define-method encode-expr <string> (compiler)	(literal self))

(define-method encode-expr <pair>   (compiler)
  (let ((head (car self))
	(args (cdr self)))
    (cond
     ((= head 'define)	(do-define head args))
     (else		(operator (encode-expr (car self) compiler)
				  (map-with encode-expr (cdr self) compiler))))))

(define-function compile (source)
  (let* ((c       (compiler () ()))
	 (encoded (map-with encode-expr source compiler)))
    (println source)
    (println "=======>")
    (println encoded)))

(compile '(42))
(compile '(a))
(compile '((+ 1 2)))
(compile '((define a 42)))

(exit 0)

(compile '
 ((define printf (extern int "printf" (char *) ...))
  (printf "Hello, world\n")))

(exit 0)

(define *top-level* (cons () ()))

(set (car *top-level* (cons '*top-level* *top-level*)))

(define-structure <extern> (type name args))

(define-method do-print <extern> ()
  (print "<extern="(<extern>-name self)">"))

(define-function extern (type name args)
  (let ((self (new <extern>)))
    (set (<extern>-type self) type)
    (set (<extern>-name self) name)
    (set (<extern>-args self) args)
    self))

(define-function define-in (env name value)
  (set-cdr env (cons (cons name value) (cdr env)))
  value)

(define-in *top-level* 'extern
  (form (lambda (expr env)
	  (let ((type ( cadr expr))
		(name (caddr expr))
		(args (cdddr expr)))
	    (define-in *top-level* name (extern type name args)))
	  ())))
  
(define-selector compile-expr (expr env)	(error "cannot compile-expr: " expr))

(define-function compile-args (args env)
  (if (pair? args)
      (let ()
	(compile-args (cdr args) env)
	(compile-expr (car args) env))))

(define-method compile-expr <extern> (env)	(emit 'define self))
(define-method compile-expr <symbol> (env)	(emit 'lookup self))
(define-method compile-expr <undefined> (env)	)
(define-method compile-expr <long> (env)	(emit 'load self))
(define-method compile-expr <string> (env)	(emit 'load self))

(define-function emit args (print "EMIT ") (dumpln args))

(define-method compile-expr <pair> (env)
  (let ((head  (car self))
	(value ()))
    (if (and (symbol? head) (form? (set value (cdr (assq head env)))))
	(compile-expr (apply (<form>-function value) (cons self (cons env ())) env) env)
      (let ((args (cdr self)))
	(compile-args args env)
	(compile-expr head env)
	(emit 'apply (list-length args))))))

(define-function compile (program)
  (while program
    (let ((expr (car program)))
      (print "COMPILE ")
      (dumpln expr)
      (compile-expr expr *top-level*)
      )
    (set program (cdr program))))

(compile '(
  (extern int printf (* char) ...)
  (define nfibs
    (lambda (n)
      (if (< n 2)
	  1
	(+ 1
	   (+ (nfibs (- n 1))
	      (nfibs (- n 2)))))))
  (printf "%d\n" (nfibs 5))))

;; (define-structure <RI32> (generator))

;; (define-method do-print <RI32> ()
;;   (print (<RI32>-generator self) ":RI32"))

;; (define-function RI32 (gen)
;;   (let ((self (new <RI32>)))
;;     (set (<RI32>-generator self) gen)
;;     self))



;; (define-structure <ADDI32> (a b))

;; (define-method do-print <ADDI32> ()
;;   (print "ADDI32("(<ADDI32>-a self)","(<ADDI32>-b self)")"))

;; (define-function ADDI32 (a b)
;;   (let ((self (new <ADDI32>)))
;;     (set (<ADDI32>-a self) a)
;;     (set (<ADDI32>-b self) b)
;;     self))



;; (define-generic add)

;; (define-multimethod add ((a <RI32>) (b <RI32>))		(RI32 (ADDI32 a b)))

;; (define %eax (RI32 "%eax"))
;; (define %ebx (RI32 "%ebx"))

;; (println (add %eax %ebx))
