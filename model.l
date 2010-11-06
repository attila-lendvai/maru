(define-structure <multimethod> (methods name))

(define-function multimethod (name)
  (let ((self (new <multimethod>)))
    (set (<multimethod>-methods self) (array))
    (set (<multimethod>-name    self) name)
    self))

(define-method print <multimethod> (self) (print "<multimethod:" (<multimethod>-name self) ">"))

(define-function %add-multimethod (mm types method)
  (let ((methods (or (<multimethod>-methods mm)
		     (set (<multimethod>-methods mm) (array 32)))))
    (while (cdr types)
      (let ((type (eval (car types))))
	(set methods (or (array-at methods type)
			 (set (array-at methods type) (array 32)))))
      (set types (cdr types)))
    (set (array-at methods (eval (car types))) method)))

(define-form define-multimethod (method typed-args . body)
  (let ((args  (map car  typed-args))
	(types (map cadr typed-args)))
    `(%add-multimethod ,method (list ,@types) (lambda ,args ,@body))))

(define-apply <multimethod> (self . arguments)
  (let ((method (<multimethod>-methods self))
	(arg     arguments))
    (while arg
      (set method (array-at method (type-of (car arg))))
      (set arg (cdr arg)))
    (if method 
	(apply method arguments)
      (error "no method in "(<multimethod>-name self)" corresponding to "arguments))))

(define foo (multimethod 'foo))

(let ((arg1 (array 32)))
  (set (array-at arg1 <long>)
       (let ((arg2 (array 32)))
	 (set (array-at arg2 <long>)
	      (lambda (self arg) (println "foo on long.long: "self arg)))
	 arg2))
  (set (<multimethod>-methods foo) arg1))

(foo 1 2)

(define-multimethod foo ((self <long>)	 (arg <long>))		(println "ANOTHER foo on long.long: "		self " " arg))
(define-multimethod foo ((self <long>)	 (arg <long>))		(println "ANOTHER foo on long.long: "		self " " arg))
(define-multimethod foo ((self <string>) (arg <long>))		(println "ANOTHER foo on string.long: "		self " " arg))
(define-multimethod foo ((self <long>) 	 (arg <string>))	(println "ANOTHER foo on long.string: "		self " " arg))
(define-multimethod foo ((self <string>) (arg <string>))	(println "ANOTHER foo on string.string: "	self " " arg))
(define-multimethod foo ((self <symbol>))			(println "ANOTHER foo on symbol: "		self))

(foo 3 4)
(foo "five" 6)
(foo 7 "eight")
(foo "nine" "ten")
(foo 'foo)

(define-function fnfibs (n)
  (if (< n 2)
      1
    (+ 1 (+ (fnfibs (- n 1)) (fnfibs (- n 2))))))

(define nfibs	(multimethod 'nfibs))
(define add	(multimethod 'add))
(define sub	(multimethod 'sub))
(define less	(multimethod 'less))

(define-multimethod add	((self <long>) (arg <long>)) (+ self arg))
(define-multimethod sub	((self <long>) (arg <long>)) (- self arg))
(define-multimethod less	((self <long>) (arg <long>)) (< self arg))

(define-multimethod nfibs ((self <long>))
  (if (less self 2)
      1
    (add 1 (add (nfibs (sub self 1)) (nfibs (sub self 2))))))

;(println (fnfibs 28))
;(println (nfibs 28))

(exit 0)



(define <stage> (%allocate-type '<stage>))

(set-array-at *applicators* <stage>
  (lambda (stage arg)
    (println "you just applied " stage" with "arg)))

(set-array-at (<selector>-methods print) <stage>
  (lambda args
    (print "<stage>")))

(define s (allocate <stage> 0))

(println s)

(s 42)

(define <foo> (%allocate-type '<foo>))
(define foo (allocate <foo> 0))
(set-array-at (<selector>-methods print) <foo> (lambda args (error "trying to print a <foo>: " args)))

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
