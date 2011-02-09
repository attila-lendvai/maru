(define unit-testing? '(t))

(define list (lambda args args))

(define %print print)
(define %dump  dump)

(define error)

(define %error
  (lambda args
    (set error abort)
    (%print "\nERROR: ")
    (apply %print args)
    (%print "\n")
    (abort)))

(set error
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
(define cadar (lambda (x) (car (cdr (car x)))))
(define caadr (lambda (x) (car (car (cdr x)))))
(define cdadr (lambda (x) (cdr (car (cdr x)))))
(define caddr (lambda (x) (car (cdr (cdr x)))))
(define cdddr (lambda (x) (cdr (cdr (cdr x)))))
(define caddar (lambda (x) (car (cdr (cdr (car x))))))
(define caaddr (lambda (x) (car (car (cdr (cdr x))))))
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
      (lambda (env expr)
	(qq-object expr)))))

(define define-form (form (lambda (env name args . body)
			    `(define ,name (form (lambda (*env* ,@args) ,@body))))))

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

(define-function array-append (arr val)
  (set-array-at arr (array-length arr) val))

(define-function map (function list)
  (if (pair? list)
      (let ((head (function (car list))))
	(cons head (map function (cdr list))))))

(define-function map-with (function list a)
  (if (pair? list)
      (let ((head (function (car list) a)))
	(cons head (map-with function (cdr list) a)))))

(define-function with-map (function a list)
  (if (pair? list)
      (let ((head (function a (car list))))
	(cons head (with-map function a (cdr list))))))

(define-function map2-with (function alist blist a)
  (if (pair? alist)
      (let ((head (function (car alist) (car blist) a)))
	(cons head (map2-with function (cdr alist) (cdr blist) a)))))

(set *expanders*   (array))	(define-form define-expand (type args . body)	`(set-array-at *expanders*   ,type (lambda ,args ,@body)))
(set *encoders*    (array))	(define-form define-encode (type args . body)	`(set-array-at *encoders*    ,type (lambda ,args ,@body)))
(set *evaluators*  (array))	(define-form define-eval   (type args . body)	`(set-array-at *evaluators*  ,type (lambda ,args ,@body)))
(set *applicators* (array))	(define-form define-apply  (type args . body)	`(set-array-at *applicators* ,type (lambda ,args ,@body)))

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
	     (value  (cdr clause)))
	(if (= 'else test)
	    `(let () ,@value)
	  `(if ,test (let () ,@value) ,(%cond (cdr clauses)))))))

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
(define %structure-bases	(array))
(define %structure-derivatives	(array))

(define-function %typecheck (type object)
  (or (= type (type-of object))
      (error "type check failed for field accessor: expected "(array-at %type-names type)" got "(array-at %type-names (type-of object))))
  object)

(define-function %make-accessor (name fields offset)
  (if fields (cons `(define-form ,(concat-symbol name (concat-symbol '- (car fields))) (self)
		      (list 'oop-at
			    self ; (list '%typecheck ',name self) ; self
			    ,offset))
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

(define-form define-class (name basis fields)
  (let ((base (eval basis)))
    (set fields (concat-list (array-at %structure-fields base) fields))
    (let ((type   (%allocate-type name))
	  (offset (list-length (array-at %structure-fields base)))
	  (size   (list-length fields)))
      (set-array-at %structure-sizes  type size)
      (set-array-at %structure-fields type fields)
      (set-array-at %structure-bases  type base)
      (let ((derived (or (array-at %structure-derivatives base)
			 (set-array-at %structure-derivatives base (array)))))
	(array-append derived type))
      `(let ()
	 (define ,name ,type)
	 ,@(%make-accessors name fields)))))

;;; built-in types

(define-structure <undefined>	())
(define-structure <long>	(_bits))
(define-structure <string>	(size _bits))
(define-structure <symbol>	(_bits))
(define-structure <pair>	(head tail))
(define-structure <_array>	())
(define-structure <array>	(size _array))
(define-structure <expr>	(name defn ctx))
(define-structure <form>	(function symbol))
(define-structure <fixed>	(function))
(define-structure <subr>	(_imp _name))
(define-structure <variable>	(name value env index))
(define-structure <env>		(parent level offset bindings stable))
(define-structure <context>	(home env bindings callee))

(define-function fixed (fun)
  (let ((self (new <fixed>)))
    (set (<fixed>-function self) fun)
    self))

(define-function variable (name value env index)
  (let ((self (new <variable>)))
    (set (<variable>-name  self) name)
    (set (<variable>-value self) value)
    (set (<variable>-env   self) env)
    (set (<variable>-index self) index)
    self))

(define-function environment (parent)
  (let ((self (new <env>)))
    (set (<env>-parent 	 self) parent)
    (set (<env>-level  	 self) (<env>-level  parent))
    (set (<env>-offset 	 self) (<env>-offset parent))
    (set (<env>-bindings self) (array))
    self))

(define-function environment-define (env name value)
  (let ((bindings (<env>-bindings env))
	(offset   (<env>-offset   env))
	(var      (variable name value env offset)))
    (set (<env>-offset env) (+ offset 1))
    (array-append bindings var)))

;;; local syntax

(define-function make-with-form (args-body)
  (and args-body `(lambda (*env* ,@(car args-body)) ,@(cdr args-body))))

(define-form with-forms (bindings . body)
  (let ((env (environment *env*)))
    (while bindings
      (let* ((binding (car   bindings))
	     (name    (car   binding))
	     (fun     (cadr  binding))
	     (var     (caddr binding))
	     (exp     (list 'form (make-with-form fun) (make-with-form var))))
	(environment-define env (caar bindings) (eval exp *env*))
	(set bindings (cdr bindings))))
    (cons 'let (cons () (map-with expand body env)))))

;;; field accesors

(define-function make-instance-accessors (name fields i)
  (and (pair? fields)
       (cons `(,(concat-symbol 'self. (car fields)) () ((name) (list 'oop-at 'self ,i)))
	     (make-instance-accessors name (cdr fields) (+ i 1)))))
  
(define-form with-instance-accessors (type . body)
  `(with-forms ,(make-instance-accessors type (array-at %structure-fields (eval type)) 0)
    (let () ,@body)))

;;; selector

(define-structure <selector> (name methods default))

(define-function selector? (obj) (= <selector> (type-of obj)))

(define-function <selector>-inherit (methods type)
  (let ((method ()))
    (while (and (set type (array-at %structure-bases type))
		(not (set method (array-at methods type)))))
    method))

(define-apply <selector> (self . arguments)
  (apply (or (array-at (<selector>-methods self) (type-of (car arguments)))
	     (<selector>-inherit (<selector>-methods self) (type-of (car arguments)))
	     (<selector>-default self))
	 arguments))

(define-function selector (name default)
  (let ((self (new <selector>)))
    (set (<selector>-name    self) name)
    (set (<selector>-methods self) (array))
    (set (<selector>-default self) default)
    self))

(define-function <selector>-add-method (self type method)
  (or (<expr>-name method) (set (<expr>-name method) (<selector>-name self)))
  (set-array-at (<selector>-methods self) type method))

(define-form define-selector (name . default)
  (let ((def (defined? name)))
    (if def
	(or (selector? def)
	    (error name" already defined as non-selector"))
      (let ()
	(or default (set default `(args (error "cannot apply selector "',name
					       " to "(array-at %type-names (type-of (car args)))
					       ": "(cons (car args) (map name-of-type (map type-of (cdr args))))))))
	`(define ,name (selector ',name (lambda ,@default)))))))

(define-selector add-method)

(<selector>-add-method add-method <selector>
  (lambda (self type args body)
    (<selector>-add-method self type (eval `(lambda ,args (with-instance-accessors ,type ,@body))))))

(define-form define-method (selector type args . body)
  `(add-method ,selector ,type ',(cons 'self args) ',body))

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

(if 't;;()
    (set *backtrace*
	 (lambda (stack depth)
	   (println "\n")
	   (let ((posn (array)))
	     (while (>= (set depth (- depth 1)) 0)
	       (let ((here (array-at stack depth)))
		 (print "  " depth "\t")
		 (dump-until posn here)
		 (print "\n")
		 (set posn here))))
	   (exit 0))))

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
  (or (<expr>-name method) (set (<expr>-name method) (<generic>-name mm)))
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

;; (define-function array->list (arr)
;;   (let* ((ind (array-length arr))
;; 	 (lst ()))
;;     (while (<= 0 (set ind (- ind 1)))
;;       (set lst (cons (array-at arr ind) lst)))
;;     lst))

;;; structural equality

(define equal ()) ;; forward

(define-function equal-lists (a b)
  (and (equal (car a) (car b))
       (equal (cdr a) (cdr b))))

(set equal (lambda (a b)
  (or (= a b)
      (and (pair? a)
	   (pair? b)
	   (equal-lists a b)))))

;;; unit testing

(define-form unit-fail (expr)
  `(error "UNIT FAIL "unit-name": "',expr))

(define-form unit-assert (expr)
  `(or ,expr (unit-fail ,expr)))

(define-form unit-test (name . body)
  (and unit-testing?
       `(let ((unit-name ,name))
	  ,@body)))

;;; namespace

(define *global* *globals*)

(define-form define-namespace (name parent)	`(define ,name (environment ,parent)))

(define-form namespace (name)			`(set *globals* ,name))
