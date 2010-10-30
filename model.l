(define *backtrace*
  (lambda (stack depth)
    (while (>= (set depth (- depth 1)) 0)
      (println "  " depth "\t" (array-at stack depth)))
    (exit 0)))

(define <stage> (%allocate-type '<stage>))

(set-array-at *applicators* <stage>
  (lambda (stage arg)
    (println "you just applied " stage" with "arg)))

(set-array-at (selector-methods print) <stage>
  (lambda args
    (print "<stage>")))

(define s (allocate <stage> 0))

(println s)

(s 42)

(define <foo> (%allocate-type '<foo>))
(define foo (allocate <foo> 0))
(set-array-at (selector-methods print) <foo> (lambda args (error "trying to print a <foo>: " args)))

(error foo)

(exit 0)


(define-function do-stage (stage expr env)
  (println "DO-STAGE "stage" "expr" "env)
  (let ((fn (array-at stage (type-of expr))))
    (or fn (error "no stage rule to deal with "expr))
    (fn stage expr env)))

(define-function do-stage-list (stage expr env)
  (println "DO-STAGE-LIST "stage" "expr" "env)
  (and (pair? expr)
       (cons (do-stage stage (car expr) env) (do-stage-list stage (cdr expr) env))))

(define stage-encode (array 8))

(define-function exec-apply (args env)
  (apply (car args) (cdr args) env))

(define-function exec-lookup (arg env)
  (or (cdr (assq args env))
      (error "undefined: "arg)))

(set-array-at stage-encode <long>
	      (lambda (stage expr env)
		(println "STAGE-ENCODE:LONG "stage" "expr" "env)
		expr))

(set-array-at stage-encode <pair>
	      (lambda (stage expr env)
		(println "STAGE-ENCODE:PAIR "stage" "expr" "env)
		(let ((arguments (do-stage-list stage expr env)))
		  (cons exec-apply arguments))))

(set-array-at stage-encode <symbol>
	      (lambda (stage expr env)
		(println "STAGE-ENCODE:SYMBOL "stage" "expr" "env)
		(cons exec-lookup expr)))

(println (do-stage stage-encode '+) ())
(println (do-stage stage-encode '3) ())
(println (do-stage stage-encode '4) ())
(println (do-stage stage-encode '(+ 3 4) ()))

(exit 0)

(define stage-exec (array 8))

(set-array-at stage-exec <pair>
	      (lambda (stage expr env)
		(println "STAGE-EXEC:PAIR "expr)
		(let ((head (car expr))
		      (tail (do-stage-list stage (cdr expr) env)))
		  (if (pair? head)
		      (set head (do-stage stage expr head env)))
		  (apply head tail env))))

;; (do-stage stage-exec x ())
