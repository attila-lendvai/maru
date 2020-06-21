;;; This is the minimum "standard library" that is needed/used while bootstrapping

(if bootstrapping?
    (warn "boot.l speaking; we're in bootstrapping mode\n"))

(if bootstrapping?
    (let ()
      (define *command-line-arguments* '())
      (define *verbosity* 0)
      (define *optimised* 1)))

(if (> *optimised* 0)
    (warn "boot.l speaking; we're in optimised mode\n"))

(define unit-testing? '(t))

(define list (lambda args args))

(define primitive/print print)
(define primitive/dump  dump)

(define error)

(define error/nested/2
  (lambda args
    (set error abort) ; let's give up in case of more recursive errors
    (primitive/print "\nNESTED ERROR LEVEL 2: ")
    (apply primitive/print args)
    (primitive/print "\n")
    (abort)))

(define error/nested/1
  (lambda args
    (set error error/nested/2)
    (primitive/print "\nNESTED ERROR LEVEL 1: ")
    (apply primitive/print args)
    (primitive/print "\n")
    (abort)))

(set error
  (lambda args
    (set error error/nested/1) ; in case a nested error happens while reporting
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
      (lambda (env expr)
        (qq-object expr)))))

(define define-form (form (lambda (env name args . body)
                            `(define ,name (form (lambda (*env* ,@args) ,@body))))))

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
  `(define ,name (form () (lambda args ',value))))

(define-form define-function (name args . body)
  `(define ,name (lambda ,args ,@body)))

(define-form define-macro (name args . body)
  `(define-form ,name ,args (cons 'let (cons () (macro-expand (zip-assocs ',args (list ,@args)) ',body)))))

(define-function macro-expand (bindings exp)
  (if (pair? exp)
      (cons (macro-expand bindings (car exp))
            (macro-expand bindings (cdr exp)))
    (if (symbol? exp)
        (let ((a (assq exp bindings)))
          (if a (cdr a) exp))
      exp)))

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

(define-function %let*getters (vars getter rest)
  (if (pair? vars)
      (cons (list (car vars) (list 'car getter))
            (%let*getters (cdr vars) (list 'cdr getter) rest))
    (if (symbol? vars)
        (cons (list vars getter) rest)
      rest)))

(define-function %let*unpack (vars val rest)
    (cons (cons '_%let_values_ val)
          (%let*getters vars '_%let_values_ rest)))

(define-function %let*bindings (bindings)
  (if (pair? bindings)
      (let ((var     (caar bindings))
            (val     (cdar bindings)))
        (if (pair? var)
            (%let*unpack var val (%let*bindings (cdr bindings)))
          (cons (cons var val) (%let*bindings (cdr bindings)))))))

(define-function %let* (bindings body)
  (if (pair? (cdr bindings))
      `(let (,(car bindings)) ,(%let* (cdr bindings) body))
    `(let ,bindings ,@body)))

(define-form let* bindings-body
  (%let* (%let*bindings (car bindings-body)) (cdr bindings-body)))

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
(define %structure-bases	(array))
(define %structure-derivatives	(array))

(define-function structure-field-count (type)
  (assert (<= type %last-type) "structure-field-count for undefined type " type)
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

;; TODO naming? fields-of-structure? or type-field-count above?
(define-function fields-of-type (type)
  (array-at %structure-fields type))

(define-function sanity-check-structure-fields (name fields)
  (let ((f fields))
    (while (pair? f)
      (and (memq (car f) (cdr f))
           (error "field '"(car f)"' multiply-defined in structure: "name" "fields))
      (set f (cdr f)))))

(define-function inherits-from (type base)
  (and type
       (or (= type base)
           (inherits-from (array-at %structure-bases type) base))))

(define-function %typecheck (type object)
  (or (= type (type-of object))
      (inherits-from (type-of object) type)
      (error "type check failed for field accessor: expected "
             type" "(name-of-type type)", got "
             (type-of object)" "(name-of-type (type-of object))))
  object)

(define-function %accessor (name)
  ;; KLUDGE? TODO understand and reinstate?
  ;; (if (= ?_ (string-at (symbol->string name) 0))
  ;;     'long-at
  ;;   'oop-at)
  'oop-at)

(define %make-accessor) ;; forward

(define-function %make-safe-accessor (name fields offset)
  (if fields (cons `(define-form ,(concat-symbol name (concat-symbol '- (car fields))) (self)
                      (list ',(%accessor (car fields))
                            (list '%typecheck ',name self)
                            ,offset))
                   (%make-accessor name (cdr fields) (+ 1 offset)))))

(define-function %make-unsafe-accessor (name fields offset)
  (if fields (cons `(define-form ,(concat-symbol name (concat-symbol '- (car fields))) (self)
                      (list ',(%accessor (car fields))
                            self
                            ,offset))
                   (%make-accessor name (cdr fields) (+ 1 offset)))))

(set %make-accessor (if (> *optimised* 0)
                        %make-unsafe-accessor
                      %make-safe-accessor))

(define-function %make-accessors (name fields)
  (%make-accessor name fields 0))

(define-form define-structure (name fields)
  (let ((type (%allocate-type name))
        (field-count (list-length fields)))
    (sanity-check-structure-fields name fields)
    (set-array-at %structure-field-counts type field-count)
    (set-array-at %structure-fields       type fields)
    `(let ()
       (define ,name ,type)
       ,@(%make-accessors name fields)
       ,type)))

(define-form new (type . inits)
  (let ((i -1))
    `(let* ((_type_ ,type)
            (_self_ (allocate _type_ (structure-field-count _type_))))
       ,@(map (lambda (_init_) (list 'set-oop-at '_self_ (set i (+ i 1)) _init_)) inits)
       _self_)))

(define-function %make-make-inits (prefix inits)
  (and inits
       (cons (list 'set (list (concat-symbol prefix (caar inits)) 'self) (cadar inits))
             (%make-make-inits prefix (cdr inits)))))

(define-form make (type . inits)
  `(let ((self (new ,type)))
     (with-instance-accessors ,type
       ,@(%make-make-inits (concat-symbol type '-) inits)
       self)))

;;; built-in types

;; NOTE: the subr's in eval.l assume a certain layout for the built-in types.
;; what actually happens is encoded in eval.l, and the define-structure forms
;; for the built-in types in boot.l merely fill in some missing parts. types
;; are represented internally as successive integers.
;; corollary: the two files must agree, both in the order and in the field layout.
(define-structure <undefined>   ()) ; NOTE: it doesn't need to be the first one (to be denoted by 0 at runtime)
(define-structure <long>        (_bits))
(define-structure <string>      (size _bits))
(define-structure <symbol>      (_bits))
(define-structure <pair>        (head tail))
(define-structure <_array>      ())
(define-structure <array>       (size _array))
(define-structure <expr>        (name defn ctx))        ; NOTE: defn is: (env formals . prog)
(define-structure <form>        (function symbol))      ; these are expander lambda's
(define-structure <fixed>       (function))
(define-structure <subr>        (_name _imp _sig _profile))
(define-structure <variable>	(name value env index type))
(define-structure <env>		(parent level offset bindings stable))
(define-structure <context>	(home env bindings callee pc))
(define-structure <module>      (symbols globals)) ; globals is the <variable> that holds '*globals*

(define-function long?		(obj)	(= <long>	(type-of obj)))
(define-function expr?		(obj)	(= <expr>	(type-of obj)))
(define-function variable?	(obj)	(= <variable>	(type-of obj)))

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

(define-function global-variable? (var)        (= 0 (<env>-level (<variable>-env var))))

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

(define-function selector? (obj) (= <selector> (type-of obj)))

(define-function <selector>-inherit (methods type)
  (let ((method ())
        (probe  type))
    (while (and (set probe (array-at %structure-bases probe))
                (not (set method (array-at methods probe)))))
    ;; (and method (set (array-at methods type) method))	; copy down the method for performance
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
  (and (expr? method)
       (or (<expr>-name method)
           (set (<expr>-name method)
                (concat-symbol (array-at %type-names type) (concat-symbol '. (<selector>-name self))))))
  (set-array-at (<selector>-methods self) type method))

(define-form define-selector (name . default)
  (assert (symbol? name) "define-selector: name is not a symbol")
  (let ((var (defined? name)))
    (if var
        (if (selector? (<variable>-value var))
            (list 'quote <variable>-value var)
          (error name" is already defined as non-selector: " (<variable>-value var)))
      (let ()
        (or default (set default `(args (error "selector '"',name
                                               "' has no method for "(type-name-of (car args))
                                               ": "(cons (car args) (map type-name-of (cdr args)))))))
        `(define ,name (selector ',name (lambda ,@default)))))))

(define-selector add-method)

(<selector>-add-method add-method <selector>
  (lambda (self type args body)
    (<selector>-add-method self type (eval `(lambda ,args (with-instance-accessors ,type ,@body))))))

(define-form define-method (selector type args . body)
  (or (defined? selector) (eval `(define-selector ,selector)))
  `(add-method ,selector ,type ',(cons 'self args) ',body))

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

(define-method do-dump <pair> ()
  (if (= *globals* (cdr self)) ;; TODO is this still needed?
      (print "*globals*")
    (let ()
      (print "(")
      (while self
        (if (pair? self)
            (dump (car self))
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
      (dump arg))
    found))

;; (define *backtrace*
;;   (lambda (stack depth)
;;     (let ((posn (array)))
;;       (while (>= (set depth (- depth 1)) 0)
;;         (let ((here (array-at stack depth)))
;;           (print "  " depth "\t")
;;           (dump-until posn here)
;;           (print "\n")
;;           (set posn here))))
;;     (exit 0)))

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
    (or (defined? method) (eval (list 'define-generic method)))
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

;;; sequences

(define-method length <string> ()		(string-length self))
(define-method length <array> ()		(array-length self))

(define-method at <string> (index)		(string-at self index))
(define-method at <array> (index)		(array-at self index))

(define-method set-at <string> (index value)	(set-string-at self index value))
(define-method set-at <array> (index value)	(set-array-at self index value))

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
       (let* ((,var (car _list_))) ,@body) ; let* allows (list-do (vars...) list-of-lists)
       (set _list_ (cdr _list_)))))

(define-form alist-do (var alist . body)
  `(let ((_list_ ,alist))
     (while _list_
       (let*  ((,var (cdar _list_))) ,@body)
       (set _list_ (cdr _list_)))))

(define-function %generic-do (get len var col body)
  `(let* ((_col_ ,col)
          (_idx_ 0)
          (_end_ (,len _col_)))
     (while (< _idx_ _end_)
       (let* ((,var (,get _col_ _idx_))) ,@body)
       (set _idx_ (+ _idx_ 1)))))

(define-form array-do (var arr . body)	(%generic-do array-at array-length var arr body))

(define-form string-do (var str . body)	(%generic-do string-at string-length var str body))

(define-method for-each <pair>   (function)	(list-do   _elt_ self (function _elt_)))
(define-method for-each <array>  (function)	(array-do  _elt_ self (function _elt_)))
(define-method for-each <string> (function)	(string-do _elt_ self (function _elt_)))

(define-function for-each-with (collection function value)
  (for-each collection (lambda (x) (function x value))))

(define-form incr (lval . options)	`(set ,lval (+ ,lval ,(or (car options) 1))))
(define-form decr (lval . options)	`(set ,lval (- ,lval ,(or (car options) 1))))

(define-form until (condition . body)
  `(while (not ,condition) ,@body))

(define-form list-detect (name list expr)
  `(let ((_ ())
         (__ ,list))
     (while (and __ (not _))
       (let* ((,name (car __)))
         (and ,expr (set _ (car __)))
         (set __ (cdr __))))
     _))

(define-form array-detect (name arr expr)
  `(let* ((_ ())
          (_a ,arr)
          (_l (array-length _a)))
     (for (_i 0 _l)
       (let ((,name (array-at _a _i)))
         (and ,expr (let () (set _ ,name) (set _i _l)))))
     _))

(define-function %loop-inits (bindings)
  (and bindings
       (cons (list (caar bindings) (cadar bindings))
             (%loop-inits (cdr bindings)))))

(define-function %loop-steps (bindings)
  (and bindings
       (cons (list 'set (caar bindings) (caddar bindings))
             (%loop-steps (cdr bindings)))))

(define-form loop (bindings test . body)
  `(let ,(%loop-inits bindings)
     (while ,test
       ,@body
       ,@(%loop-steps bindings))))

;;; conversion

(define-function string->number-base (str radix)
  (let ((n 0)
        (i 0)
        (l (string-length str))
        (s 1))
    (while (and (< i l) (= ?- (string-at str i)))
      (set s (- s))
      (set i (+ i 1)))
    (while (< i l)
      (let* ((c (string-at str i))
             (d (cond
                  ((and (<= ?0 c) (<= c ?9))	      (- c ?0) )
                  ((and (<= ?A c) (<= c ?Z))	(+ 10 (- c ?A)))
                  ((and (<= ?a c) (<= c ?z))	(+ 10 (- c ?a)))
                  (else				radix          ))))
        (if (< d radix)
            (let ()
              (set n (+ (* radix n) d))
              (set i (+ i 1)))
          (set l i))))
    (* s n)))

(define-function string->number (str)
  (string->number-base str 10))

(define-function array->string (arr lim)
  (let ((ind 0)
        (str (string lim)))
    (while (< ind lim)
      (set-string-at str ind (array-at arr ind))
      (set ind (+ 1 ind)))
    str))

(define-function array->list (arr)
  (let* ((ind (array-length arr))
         (lst ()))
    (while (<= 0 (set ind (- ind 1)))
      (set lst (cons (array-at arr ind) lst)))
    lst))

(define-function list->string (list)
  (let* ((len (list-length list))
         (str (string len))
         (idx 0))
    (while (< idx len)
      (set-string-at str idx (car list))
      (set idx (+ idx 1))
      (set list (cdr list)))
    str))

(define-function character->string (c)
  (let ((s (string 1)))
    (set-string-at s 0 c) s))

(define-function array-append-all (a s)
  (string-do e s (array-append a e))
  s)

;;; sorting and searching

(define-function %partition (items at set-at compare left pivot right)
  (let ((index left)
        (value (at items pivot)))
    (set-at items pivot (at items right))
    (set-at items right value)
    (for (i left right)
      (and (compare (at items i) value)
           (let ((item (at items i)))
             (set-at items i (at items index))
             (set-at items index item)
             (set index (+ index 1)))))
    (set value (at items index))
    (set-at items index (at items right))
    (set-at items right value)
    index))

(define-function %sort (items at set-at compare left right)
  (and (< left right)
       (let* ((pivot (/ (+ left right) 2))
              (index (%partition items at set-at compare left pivot right)))
         (%sort items at set-at compare left (- index 1))
         (%sort items at set-at compare (+ index 1) right))))

(define-function array-sort (items . options)
  (%sort items array-at set-array-at (or (car options) <) 0 (- (array-length items) 1))
  items)

(define-function string-sort (items . options)
  (%sort items string-at set-string-at (or (car options) <) 0 (- (string-length items) 1))
  items)

(define-function %search (items length at obj compare)
  (let ((lo 0)
        (hi (- (length items) 1))
        (ix ()))
    (while (<= lo hi)
      (let* ((m (/ (+ lo hi) 2))
             (s (at items m))
             (c (compare obj s)))
        (cond
          ((< c 0)	(set hi (- m 1)))
          ((> c 0)	(set lo (+ m 1)))
          (else		(let () (set ix m) (set lo (+ hi 1)))))))
    ix))

(define-function array-search  (arr obj . options)	(%search arr array-length  array-at  obj (or (car options) -)))
(define-function string-search (str obj . options)	(%search str string-length string-at obj (or (car options) -)))

(define-function max (a . rest)	(list-do b rest (set a (if (> b a) b a))) a)
(define-function min (a . rest)	(list-do b rest (set a (if (< b a) b a))) a)
(define-function sum (a . rest)	(list-do b rest (incr a b)) a)

(define-function align (value alignment)	(& (+ value (- alignment 1)) (- alignment)))

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

(define-form define-namespace (name parent)	`(define ,name (environment ,parent)))

(define-form namespace (name)			`(set *globals* ,name))

;;; command line

(define *load-path*)

(and (= "-L" (car *command-line-arguments*))
     (let ()
       (pop *command-line-arguments*)
       (set *load-path* (pop *command-line-arguments*))))

;; TODO rename
(define-form next-argument () '(pop *command-line-arguments*))

;;; load/save

(define-function pval (expr)
  (and (> *verbosity* 0) (println expr))
  (let ((result (eval expr)))
    (and (> *verbosity* 1) (println "=> "result))
    result))

;; (define-function find-and-read (name)
;;   (or (and *load-path* (read (concat-string *load-path* name)))
;;       (read name)))

;; (define-function load (name)
;;   (let ((exps (find-and-read name)))
;;     (or exps (error "file not found or empty: "name))
;;     (list-do expr exps (pval expr))))

(define *loaded*)

;; (define-function require (name)
;;   (or (member? name *loaded*)
;;       (let ()
;;         (push *loaded* name)
;;         (load name))))

;; (define-function contents-to-file-named (string path . options)
;;   (let ((f (or (open path "w")
;;                (error "cannot open for writing: "path)))
;;         (p (or (car options) putc)))
;;     (for (i 0 (length string)) (p (at string i) f))
;;     (close f)))

;; (define-function contents-of-file-named (path)
;;   (let ((f (or (open path)
;;                (error "cannot open for reading: "path)))
;;         (s (array))
;;         (c))
;;     (while (set c (getc f))
;;       (array-append s c))
;;     (close f)
;;     (array->string s)))
