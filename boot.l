;;; This is the minimum "standard library" that is needed/used while bootstrapping

(define list (lambda args args))

(define primitive/print print)
(define primitive/dump  dump)

(define error/nested
  (lambda args
    (set error abort) ; let's give up in case of more recursive errors
    (primitive/print "\nNESTED ERROR: ")
    (apply primitive/print args)
    (primitive/print "\n")
    (abort)))

(define error
  (lambda args
    (set error error/nested) ; in case a nested error happens while reporting
    (primitive/print "\nerror: ")
    (apply print args)
    (primitive/print "\n")
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
(define cddddr (lambda (x) (cdr (cdr (cdr (cdr x))))))

(define memq
  (lambda (object list)
    (let ((result ()))
      (while (pair? list)
        (if (= object (car list))
            (let ()
              (set result list)
              (set list ()))
          (set list (cdr list))))
      result)))

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

(define concat-strings
  (lambda args
    (let ((result (car args)))
      (while (string? (car (set args (cdr args))))
        (set result (concat-string result (car args))))
      result)))

(define concat-symbol
  (lambda (x y)
    (string->symbol (concat-string (symbol->string x) (symbol->string y)))))

(define concat-symbols
  (lambda args
    (let ((result (car args)))
      (while (symbol? (car (set args (cdr args))))
        (set result (concat-symbol result (car args))))
      result)))

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
                             (if (and (= 'unquote obj) (pair? (cdr l)) (not (cddr l)))
                                 (cadr l)
                               (list 'cons (qq-object obj) (qq-list (cdr l))))))
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

(define-form when (test . body)
  `(and ,test (let () ,@body)))

(define-form unless (test . body)
  `(or ,test (let () ,@body)))

(define-form assert (test . args)
  (unless args
    (set args (list "assertion failed: " `(quote ,test))))
  `(unless ,test
     (error ,@args)))

(define-form define-constant (name value)
  ;; for now this is merely a maker of intention.
  `(define ,name ,value))

(define-form define-function (name args . body)
  `(define ,name (lambda ,args ,@body)))

(define-function list-length (list)
  (assert (or (not list) (pair? list)) "LIST-LENGTH called with an improper list: " list)
  (if (pair? list)
      (let ((len 1))
        (while (set list (cdr list))
          (set len (+ len 1)))
        len)
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

(define-function map1 (function list)
  (let ((head (cons)))
    (let ((tail head))
      (while (pair? list)
        (set tail (set (cdr tail) (cons (function (car list)) ())))
        (set list (cdr list))))
    (cdr head)))

(define-function mapN (function lists)
  (and (pair? (car lists))
       (cons (apply function (map1 car lists))
             (mapN function (map1 cdr lists)))))

(define-function map (function . lists)
  (if (pair? (cdr lists))
      (mapN function lists)
    (map1 function (car lists))))

(define-function reverse-map (function list)
  (and list
       (let ((tail (reverse-map function (cdr list))))
         (cons (function (car list)) tail))))

(define-function reverse-with-map (function arg list)
  (and list
       (let ((tail (reverse-with-map function arg (cdr list))))
         (cons (function arg (car list)) tail))))

(define-function reverse-map-with (function list arg)
  (and list
       (let ((tail (reverse-map-with function (cdr list) arg)))
         (cons (function (car list) arg) tail))))

(define-function map-with (function list a)
  (if (pair? list)
      (let ((head (function (car list) a)))
        (cons head (map-with function (cdr list) a)))))

(define-function with-map (function a list)
  (if (pair? list)
      (let ((head (function a (car list))))
        (cons head (with-map function a (cdr list))))))

(define-function map-with2 (function list a b)
  (if (pair? list)
      (let ((head (function (car list) a b)))
        (cons head (map-with2 function (cdr list) a b)))))

(define-function with2-map (function a b list)
  (if (pair? list)
      (let ((head (function a b (car list))))
        (cons head (with2-map function a b (cdr list))))))

(define-function with-map2 (function a alist blist)
  (if (pair? alist)
      (let ((head (function a (car alist) (car blist))))
        (cons head (with-map2 function a (cdr alist) (cdr blist))))))

(define-function map2-with (function alist blist a)
  (if (pair? alist)
      (let ((head (function (car alist) (car blist) a)))
        (cons head (map2-with function (cdr alist) (cdr blist) a)))))

(define-function map* (function . lists)
  (if (pair? (car lists))
      (let ((head (apply function (map car lists))))
        (cons head (apply map* (cons function (map cdr lists)))))))

(define-function foldr (op value list)
  (if (pair? list)
      (op (car list) (foldr op value (cdr list)))
    value))

(define-form define-expand (type args . body)   `(set-array-at *expanders*   ,type (lambda ,args ,@body)))
(define-form define-encode (type args . body)   `(set-array-at *encoders*    ,type (lambda ,args ,@body)))
(define-form define-eval   (type args . body)   `(set-array-at *evaluators*  ,type (lambda ,args ,@body)))
(define-form define-apply  (type args . body)   `(set-array-at *applicators* ,type (lambda ,args ,@body)))

;;; let*

(define-function %let* (bindings body)
  (if (pair? (cdr bindings))
      `(let (,(car bindings)) ,(%let* (cdr bindings) body))
    `(let ,bindings ,@body)))

(define-form let* bindings-body
  (%let* (car bindings-body) (cdr bindings-body)))

;;; cond

(define-function %maybe-progn (prog)
  (if (cdr prog)
      (cons 'let (cons '() prog))
    (car prog)))

(define-function %cond (clauses)
  (if (pair? clauses)
      (let* ((clause (car clauses))
             (test   (car clause))
             (body   (cdr clause)))
        (if (= 'else test)
            (%maybe-progn body)
          (if (= '=> (car body)) ; scheme syntax to funcall the body
              `(let ((_ ,test))
                 (if _
                     (,(%maybe-progn (cdr body)) _)
                   ,(%cond (cdr clauses))))
            `(if ,test
                 ,(%maybe-progn body)
               ,(%cond (cdr clauses))))))))

(define-form cond clauses (%cond clauses))

;;; type information

(define %type-names     (array 16))
(define %last-type      -1)

(define-function %allocate-type (name)
  (set %last-type (+ 1 %last-type))
  (set-array-at %type-names %last-type name)
  %last-type)

(define-function name-of-type (type)
  (array-at %type-names type))

(define-function type-name-of (obj)
  (name-of-type (type-of obj)))

;;; structure

(define %structure-fields       (array))
(define %structure-field-counts (array))

(define-function %make-accessor (name fields offset)
  (when fields
    (cons `(define-form ,(concat-symbol name (concat-symbol '- (car fields))) (self)
             (list 'oop-at self ,offset))
          (%make-accessor name (cdr fields) (+ 1 offset)))))

(define-function %make-accessors (name fields)
  (%make-accessor name fields 0))

(define-form define-structure (name fields)
  (let ((type (%allocate-type name)))
    (set-array-at %structure-field-counts type (list-length fields))
    (set-array-at %structure-fields       type fields)
    `(let ()
       (define ,name ,type)
       ,@(%make-accessors name fields))))

(define-function new (type)
  (allocate type (structure-field-count type)))

(define-function structure-field-count (type)
  (array-at %structure-field-counts type))

(define-function structure-field-index (type field-name)
  (let ((i 0)
        (list (array-at %structure-fields type)))
    (while (and (pair? list)
                (not (= field-name (car list))))
      (set list (cdr list))
      (set i (+ i 1)))
    (or (and (pair? list)
             i)
        (error "structure-field-index has failed for type "type", field-name "field-name))))

;;; built-in types

;; NOTE: the subr's in eval.l assume a certain layout for the built-in types.
;; what actually happens is encoded in eval.l, and the define-structure forms
;; for the built-in types in boot.l merely fill in some missing parts. types
;; are represented internally as successive integers.
;; corollary: the two files must agree, both in the order and in the field layout.
(define-structure <undefined>   ())
(define-structure <long>        (_bits))				(define-function long? (self) (= <long> (type-of self)))
(define-structure <string>      (size _bits))
(define-structure <symbol>      (_bits))
(define-structure <pair>        (head tail))
(define-structure <_array>      ())
(define-structure <array>       (size _array))
(define-structure <expr>        (defn env))
(define-structure <form>        (function symbol)) ; these are expander lambda's
(define-structure <fixed>       (function))
(define-structure <subr>        (_name _imp _sig _profile))
(define-structure <module>      (symbols env))
(define-structure <variable>	(name value env index type))		(define-function variable? (obj) (= <variable> (type-of obj)))
(define-structure <env>		(parent level offset bindings stable))
(define-structure <context>	(home env bindings callee pc))

(define-function fixed (fun)
  (let ((self (new <fixed>)))
    (set (<fixed>-function self) fun)
    self))

(define-function variable (name value env index . opt-type)
  (let ((self (new <variable>)))
    (set (<variable>-name  self) name)
    (set (<variable>-value self) value)
    (set (<variable>-env   self) env)
    (set (<variable>-index self) index)
    (set (<variable>-type  self) (car opt-type))
    self))

(define-function environment (parent)
  (let ((self (new <env>)))
    (set (<env>-parent   self) parent)
    (set (<env>-level    self) (<env>-level  parent))
    (set (<env>-offset   self) (<env>-offset parent))
    (set (<env>-bindings self) (array))
    self))

(define-function environment-define (env name value)
  (let* ((bindings (<env>-bindings env))
         (offset   (<env>-offset   env))
         (var      (variable name value env offset)))
    (set (<env>-offset env) (+ offset 1))
    (array-append bindings var)))

(define-function environment-find (env name)
  (let* ((bindings (<env>-bindings env))
         (offset   (<env>-offset   env))
         (var      ())
         (idx      0))
    (while (and (not var) (< idx offset))
      (if (= name (<variable>-name (array-at bindings idx)))
          (set var (array-at bindings idx))
        (set idx (+ idx 1))))
    var))

(define-function global? (var)        (= 0 (<env>-level (<variable>-env var))))

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

;;; selector/method (single dispatch on the type of the first argument)

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
  (or default (set default `(args (error "cannot apply selector '"',name
                                         "' to type '"(array-at %type-names (type-of (car args)))
                                         "': "(cons (car args) (map name-of-type (map type-of (cdr args))))))))
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

(define-selector do-print (arg) (primitive/print arg))
(define-selector do-dump  (arg) (do-print arg))

(define print
  (lambda args
    (while (pair? args)
      (do-print (car args))
      (set args (cdr args)))
    (car args)))

(define dump
  (lambda args
    (while (pair? args)
      (do-dump (car args))
      (set args (cdr args)))
    (car args)))

(define println
  (lambda args
    (apply print args)
    (primitive/print "\n")
    (car args)))

(define dumpln
  (lambda args
    (apply dump args)
    (primitive/print "\n")
    (car args)))

(define-method do-dump  <string> ()     (primitive/dump self))
(define-method do-dump  <array> ()      (primitive/dump self))
(define-method do-print <selector> ()   (print "<selector "(<selector>-name self)">"))

(define-method do-print <pair> ()
  (print "(")
  (while self
    (if (pair? self)
        (print (car self))
        (let ()
          (print ". ")
          (print self)))
    (if (set self (cdr self))
        (print " ")))
  (print ")"))

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

;;; generic/multimethod (dispatch on the type of all arguments)

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

(define-function member? (key list)
  (while (and (pair? list) (!= key (car list)))
    (set list (cdr list)))
  (car list))

(define-function list-reverse! (head)
  (let ((curr head)
        (prev ())
        (next ()))
    (while curr
      (set next (cdr curr))
      (set-cdr curr prev)
      (set prev curr)
      (set curr next))
    prev))

(define-function zip lists
  (apply map list lists))

(define-function zip-assocs (a b)
  (if (and (pair? a) (pair? b))
      (cons (cons (car a) (car b)) (zip-assocs (cdr a) (cdr b)))
    (or a b)))

;;; iteration

(define-form for (var-init-limit-step . body)
  (let ((var       (car    var-init-limit-step)    )
        (init      (cadr   var-init-limit-step)    )
        (limit     (caddr  var-init-limit-step)    )
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

(define-function array->string (arr lim)
  (let ((ind 0)
        (str (string lim)))
    (while (< ind lim)
      (set-string-at str ind (array-at arr ind))
      (set ind (+ 1 ind)))
    str))
