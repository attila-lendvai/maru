(define list (lambda args args))

(define %type-names	(array 16))

(define %last-type	-1)

(define %allocate-type
  (lambda (name)
    (set %last-type (+ 1 %last-type))
    (set-array-at %type-names %last-type name)
    %last-type))

(define <undefined>	(%allocate-type '<undefined>))
(define <long>		(%allocate-type '<long>))
(define <string>	(%allocate-type '<string>))
(define <symbol>	(%allocate-type '<symbol>))
(define <pair>		(%allocate-type '<pair>))
(define <_array>	(%allocate-type '<_array>))
(define <array>		(%allocate-type '<array>))
(define <expr>		(%allocate-type '<expr>))
(define <form>		(%allocate-type '<form>))
(define <fixed>		(%allocate-type '<fixed>))
(define <subr>		(%allocate-type '<subr>))

(define %print print)

(define %error
  (lambda args
    (%print "\nERROR: ")
    (apply %print args)
    (%print "\n")
    (abort)))

(define error
  (lambda args
    (set error %error)
    (%print "\nerror: ")
    (apply print args)
    (%print "\n")
    (abort)))

(set *applicators* (array 16))

(define <selector> (%allocate-type '<selector>))

(define selector-name		(form (lambda (self) (list 'oop-at self 0))))
(define selector-methods	(form (lambda (self) (list 'oop-at self 1))))

(define selector
  (lambda (name)
    (let ((self (allocate <selector> 2)))
      (set (selector-name    self) name)
      (set (selector-methods self) (array 16))
      self)))

(set-array-at *applicators* <selector>
  (lambda (selector . arguments)
    (let ((method (array-at (selector-methods selector) (type-of (car arguments)))))
      (if method
	  (apply method arguments)
	(error "cannot apply selector "(selector-name selector)" to "arguments)))))

(define print (selector 'print))

(let ((i 0))
  (while (<= i <subr>)
    (set-array-at (selector-methods print) i %print)
    (set i (+ 1 i))))

(define println
  (lambda args
    (while (pair? args)
      (print (car args))
      (set args (cdr args)))
    (print "\n")))

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

(define define-form (form (lambda (name args . body)
			    `(define ,name (form (lambda ,args ,@body))))))

(define-form define-function (name args . body)
  `(define ,name (lambda ,args ,@body)))

(define-function list-length (list)
  (if (pair? list)
      (+ 1 (list-length (cdr list)))
    0))

(define-function %list->array (list index)
  (if (pair? list)
      (let ((a (%list->array (cdr list) (+ 1 index))))
	(set-array-at a index (car list))
	a)
    (array index)))

(define-function list->array (list)
  (%list->array list 0))
