;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is the minimum "standard library" that is needed/used while bootstrapping
;;;

;; NOTE define is implemented so that it unconditionally defines the variable
;; at expand time, therefore we need to "hide" it inside a quote.
(if (not (defined? 'bootstrapping?))
    (eval '(define bootstrapping? ())))

(if (not (defined? 'evolving?))
    (eval '(define evolving? ())))

(if bootstrapping?
    (let ()
      (warn "boot.l speaking; we're bootstrapping")
      (if evolving?
          (warn "; we're evolving"))
      (warn "\n")))

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
      (while (set args (cdr args))
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

;; this is very similar in effect to read-time evaluation in CL, aka #.(foo)
(define-form eval-at-expand body
  (eval `(let () ,@body)))

(define-form if-at-expand (cond true-form false-form)
  (if (eval cond)
      true-form
    false-form))

(define-form when-at-expand (cond . true-forms)
  (if (eval cond)
      `(let ()
         ,@true-forms)))

(define-form when (test . body)
  `(and ,test (let () ,@body)))

(define-form awhen (test . body)
  `(let ((it ,test))
     (when it
       ,@body)))

(define-form unless (test . body)
  `(or ,test (let () ,@body)))

(define-form assert (test . args)
  (unless args
    (set args (list "assertion failed: " `(quote ,test))))
  `(or ,test (error ,@args)))

(define-form define-constant (name value)
  `(define ,name (form () (lambda _ ,value))))

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

;;; list

(define-function first	(list)	(car list))
(define-function second	(list)	(cadr list))
(define-function third	(list)	(caddr list))

(define-function rest	(list)	(cdr list))

(define-function list-length (list)
  (assert (or (not list) (pair? list)) "LIST-LENGTH called with an improper list: " list)
  (if (pair? list)
      (let ((len 1))
        (while (set list (cdr list))
          (set len (+ len 1)))
        len)
    0))

(define-form push (list element)
  `(set ,list (cons ,element ,list)))

(define-form pop (list)
  `(let* ((_list_ ,list)
          (_head_ (car _list_)))
     (set ,list (cdr _list_))
     _head_))

(define-function member? (key list)
  (while (and (pair? list) (!= key (car list)))
    (set list (cdr list)))
  (car list))

(define-function list-reverse (lst)
  (let ((result ()))
    (while (pair? lst)
      (push result (pop lst)))
    result))

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

(define-function zip lists
  (apply map list lists))

(define-function zip-assocs (a b)
  (if (and (pair? a) (pair? b))
      (cons (cons (car a) (car b)) (zip-assocs (cdr a) (cdr b)))
    (or a b)))

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

;;; basic iteration

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

(define-form times-do (count . body)
  `(for (__i__ 0 ,count)
     ,@body))

(define-function %generic-do (get len var col body)
  `(let* ((_col_ ,col)
          (_idx_ 0)
          (_end_ (,len _col_)))
     (while (< _idx_ _end_)
       (let* ((,var (,get _col_ _idx_))) ,@body)
       (set _idx_ (+ _idx_ 1)))))

(define-form array-do	(var arr . body)	(%generic-do array-at  array-length  var arr body))
(define-form string-do	(var str . body)	(%generic-do string-at string-length var str body))

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

;; TODO use key-var value-var instead?
;; (define-form alist-do (var alist . body)
;;   `(let ((_list_ ,alist))
;;      (while _list_
;;        (let*  ((,var (cdar _list_))) ,@body)
;;        (set _list_ (cdr _list_)))))

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

;;; math

(define-form incr (lval . options)	`(set ,lval (+ ,lval ,(or (car options) 1))))
(define-form decr (lval . options)	`(set ,lval (- ,lval ,(or (car options) 1))))

(define-function max (a . rest)	(list-do b rest (set a (if (> b a) b a))) a)
(define-function min (a . rest)	(list-do b rest (set a (if (< b a) b a))) a)
(define-function sum (a . rest)	(list-do b rest (incr a b)) a)

(define-function align (value alignment)	(& (+ value (- alignment 1)) (- alignment)))

;;;
;;; types
;;;
;;;
;;; type-id-of: returns the type-id that the target VM is working with,
;;; i.e. the "level-shifted name" of the type (an integer).
;;;
;;; type-of: returns a maru record holding the metadata for that type
;;; (i.e. its name, type-id, etc).
;;;
;;; the <foo> global definitions are also holding full maru type objects.
;;;
;;; NOTE we store the extra type id in a slave-id slot (as opposed to
;;; a host-id slot) so that most things in the host keeps working
;;; because <type>-id of a slave type instance returns the host type id.

(define type-id-of type-of) ; we will replace type-of later

(define %first-type-id		1) ; i.e. the first allocated type will be 1 (so that we can assert for non-zero type in the gc)
(define %last-type-id		(- %first-type-id 1))
(define %types			(array 16))

(define-form types-do (var . body)
  `(for (__i__ %first-type-id %last-type-id)
     (let ((,var (array-at %types __i__)))
       ,@body)))

(if-at-expand bootstrapping?
    (let ()
      (define %type-id-map/host->slave (array 16))

      ;; allocate-type-id is defined in bootstrapping/early.l to allocate a type id from the host
      (define-function allocate-type-id/slave ()
        (incr %last-type-id)))

  (define-function allocate-type-id ()
    (incr %last-type-id)))

(define *force-trivial-accessors* '()) ; expand to only a single oop-at, which is understood by the compiler

(define-function %make-accessor (type-id type-name slot-names offset typecheck?)
  (let ((slot-name (car slot-names)))
    `(define-form ,(concat-symbol type-name (concat-symbol '- slot-name)) (obj)
       (if (and ',typecheck?
                (not *force-trivial-accessors*))
           (list 'slot-value ',type-id '',slot-name obj ,offset)
         (list 'oop-at obj ,offset)))))

(define-function %make-accessors (type-id type-name slot-names offset typecheck?)
  (when slot-names
    (cons (%make-accessor  type-id type-name slot-names offset typecheck?)
          (%make-accessors type-id type-name (cdr slot-names) (+ 1 offset) typecheck?))))

;; KLUDGE forward definitions to avoid the need for excessinve use of eval for the conditional bootstrap stuff
(define <type>-slave-id)
(define set-<type>-slave-id)

;; these are internal stuff needed for the bootstrap
(define type-id-of-<type>		(allocate-type-id))
(define type-id-of-<record>		(allocate-type-id))
(define slots-of-<type>			(concat-list '(id name) (when bootstrapping? '(slave-id))))
(define slots-of-<record>		'(super direct-slots effective-slots))

;; define non-typechecking accessors for <type> and <record> to help us while we instantiate these two types.
(eval `(let ()
         ,@(%make-accessors type-id-of-<type>	'<type>		slots-of-<type>		0				())
         ,@(%make-accessors type-id-of-<record>	'<record>	slots-of-<record>	(list-length slots-of-<type>)	())))

(assert <type>-name)

(define-function register-type (type)
  (if-at-expand bootstrapping?
      ;; while bootstrapping we instantiate types in the host (so that we can use e.g. method dispatch),
      ;; and keep an additional host->slave map and a slave-id slot.
      (let ((slave-id (allocate-type-id/slave)))
        (set (array-at %type-id-map/host->slave (<type>-id type)) slave-id)
        (set (<type>-slave-id type) slave-id)
        (set (array-at %types slave-id) type)
        (register-type/host type))
    (set (array-at %types (<type>-id type)) type)))

(define-function %bootstrap-type (type-name type-id type-type-id slot-count)
  (let ((type-obj (allocate type-type-id slot-count)))
    (set (<type>-id	type-obj)	type-id)
    (set (<type>-name	type-obj)	type-name)
    (register-type type-obj)
    (eval `(define ,type-name ,type-obj))
    type-obj))

(define-function %bootstrap-record (type-name type-id super direct-slots)
  (let ((type-obj (%bootstrap-type type-name type-id type-id-of-<record> (+ (list-length slots-of-<type>)
                                                                            (list-length slots-of-<record>)))))
    (set (<record>-super		type-obj)		super)
    (set (<record>-direct-slots		type-obj)		direct-slots)
    (set (<record>-effective-slots	type-obj)		'not-yet-bootstrapped)))

(%bootstrap-record '<type>		type-id-of-<type>	()	slots-of-<type>)	(when (< 0 *verbosity*) (warn "<type> is bootstrapped: " <type> "\n"))
(%bootstrap-record '<record>		type-id-of-<record>	<type>	slots-of-<record>)	(when (< 0 *verbosity*) (warn "<record> is bootstrapped: " <record> "\n"))

(assert (or (not bootstrapping?)
            (and (> (<type>-id <type>) 5)   (> (type-id-of <type>) 5)
                 (> (<type>-id <record>) 5) (> (type-id-of <record>) 5)
                 (= (type-id-of <type>) (<type>-id <record>)))))

(define-function type-object-for (type-id)
  (or (array-at %types (if-at-expand bootstrapping?
                           (let ((slave-id (array-at %type-id-map/host->slave type-id)))
                             ;; we could make this smarter and only do the remap when there's an entry...
                             ;; but do we want to? wouldn't that hide some nasty bugs?
                             (assert slave-id "type-object-for: no host->slave mapping exists for host type-id: " type-id)
                             slave-id)
                         type-id))
      (error "type-object-for has failed for type id "type-id", known types are: "%types)))

(define-function type-of (obj)
  (type-object-for (type-id-of obj)))

(define-function name-of-type (type)
  (<type>-name type))

(define-function type-name-of (obj)
  (name-of-type (type-of obj)))

(define-function record-inherits-from? (type super)
  (and type
       (or (= type super)
           (record-inherits-from? (<record>-super type) super))))

(define-function subtype? (subtype supertype)
  (assert (and subtype supertype))
  (or (= subtype supertype)
      (and (subtype? (type-of subtype) <record>)
           (record-inherits-from? subtype supertype))))

(assert (subtype? (type-of <type>) <record>))
(assert (subtype? <record> <type>))

;; now that <type> and <record> is instantiated, we can implement type checking in the accessors.
;; let's also redefine the basic accessors that we have defined earlier.
(define-function %accessor-typecheck (expected-type-id slot-name object)
  (unless (= (type-id-of object) expected-type-id)
    (let ((expected-type (type-object-for expected-type-id))
          (actual-type (type-of object)))
      (unless (subtype? actual-type expected-type)
        ;; (warn "about to process an %accessor-typecheck failure, which may fail to properly print the error output\nslot name is "slot-name", expected-type-id is "expected-type-id", object's actual type id is "(type-id-of object)"\n")
        (error "type check failed for record slot accessor: expected type "expected-type", slot name "slot-name", got " actual-type)))))

(define-function slot-value (expected-type-id slot-name object offset)
  (%accessor-typecheck expected-type-id slot-name object)
  (oop-at object offset))

(define-function set-slot-value (expected-type-id slot-name object offset value)
  (%accessor-typecheck expected-type-id slot-name object)
  (set-oop-at object offset value))

(define-function sanity-check-record-slots (record slots)
  (let ((f slots))
    (while (pair? f)
      (and (memq (car f) (cdr f))
           (error "slot '"(car f)"' multiply-defined in record: "record" "slots))
      (set f (cdr f)))))

(define-function %record/compute-effective-slots (type)
  (and type
       (concat-list (%record/compute-effective-slots (<record>-super type))
                    (<record>-direct-slots type))))

(define-function record/compute-effective-slots (type)
  ;;(print "record/compute-effective-slots for type " (<type>-name type) " of type " (<type>-name (type-of type)) " ?= <record>" (= type <record>) "\n") ; TODO delme
  (assert (subtype? (type-of type) <record>) "record/compute-effective-slots called with a non-record type " type)
  (let ((slots (%record/compute-effective-slots type)))
    (sanity-check-record-slots type slots)
    slots))

(set (<record>-effective-slots <type>)		(record/compute-effective-slots <type>))
(set (<record>-effective-slots <record>)	(record/compute-effective-slots <record>))

(assert (equal slots-of-<type> (<record>-effective-slots <type>)))
(assert (equal (concat-list slots-of-<type> slots-of-<record>) (<record>-effective-slots <record>)))

(define-function record/effective-slot-count (type)
  (list-length (<record>-effective-slots type)))

(define-function type/slot-count-of-instances (type)
  (cond
    ((subtype? (type-of type) <record>)	(record/effective-slot-count type))
    ((subtype? (type-of type) <type>)	0)
    (else				(error "type/slot-count-of-instances: called with something unexpected: " type))))

(define-function %make-record-accessors (type)
  (assert (subtype? (type-of type) <record>) "%make-record-accessors called with a non-record type " type)
  (%make-accessors (<type>-id type)
                   (<type>-name type)
                   (<record>-direct-slots type)
                   (or (and (<record>-super type)
                            (record/effective-slot-count (<record>-super type)))
                       0)
                   (= 0 *optimised*)))

;; redefine the preliminary bootstrap accessors with full featured ones
(eval `(let ()
         ,@(%make-record-accessors <type>)
         ,@(%make-record-accessors <record>)))

(when (< 0 *verbosity*) (warn "type bootstrap finished\n"))

;;; at this point the type registry is bootstrapped, containing two types: <type> and <record>

(assert (= (type-of <type>)	<record>))
(assert (= (type-of <record>)	<record>))

(assert (= (if bootstrapping? 3 2) (list-length (<record>-effective-slots <type>))))
(assert (= (+ 3 (list-length (<record>-effective-slots <type>))) (list-length (<record>-effective-slots <record>))))

(define-function new-type-instance (name type)
  (assert (subtype? type <type>))
  (let ((id (allocate-type-id))
        (result (allocate (<type>-id type) (type/slot-count-of-instances type))))
    (set (<type>-name	result) name)
    (set (<type>-id	result) id)
    (register-type result)
    result))

(define-function new-<type> (name)
  (new-type-instance name <type>))

(define-form define-type (name)
  (let ((type (new-<type> name)))
    ;; TODO we want this to be defined already when the upcoming forms get expanded. but it feels like a kludge...
    (eval `(define ,name ,type))
    `(define ,name ,type)))

(define-function new-<record> (name super slots)
  (assert (or (not super) (and (not (pair? super)) (subtype? (type-of super) <record>))))
  (let ((type (new-type-instance name <record>)))
    (set (<record>-super		type) super)
    (set (<record>-direct-slots		type) slots)
    (set (<record>-effective-slots	type) (record/compute-effective-slots type))
    type))

(define-form define-record (name super slots)
  (let ((record-type (new-<record> name (eval super) slots)))
    (eval `(define ,name ,record-type))
    `(let ((type-obj ,record-type))
       (define ,name type-obj)
       ,@(%make-record-accessors record-type)
       type-obj)))

;;; immediate type

(define-record <immediate-type> <type> (tag-value tag-width))

(define-function new-<immediate-type> (name tag-value tag-width)
  (assert (and (< 0 tag-width) (< 0 tag-value)) "new-<immediate-type>: illegal tag-width or tag-value for type " name)
  (let ((type (new-type-instance name <immediate-type>)))
    (set (<immediate-type>-tag-value	type) tag-value)
    (set (<immediate-type>-tag-width	type) tag-width)
    type))

(define-form define-immediate-type (name tag-width tag-value)
  `(define ,name ,(new-<immediate-type> name (eval tag-width) (eval tag-value))))

(define-function immediate-type? (type)
  (subtype? (type-of type) <immediate-type>))

;;; classes

(define-form define-class (name basis fields)
  ;; TODO source-level compatibility. decide whether to delme.
  ;; TODO accessor regression: there used to be <peg>-result, now there's only a <parser>-result (inheritance)
  `(define-record ,name ,basis ,fields))

;;; built-in types

;; NOTE: the subr's in eval.l assume a certain layout for the built-in types.
;; what actually happens is encoded in eval.l, and the define-record forms
;; for the built-in types in boot.l merely fill in some missing parts. types
;; are represented internally as successive integers.
;; corollary: the two files must agree, both in the order and in the field layout.

;; TODO maybe: type objects should be serialized into the compiled binary and this
;; should be wrapped in a big (eval-at-expand (if bootstrapping? ...)). this would also
;; reflect the fact that editing these and bringing it out of sync with the
;; level-shifted binary is not an option without grave consequences.
;; such a setup would hopefully simplify the bootstrapping dance above
(define-type		<undefined>)				; NOTE: it doesn't need to be the first one (i.e. to be denoted by 0 in the target at runtime)
(define-type		<data>)					; some blob; used for stuff like the _bits of <string> and <array>
(define-immediate-type	<long> 1 1)
;(define-record <long>			() (_bits))		; bootstrap is about 25% slower
(define-record <array>			() (size _bits))
(define-record <string>			() (size _bits))
(define-record <expr>			() (name defn ctx))        ; TODO: defn is: (env formals . prog), parse it into separate slots? name is informal for debugging purposes.
(define-record <form>			() (function symbol))      ; these are expander lambda's
(define-record <fixed>			() (function))
(define-record <subr>			() (_name _imp _sig _profile))
(define-record <variable>		() (name value env index))
(define-record <env>			() (parent level offset bindings stable))
(define-record <context>		() (home env bindings callee pc))
(define-record <module>			() (symbols globals)) ; globals is the <variable> that holds '*globals*
(define-record <target-vm-pointer>	() (_bits))		; a pointer into the level-shifted realm, wrapped up, so that it can be stored in the maru heap
(define-record <symbol>			() (_bits))
(define-record <pair>			() (head tail))

(define-function long?		(obj)	(= <long>	(type-of obj)))
(define-function expr?		(obj)	(= <expr>	(type-of obj)))
(define-function variable?	(obj)	(= <variable>	(type-of obj)))

(when-at-expand bootstrapping?
  ;; let's map the following host types to their respective slave equivalents
  ;; so that type-of on one of their instances will return the slave type object.
  ;; this is mainly needed to interact with the data that the host's reader returns
  ;; e.g. to be able to specialize methods on them while in the bootstrap process.
  (list-do entry `(("" ,<string>) (42 ,<long>) (t ,<symbol>) ((1) ,<pair>))
    (apply (lambda (instance type)
             (set (array-at %type-id-map/host->slave (type-id-of instance))
                  (<type>-slave-id type))
             (assert (= (type-of instance) type)))
           entry))
  ;; (print %type-id-map/host->slave "\n" %types "\n")
  )

;; KLUDGE fake defunct slot accessors for source position to remain compatible
(define-function <pair>-source (x) ())
(define-function set-<pair>-source (x pos) pos)

;; (define-function environment-find (env name)
;;   (let* ((bindings (<env>-bindings env))
;;          (offset   (<env>-offset   env))
;;          (var      ())
;;          (idx      0))
;;     (while (and (not var) (< idx offset))
;;       (if (= name (<variable>-name (array-at bindings idx)))
;;           (set var (array-at bindings idx))
;;         (set idx (+ idx 1))))
;;     var))

(define-function global-variable? (var)        (= 0 (<env>-level (<variable>-env var))))

(define-form define-expand (type args . body)   `(set-array-at *expanders*   ,(<type>-id (eval type)) (lambda ,args ,@body)))
(define-form define-encode (type args . body)   `(set-array-at *encoders*    ,(<type>-id (eval type)) (lambda ,args ,@body)))
(define-form define-eval   (type args . body)   `(set-array-at *evaluators*  ,(<type>-id (eval type)) (lambda ,args ,@body)))
(define-form define-apply  (type args . body)   `(set-array-at *applicators* ,(<type>-id (eval type)) (lambda ,args ,@body)))

;;; local syntax

(define-function make-with-form (args-and-body)
  (and args-and-body
       `(lambda (*env* ,@(car args-and-body))
          ,@(cdr args-and-body))))

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

(define-function make-instance-accessors (name slots i)
  (and (pair? slots)
       (cons `(,(concat-symbol 'self. (car slots)) () ((slot-name) (list 'oop-at 'self ,i)))
             (make-instance-accessors name (cdr slots) (+ i 1)))))

(define-form with-instance-accessors (type . body)
  ;; TODO audit its use wrt <type>s (as opposed to <record>s). maybe do the filtering for <record>s at its point of use.
  (let ((type-object (eval type)))
    `(with-forms ,(when (subtype? (type-of type-object) <record>)
                    (make-instance-accessors type (<record>-effective-slots type-object) 0))
       (let () ,@body))))

(define-form new (type . inits)
  (let ((i -1))
    ;; TODO singletons for types whose instances have no slots?
    `(let* ((_type_ ,type)
            (_self_ (allocate (<type>-id _type_) (type/slot-count-of-instances _type_))))
       ;; TODO the usefulness of this is questionable... delme and rename make to new?
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

;;; selector/method (single dispatch on the type of the first argument)

(define-record <selector> () (name methods default))

(define-function selector? (obj) (= <selector> (type-of obj)))

(define-function <selector>-inherit (methods type)
  (when (subtype? (type-of type) <record>)
    (let ((method ())
          (probe  type))
      (while (and (set probe (<record>-super probe))
                  (not (set method (array-at methods (<type>-id probe))))))
      ;; (and method (set (array-at methods type) method))	; copy down the method for performance
      method)))

(define-apply <selector> (self . arguments)
  ;; NOTE if we wanted to be super precise while bootstrapping, then this should be
  ;; (<type>-id (type-of (car arguments))), so that type-of can map the host type to
  ;; that of the slave. this causes a major slowdown though, and it's probably not needed,
  ;; because emit.l is loaded into the host, so the type dispatches in it work as expected.
  ;; the fast version is: (type-id-of (car arguments))
  ;; same applies to generics.
  (apply (or (array-at (<selector>-methods self)
                       (type-id-of (car arguments)) ; faster version
                       ;;(<type>-id (type-of (car arguments))) ; more correct version that considers the type mappings while bootstrapping
                       )
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
  (when-at-expand (not bootstrapping?)
    ;; expr's (lambdas) are instantiated by the host, so let's not assume anything about their object layout.
    (and (expr? method)
         (or (<expr>-name method)
             (set (<expr>-name method)
                  (concat-symbol (name-of-type type) (concat-symbol '. (<selector>-name self)))))))
  (set-array-at (<selector>-methods self) (<type>-id type) method))

(define-form define-selector (name . default)
  (assert (symbol? name) "define-selector: name is not a symbol")
  (let ((var (defined? name)))
    (if var
        (if (selector? (<variable>-value var))
            `(quote ,(<variable>-value var))
          (error name" is already defined as non-selector: " (<variable>-value var)))
      (or default (set default `(args (error "selector '"',name
                                             "' has no method for "(type-name-of (car args))
                                             ": "(cons (car args) (map type-name-of (cdr args)))))))
      `(define ,name (selector ',name (lambda ,@default))))))

(define-selector add-method)

(<selector>-add-method add-method <selector>
  (lambda (self type args body)
    (<selector>-add-method self type (eval `(lambda ,args (with-instance-accessors ,type ,@body))))))

(define-form define-method (selector type args . body)
  (or (defined? selector) (eval `(define-selector ,selector)))
  `(add-method ,selector ,type ',(cons 'self args) ',body))

;;; print

(define-selector do-print (arg) (primitive/print "<"(type-name-of arg)" "(type-id-of arg)">"))
(define-selector do-dump  (arg) (do-print arg)) ; TODO why not primitive/dump?

(define print
  (lambda args
    (let ((l args))
      (while (pair? l)
        (do-print (pop l))))
    (car args)))

(define dump
  (lambda args
    (let ((l args))
      (while (pair? l)
        (do-dump (pop l)))
      (car args))))

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

(define-method do-print <undefined>	()	(primitive/print self))
(define-method do-print <string>	()	(primitive/print self))
(define-method do-print <symbol>	()	(primitive/print self))
(define-method do-print <long>		()	(primitive/print self))
(define-method do-print <array>		()	(primitive/print self))
(define-method do-print <variable>	()	(primitive/print self))

(define-method do-dump  <undefined>	()	(primitive/dump self))
(define-method do-dump  <string>	()	(primitive/dump self))
(define-method do-print <symbol>	()	(primitive/dump self))
(define-method do-print <long>		()	(primitive/dump self))
(define-method do-dump  <array>		()	(primitive/dump self))

(define-method do-print <selector> ()   (print "<selector "(<selector>-name self)">"))
(define-method do-print <type> ()	(print "<"(<type>-name self)" "(<type>-id self)">"))

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

(define-method do-print <array> ()
  (print "Array(")
  (for (i 0 (array-length self))
    (when (< 0 i) (print " "))
    (print (array-at self i)))
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

(define-record <generic> () (name methods default))

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
  (when-at-expand (not bootstrapping?)
    ;; expr's (lambdas) are instantiated by the host, so let's not assume anything about their object layout.
    (or (<expr>-name method) (set (<expr>-name method) (<generic>-name mm))))
  (if types
      (let ((methods (or (<generic>-methods mm)
                         (set (<generic>-methods mm) (array 32)))))
        (while (cdr types)
          (let* ((type (eval (car types)))
                 (type-id (<type>-id type)))
            (set methods (or (array-at methods type-id)
                             (set (array-at methods type-id) (array 32)))))
          (set types (cdr types)))
        (set (array-at methods (<type>-id (eval (car types)))) method))
    (set (<generic>-methods mm) method)))

(define-form define-multimethod (method typed-args . body)
  (let ((args  (map cadr typed-args))
        (types (map car  typed-args)))
    (or (defined? method) (eval (list 'define-generic method)))
    `(%add-multimethod ,method (list ,@types) (lambda ,args ,@body))))

(define-apply <generic> (self . arguments)
  (let ((method (<generic>-methods self))
        (arg     arguments))
    (while (and arg method)
      ;; see NOTE at define-apply <selector>
      (set method (array-at method (type-id-of (car arg))))
      (set arg (cdr arg)))
    (if (and method (not (array? method)))
        (apply method arguments)
      (let ((default (<generic>-default self)))
        (if default
            (apply default arguments)
          (error "no method in "(<generic>-name self)" corresponding to "arguments))))))

;;; sequences

(define-method length <string> ()		(string-length self))
(define-method length <array> ()		(array-length self))

(define-method at <string> (index)		(string-at self index))
(define-method at <array> (index)		(array-at self index))

(define-method set-at <string> (index value)	(set-string-at self index value))
(define-method set-at <array> (index value)	(set-array-at self index value))

;;; generic iteration

(define-method for-each <pair>   (function)	(list-do   _elt_ self (function _elt_)))
(define-method for-each <array>  (function)	(array-do  _elt_ self (function _elt_)))
(define-method for-each <string> (function)	(string-do _elt_ self (function _elt_)))

(define-function for-each-with (collection function value)
  (for-each collection (lambda (x) (function x value))))

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

(define-function array->string (arr)
  (let* ((ind 0)
         (lim (array-length arr))
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

;;; load/save

;; KLUDGE the following is not well designed, they are here just to remain compatible with the original eval.l for the time being
(define-function open (path)
  (assert (= <string> (type-of path)) "open: non-string path argument: " path)
  ;; TODO error handling
  (libc/fopen path))

(define-function close (stream)
  (assert (= <target-vm-pointer> (type-of stream)) "close: inappropriate argument: " stream)
  ;; TODO error handling
  (libc/fclose stream))

(define-function getc (stream)
  (assert (= <target-vm-pointer> (type-of stream)) "getc: inappropriate argument: " stream)
  ;; TODO error handling
  (libc/fgetc stream))

(define-function putc (stream char)
  (assert (= <target-vm-pointer> (type-of stream)) "putc: inappropriate stream argument: " stream)
  (assert (= <long> (type-of char))   "putc: non-integer char argument: " char)
  ;; TODO error handling
  (libc/fputc stream char))

(define-function format (fmt arg)
  (assert (= <string> (type-of fmt)) "format: non-string fmt argument: " fmt)
  (libc/format fmt arg))

(define-function find-and-read (name)
  (or (and *load-path* (read (concat-string *load-path* name)))
      (read name)))

(define-function load (name)
  (let ((exps (find-and-read name)))
    (or exps (error "file not found or empty: "name))
    (list-do expr exps (eval expr))))

(define *loaded*)

(define-function require (name)
  (or (member? name *loaded*)
      (let ()
        (push *loaded* name)
        (load name))))

(define-function contents-to-file-named (string path . options)
  (let ((f (or (open path "w")
               (error "cannot open for writing: "path)))
        (p (or (car options) putc)))
    (for (i 0 (length string)) (p (at string i) f))
    (close f)))

(define-function contents-of-file-named (path)
  (let ((f (or (open path)
               (error "cannot open for reading: "path)))
        (s (array))
        (c))
    (while (set c (getc f))
      (array-append s c))
    (close f)
    (array->string s)))
