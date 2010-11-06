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
    (set error abort)
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

(define cadr (lambda (x) (car (cdr x))))

(define concat-list
  (lambda (x y)
    (if (pair? x)
	(cons (car x) (concat-list (cdr x) y))
      y)))

(define concat-string
  (lambda (x y)
    (let ((a (string-length x))
	  (b (string-length y)))
      (let ((s (string (+ 1 (+ a b))))
	    (i 0)
	    (j 0))
	(while (< i a)
	  (set-string-at s j (string-at x i))
	  (set i (+ i 1))
	  (set j (+ j 1)))
	(set i 0)
	(while (< i b)
	  (set-string-at s j (string-at y i))
	  (set i (+ i 1))
	  (set j (+ j 1)))
	s))))

(define concat-symbol
  (lambda (x y)
    (string->symbol (concat-string (symbol->string x) (symbol->string y)))))

(define quasiquote
  (form
    (let ((qq-list) (qq-element) (qq-object))
      (set qq-list (lambda (l)
		     (if (pair? l)
			 (let ((obj (car l)))
			   (if (and (pair? obj) (= (car obj) 'unquote-splicing))
			       (list 'concat-list (cadr obj)      (qq-list (cdr l)))
			     (list   'cons        (qq-object obj) (qq-list (cdr l))))))))
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

(define-function list->array (list)
  (let ((%list->array (lambda (list index)
			(if (pair? list)
			    (let ((a (%list->array (cdr list) (+ 1 index))))
			      (set-array-at a index (car list))
			      a)
			  (array index)))))
    (lambda (list)
      (%list->array list 0))))

(define-function map (function list)
  (if (pair? list)
      (cons (function (car list))
	    (map function (cdr list)))))

(define-form define-apply (type args . body)
  `(set-array-at *applicators* ,type (lambda ,args ,@body)))

;;; structure

(define %structure-sizes	(array))
(define %structure-fields	(array))

(define-function %make-accessor (name fields offset)
  (if fields (cons `(define-form ,(concat-symbol name (concat-symbol '- (car fields))) (self) (list 'oop-at self ,offset))
		   (%make-accessor name (cdr fields) (+ 1 offset)))))

(define-function %make-accessors (name fields)
  (%make-accessor name fields 0))

(define-form define-structure (name fields)
  (let ((type (%allocate-type name))
	(size (list-length fields)))
    (set-array-at %structure-sizes  type size)
    (set-array-at %structure-fields type fields)
    `(let ()
       (define ,name ,type)
       ,@(%make-accessors name fields))))

(define-structure foo (a b c))

(define-function new (type)
  (allocate type (array-at %structure-sizes type)))

;;; <selector>

(define-structure <selector> (name methods default))

(define-apply <selector> (self . arguments)
  (apply (or (array-at (<selector>-methods self) (type-of (car arguments)))
	     (<selector>-default self))
	 arguments))

(define selector
  (lambda (name default)
    (let ((self (new <selector>)))
      (set (<selector>-name    self) name)
      (set (<selector>-methods self) (array))
      (set (<selector>-default self) default)
      self)))

(define-function <selector>-add-method (self type method)
  (set-array-at (<selector>-methods self) type method))

(define-form define-selector (name . default)
  (or default (set default `(args (error "cannot apply selector "',name" to: "args))))
  `(define ,name (selector ',name (lambda ,@default))))

(define-selector add-method)

(<selector>-add-method add-method <selector>
  (lambda (self type args body)
    (<selector>-add-method self (eval type) (eval `(lambda ,args ,@body)))))

(define-form define-method (selector type args . body)
  `(add-method ,selector ',type ',args ',body))

;;; print

(define-selector print args (apply %print args))

;(let ((i 0))
;  (while (<= i <subr>)
;    (set-array-at (<selector>-methods print) i %print)
;    (set i (+ 1 i))))

(define-method print <selector> (self)
  (print "<selector "(<selector>-name self)">"))

(define println
  (lambda args
    (while (pair? args)
      (print (car args))
      (set args (cdr args)))
    (print "\n")))

(define-selector print-until (target arg)
  (let ((found (= target arg)))
    (if (pair? arg)
	(let ()
	  (print "(")
	  (while arg
	    (if (print-until target (car arg))
		(let ()
		  (if (cdr arg) (print " ..."))
		  (set found 't)
		  (set arg ())))
	    (if (set arg (cdr arg)) (print " ")))
	  (print ")"))
      (print arg))
    found))

(define *backtrace*
  (lambda (stack depth)
    (let ((posn (array)))
      (while (>= (set depth (- depth 1)) 0)
	(let ((here (array-at stack depth)))
	  (print "  " depth "\t")
	  (print-until posn here)
	  (print "\n")
	  (set posn here))))
    (exit 0)))

(println print)

(define-selector concat)

