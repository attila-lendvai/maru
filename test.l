(define println
  (lambda args
    (while (pair? args)
      (print (car args))
      (set args (cdr args)))
    (print "\n")))

(println 42)

(define nfibs
  (lambda (n)
    (if (< n 2)
	1
      (+ (+ (nfibs (- n 1)) (nfibs (- n 2))) 1))))

(define-selector sfibs)

(define-selector less)	(define-method less <long> (other) (< self other))
(define-selector add)	(define-method add  <long> (other) (+ self other))
(define-selector sub)	(define-method sub  <long> (other) (- self other))

(define-method sfibs <long> ()
  (if (less self 2)
      1
    (add (add (sfibs (sub self 1)) (sfibs (sub self 2))) 1)))

(println (sfibs 28))

(exit 0)

(define list (lambda args args))

(println (list 1 2 3 4))

(define cadr (lambda (x) (car (cdr x))))

(define concat (lambda (x y)
		 (if (pair? x)
		     (cons (car x) (concat (cdr x) y))
		   y)))

(define quasiquote
  (form
    (let ((qq-list) (qq-element) (qq-object))
      (set qq-list (lambda (l)
		     (if (pair? l)
			 (let ((obj (car l)))
			   (if (and (pair? obj) (= (car obj) 'unquote-splicing))
			       (list 'concat (cadr obj)      (qq-list (cdr l)))
			     (list   'cons   (qq-object obj) (qq-list (cdr l))))))))
      (set qq-element (lambda (l)
			(let ((head (car l)))
			  (if (= head 'unquote)
			      (cadr l)
			    (qq-list l)))))
      (set qq-object (lambda (object)
		       (if (pair? object)
			   (qq-element object)
			 (list 'quote object))))
      (lambda (expr)
	(qq-object expr)))))

(println quasiquote)

(println `42)
(println `(list 99))

(println `(list 1 2 3 4))

(println `,(list 1 2 3 4))

(println `((+ 1 2) ,(+ 3 4) (+ 5 6)))

(println `((list 1 2) ,(list 3 4) ,@(list 5 6)))

(define define-form (form (lambda (name args . body)
			    `(define ,name (form (lambda ,args ,@body))))))

(define-form define-function (name args . body)
  `(define ,name (lambda ,args ,@body)))

(define-function foo (x) (+ x x))

(println (foo 21))

(define-function list-length (list)
  (if (pair? list)
      (+ 1 (list-length (cdr list)))
    0))

(println (list-length '(a b c d e f)))

(define-function %list->array (list index)
  (if (pair? list)
      (let ((a (%list->array (cdr list) (+ 1 index))))
	(set-array-at a index (car list))
	a)
    (array index)))

(define-function list->array (list)
  (%list->array list 0))

(println (list->array '(a b c d e f)))

(define a (list->array '(a b c)))
(println a)
(set-array-at a 2 'see)
(println a)
(set-array-at a 6 'six)
(println a)

(define *applicators* (array 0))
(set-array-at *applicators* (type-of 42) (lambda (x) (println "you applied an integer: " x) x))

(println *applicators*)

(println (42))

(define foo (array 0))

(set-array-at foo 0
  (lambda args
    (println "cannot apply method foo to "args)
    (exit 1)))

(set-array-at foo (type-of "string")
  (lambda (x) (println "method on string") x))

(set-array-at *applicators* (type-of foo)
  (lambda (method . args)
    (let ((func (array-at method (type-of (car args)))))
      (if func 
	  (apply func args)
	(apply (array-at method 0) args)))))

(println (foo "hello"))

