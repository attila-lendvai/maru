(define list (lambda args args))

(define %print print)
(define %dump  dump)

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

(define caar (lambda (x) (car (car x))))
(define cadr (lambda (x) (car (cdr x))))
(define cdar (lambda (x) (cdr (car x))))
(define cddr (lambda (x) (cdr (cdr x))))
(define caddr (lambda (x) (car (cdr (cdr x)))))
(define cdddr (lambda (x) (cdr (cdr (cdr x)))))
(define cadddr (lambda (x) (car (cdr (cdr (cdr x))))))

(define assq
  (lambda (object list)
    (let ((result ()))
      (while (pair? list)
	(if (= object (caar list))
	    (let ()
	      (set result (car list))
	      (set list ())))
	(set list (cdr list)))
      result)))

(define concat-list
  (lambda (x y)
    (if (pair? x)
	(cons (car x) (concat-list (cdr x) y))
      y)))

(define concat-string
  (lambda (x y)
    (let ((a (string-length x))
	  (b (string-length y)))
      (let ((s (string (+ a b)))
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
			       (if (cdr l)
				   (list 'concat-list (cadr obj) (qq-list (cdr l)))
				 (cadr obj))
			     (list 'cons (qq-object obj) (qq-list (cdr l)))))
		       (list 'quote l))))
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

(define %list->array
  (lambda (list index)
    (if (pair? list)
	(let ((a (%list->array (cdr list) (+ 1 index))))
	  (set-array-at a index (car list))
	  a)
      (array index))))

(define-function list->array (list)
  (%list->array list 0))

(define-function map (function list)
  (if (pair? list)
      (let ((head (function (car list))))
	(cons head (map function (cdr list))))))

(define-function map-with (function list a)
  (if (pair? list)
      (let ((head (function (car list) a)))
	(cons head (map-with function (cdr list) a)))))

(define-function map2-with (function alist blist a)
  (if (pair? alist)
      (let ((head (function (car alist) (car blist) a)))
	(cons head (map2-with function (cdr alist) (cdr blist) a)))))

(define-form define-expand (type args . body)	`(set-array-at *expanders*   ,type (lambda ,args ,@body)))
(define-form define-encode (type args . body)	`(set-array-at *encoders*    ,type (lambda ,args ,@body)))
(define-form define-eval   (type args . body)	`(set-array-at *evaluators*  ,type (lambda ,args ,@body)))
(define-form define-apply  (type args . body)	`(set-array-at *applicators* ,type (lambda ,args ,@body)))

;;; let*

(define-function %let* (bindings body)
  (if (pair? (cdr bindings))
      `(let (,(car bindings)) ,(%let* (cdr bindings) body))
    `(let ,bindings ,@body)))

(define-form let* bindings-body
  (%let* (car bindings-body) (cdr bindings-body)))

;;; cond

(define-function %cond (clauses)
  (if (pair? clauses)
      (let* ((clause (car clauses))
	     (test   (car clause))
	     (value  (cadr clause)))
	(if (= 'else test)
	    value
	  `(if ,test ,value ,(%cond (cdr clauses)))))))

(define-form cond clauses (%cond clauses))

;;; type information

(define %type-names	(array 16))
(define %last-type	-1)

(define %allocate-type
  (lambda (name)
    (set %last-type (+ 1 %last-type))
    (set-array-at %type-names %last-type name)
    %last-type))

(define-function name-of-type (type)
  (array-at %type-names type))

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

(define-function new (type)
  (allocate type (array-at %structure-sizes type)))

;;; built-in types

(define-structure <undefined>	())
(define-structure <long>	(_bits))
(define-structure <string>	(size _bits))
(define-structure <symbol>	(_bits))
(define-structure <pair>	(head tail))
(define-structure <_array>	())
(define-structure <array>	(_array))
(define-structure <expr>	(defn env))
(define-structure <form>	(function))
(define-structure <fixed>	(function))
(define-structure <subr>	(_imp _name))

;;; selector

(define-structure <selector> (name methods default))

(define-apply <selector> (self . arguments)
  (apply (or (array-at (<selector>-methods self) (type-of (car arguments)))
	     (<selector>-default self))
	 arguments))

(define-function selector (name default)
  (let ((self (new <selector>)))
    (set (<selector>-name    self) name)
    (set (<selector>-methods self) (array))
    (set (<selector>-default self) default)
    self))

(define-function <selector>-add-method (self type method)
  (set-array-at (<selector>-methods self) type method))

(define-form define-selector (name . default)
  (or default (set default `(args (error "cannot apply selector "',name
					 " to "(array-at %type-names (type-of (car args)))
					 ": "(cons (car args) (map name-of-type (map type-of (cdr args))))))))
  `(define ,name (selector ',name (lambda ,@default))))

(define-selector add-method)

(<selector>-add-method add-method <selector>
  (lambda (self type args body)
    (<selector>-add-method self (eval type) (eval `(lambda ,args ,@body)))))

(define-form define-method (selector type args . body)
  (if (symbol? args)
      `(add-method ,selector ',type ',(cons 'self args) ',body)
      `(add-method ,selector ',type '(self ,@args) ',body)))

;;; print

(define-selector do-print (arg) (%print arg))
(define-selector do-dump  (arg) (do-print arg))

(define print
  (lambda args
    (while (pair? args)
      (do-print (car args))
      (set args (cdr args)))))

(define dump
  (lambda args
    (while (pair? args)
      (do-dump (car args))
      (set args (cdr args)))))

(define println
  (lambda args
    (apply print args)
    (%print "\n")))

(define dumpln
  (lambda args
    (apply dump args)
    (%print "\n")))

(define-method do-dump  <string> ()	(%dump self))
(define-method do-print <selector> ()	(print "<selector "(<selector>-name self)">"))

(define-method do-print <pair> ()
  (if (= *globals* (cdr self))
      (print "*globals*")
    (let ()
      (print "(")
      (while self
	(if (pair? self)
	    (print (car self))
	  (let ()
	    (print ". ")
	    (print self)))
	(if (set self (cdr self))
	    (print " ")))
      (print ")"))))

(define-function dump-until (target arg)
  (let ((found (= target arg)))
    (if (pair? arg)
	(let ()
	  (print "(")
	  (while arg
	    (if (pair? arg)
		(if (dump-until target (car arg))
		    (let ()
		      (if (cdr arg) (print " ..."))
		      (set found 't)
		      (set arg ())))
	      (let ()
		(print ". ")
		(dump-until target arg)))
	    (if (set arg (cdr arg))
		(print " ")))
	  (print ")"))
      (print arg))
    found))

(define *backtrace*
  (lambda (stack depth)
    (let ((posn (array)))
      (while (>= (set depth (- depth 1)) 0)
	(let ((here (array-at stack depth)))
	  (print "  " depth "\t")
	  (dump-until posn here)
	  (print "\n")
	  (set posn here))))
    (exit 0)))

;;; multimethod

(define-structure <generic> (name methods default))

(define-function generic (name default)
  (let ((self (new <generic>)))
    (set (<generic>-name    self) name)
    (set (<generic>-methods self) (array))
    (set (<generic>-default self) default)
    self))

(define-method do-print <generic> () (print "<multimethod:" (<generic>-name self) ">"))

(define-form define-generic (name . default)
  (or default (set default `(args (error "no method in  "',name" corresponding to: "args))))
  `(define ,name (generic ',name (lambda ,@default))))

(define-function %add-multimethod (mm types method)
  (if types
      (let ((methods (or (<generic>-methods mm)
			 (set (<generic>-methods mm) (array 32)))))
	(while (cdr types)
	  (let ((type (eval (car types))))
	    (set methods (or (array-at methods type)
			     (set (array-at methods type) (array 32)))))
	  (set types (cdr types)))
	(set (array-at methods (eval (car types))) method))
    (set (<generic>-methods mm) method)))

(define-form define-multimethod (method typed-args . body)
  (let ((args  (map cadr typed-args))
	(types (map car  typed-args)))
    `(%add-multimethod ,method (list ,@types) (lambda ,args ,@body))))

(define-apply <generic> (self . arguments)
  (let ((method (<generic>-methods self))
	(arg     arguments))
    (while arg
      (set method (array-at method (type-of (car arg))))
      (set arg (cdr arg)))
    (if (and method (not (array? method)))
	(apply method arguments)
      (let ((default (<generic>-default self)))
	(if default
	    (apply default arguments)
	  (error "no method in "(<generic>-name self)" corresponding to "arguments))))))

;;; list

(define-form push (list element)
  `(set ,list (cons ,element ,list)))

(define-form pop (list)
  `(let* ((_list_ ,list) (_head_ (car _list_)))
     (set ,list (cdr _list_))
     _head_))

;;; iteration

(define-form for (var-init-limit-step . body)
  (let ((var   	   (car    var-init-limit-step)	   )
	(init  	   (cadr   var-init-limit-step)	   )
	(limit 	   (caddr  var-init-limit-step)	   )
	(step  (or (cadddr var-init-limit-step) 1)))
    `(let ((,var ,init) (_limit_ ,limit))
       (while (< ,var _limit_)
	 ,@body
	 (set ,var (+ ,var ,step))))))

(define-form list-do (var list . body)
  `(let ((_list_ ,list))
     (while _list_
       (let ((,var (car _list_))) ,@body)
       (set _list_ (cdr _list_)))))

;;; conversion

(define-function array->string (arr)
  (let* ((ind 0)
	 (lim (array-length arr))
	 (str (string lim)))
    (while (< ind lim)
      (set-string-at str ind (array-at arr ind))
      (set ind (+ 1 ind)))
    str))
