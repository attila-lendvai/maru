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

(define-function emit args (println "EMIT "args))

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
      (println "COMPILE "expr)
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
