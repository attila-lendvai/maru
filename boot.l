;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is the minimum "standard library" that is needed/used while bootstrapping
;;;

;; NOTE define is implemented so that it unconditionally defines the variable
;; at expand time, therefore we need to "hide" it inside a quote+eval.
(if (not (defined? 'bootstrapping?))
    (eval '(define bootstrapping? ())))

(if (not (defined? 'evolving?))
    (eval '(define evolving? ())))

(if bootstrapping?
    (let ()
      (warn "boot.l speaking with *verbosity* " *verbosity* "; we're bootstrapping")
      (if evolving?
          (warn "; we're evolving"))
      (warn "\n")))

;; This variable is controls the amount of safety features. It's mostly queried at expand time,
;; and its value at bootstrapping also controls the amount of checks compiled into the eval executable.
;; See also the (define-form safety ...).
;; 1: add some checks that are cheap
;; 2: non-trivial runtime costs
;; 3: catch my bug no matter what!
;; 4: run a gc before every allocation
(define *safety* 0)

(define unit-testing? '(t))

(define primitive/print print)
(define primitive/dump  dump)

(define error)

(define error/nested/2
  (lambda args
    (set error abort) ; let's give up in case of more recursive errors
    (primitive/print "\nNESTED ERROR LEVEL 2: ")
    (apply primitive/dump args)
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

(define list (lambda args args))

(load "source/list-min.l")

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
    (let ((x-len (string-length x))
          (y-len (string-length y)))
      (let ((res (string (+ x-len y-len)))
            (res-idx 0))
        (let ((i 0))
          (while (< i x-len)
            (set-string-at res res-idx (string-at x i))
            (set i (+ i 1))
            (set res-idx (+ res-idx 1))))
        (let ((i 0))
          (while (< i y-len)
            (set-string-at res res-idx (string-at y i))
            (set i (+ i 1))
            (set res-idx (+ res-idx 1))))
        res))))

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

;; NOTE quasituote is broken with multi-level quasiquotes. see https://github.com/fare/fare-quasiquote
(define quasiquote
  (form
    (let (qq-list qq-element qq-object)
      (set qq-list (lambda (l)
                     (if (pair? l)
                         (let ((obj (car l)))
                           (if (and (pair? obj)
                                    (= (car obj) 'unquote-splicing))
                               (if (cdr l)
                                   (list concat-list (cadr obj) (qq-list (cdr l)))
                                 (cadr obj))
                             (if (and (= 'unquote obj)
                                      (pair? (cdr l))
                                      (not (cddr l)))
                                 (cadr l)
                               ;; we directly reference the cons definition (as opposed to 'cons) so that our
                               ;; expansion will not depend on the environment of the module that is using us.
                               ;; this is relevant in the bootstrap process when the *target-module* gets
                               ;; filled with definitions and it redefines e.g. the cons evaluator
                               ;; primitive with the lowlevel implementation that is going to be
                               ;; level-shifted. same applies to car below.
                               (list cons (qq-object obj) (qq-list (cdr l))))))
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

(define-form define-symbol-form (name replacement)
  `(define ,name (form () (lambda _ ',replacement))))

(define-symbol-form *module* (current-module))

;; this is very similar in effect to read-time evaluation in CL, aka #.(foo)
(define-form eval-at-expand (form)
  (eval form))

(define-form if-at-expand (cond true-form . false-forms)
  (if (eval cond)
      true-form
    (if (and false-forms
             (cdr false-forms))
        `(let () ,@false-forms)
      (car false-forms))))

(define-form when-at-expand (cond . true-forms)
  (if (eval cond)
      (if (and true-forms
               (cdr true-forms))
          `(let ()
             ,@true-forms)
        (car true-forms))))

(define-form when (test . body)
  `(if ,test (let () ,@body)))

(define-form unless (test . body)
  `(if ,test () ,@body))

(define-form awhen (test . body)
  `(let (it)
     ;; this allows SETting IT from inside TEST
     (when (set it ,test)
       ,@body)))

(define-form aif (test true-form . false-forms)
  `(let (it)
     (set it ,test)
     (if it
         ,true-form
       ,@false-forms)))

(define-form assert (test . args)
  (unless args
    (set args (list "assertion failed: " `(quote ,test))))
  `(or ,test (error ,@args)))

(define-form define-constant (name value-form)
  `(define ,name (form () (lambda _ ',(eval value-form)))))

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

(define-form verbosity (level . body)
  `(when (<= ,level *verbosity*)
     ,@body))

(define-form safety (level . prog)
  (when (<= level *safety*)
    `(let () ,@prog)))

(define-constant false ()) ; just a convenience to facilitate code readability

;;; list basics

(define-function ensure-list (obj)
  (if (pair? obj) obj (list obj)))

(define-function member? (key list)
  (while (and (pair? list) (!= key (car list)))
    (set list (cdr list)))
  (car list))

(define-form push (list element)
  `(set ,list (cons ,element ,list)))

(define-form pop (list)
  `(let* ((_list_ ,list)
          (_head_ (car _list_)))
     (set ,list (cdr _list_))
     _head_))

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
  (when (pair? bindings)
    (let ((entry (first bindings)))
      (unless (pair? entry)
        (set entry (list entry)))
      (let ((var-name	(first entry))
            (value	(rest entry)))
        (if (pair? var-name)
            (%let*unpack var-name value (%let*bindings (cdr bindings)))
          (cons (cons var-name value)
                (%let*bindings (cdr bindings))))))))

(define-function %let* (bindings body)
  (if (pair? (cdr bindings))
      `(let (,(car bindings)) ,(%let* (cdr bindings) body))
    `(let ,bindings ,@body)))

(define-form let* bindings-body
  (%let* (%let*bindings (car bindings-body)) (cdr bindings-body)))

;; this simple let* is also enough for bootstrapping
;; (define-form let* (bindings . body)
;;   (if bindings
;;       `(let (,(car bindings)) (let* ,(cdr bindings) ,@body))
;;     `(let () ,@body)))

;;; basic iteration

(load "source/iteration-min.l")

;;;
;;; require
;;;

(define-function load (path)
  ;;(primitive/print "load, verbosity is " *verbosity* "\n")
  (verbosity 1 (warn "loading file: "path"\n"))
  (let ((exps (or (read path)
                  (error "file not found or empty: "path))))
    (list-do expr exps
      (eval expr))))

(define *loaded*)

(define-function require (path)
  (unless (member? path *loaded*)
    (push *loaded* path)
    (load path)))

;;; configuration

;; this may or may not be defined by the makefile, so let's hide the reading of the var feature/profiler behind an eval
(eval `(define-constant feature/profiler
           ,(when (defined? 'feature/profiler)
              (eval '(not (= feature/profiler 0))))))

(define-constant feature/debug-info		true)
(define-constant feature/track-expr-names	(or feature/debug-info feature/profiler))
(define-constant feature/typecheck-slot-access	(and (< 0 *safety*) (<= *optimised* 0)))

;;; list

(define-function list-length (list)
  (assert (or (not list) (pair? list)) "LIST-LENGTH called with an improper list: " list)
  (if (pair? list)
      (let ((len 1))
        (while (set list (cdr list))
          (set len (+ len 1)))
        len)
    0))

(define-function list-remove (key list)
  (let ((result ())
        (last ()))
    (while list
      (unless (= key (car list))
        (let ((new (cons (car list))))
          (if last
              (set (cdr last) new)
            (set result new))
          (set last new)))
      (set list (cdr list)))
    result))

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
      (set (cdr curr) prev)
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

;; TODO move this to be a primitive once subr creation/mapping is more automated
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
  (apply map (cons list lists)))

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

;;; iteration

(define-function %generic-do (get len var col body)
  `(let* ((_col_ ,col)
          (_idx_ 0)
          (_end_ (,len _col_)))
     (while (< _idx_ _end_)
       (let ((,var (,get _col_ _idx_))) ,@body)
       (set _idx_ (+ _idx_ 1)))))

(define-form array-do	(var arr . body)	(%generic-do array-at  array-length  var arr body))
(define-form string-do	(var str . body)	(%generic-do string-at string-length var str body))

(define-form list-detect (name list expr)
  `(let ((_ ())
         (__ ,list))
     (while (and __ (not _))
       (let ((,name (car __)))
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

(define-form is (type obj)
  `(= ,type (type-of ,obj)))

(define type-id-of type-of) ; we will replace type-of later
(set type-of 'not-yet-bootstrapped)

(define %first-type-id		1) ; i.e. the first allocated type will be 1 (so that we can assert for non-zero type in the gc)
(define %last-type-id		(- %first-type-id 1))
(define %types			(array 16))

(define-form types-do (var . body)
  `(for (__i__ %first-type-id %last-type-id)
     (let ((,var (array-at %types __i__)))
       ,@body)))

(if-at-expand bootstrapping?
    (let ()
      ;; integrate with the host vm's type machinery to instantiate slave objects
      ;; in the framework of the host while we are being bootstrapped.
      (define-function allocate-type-id ()
        (eval-in-host '(allocate-type-id)))

      (define-function allocate-type-id/slave ()
        (incr %last-type-id))

      (define %type-id-map/host->slave (array 16)))

  (define-function allocate-type-id ()
    (incr %last-type-id)))

(define-function %make-accessor-forms (type-name slot-names slot-index disable-typecheck)
  (when slot-names
    (cons (let* ((slot-name (car slot-names))
                 (accessor-name (concat-symbol type-name (concat-symbol '- slot-name))))
            (if disable-typecheck
                `(define-form ,accessor-name (obj)
                   (list 'oop-at obj ,slot-index))
              `(define-form ,accessor-name (obj)
                 (list 'slot-value ',type-name ',slot-name obj))))
          (%make-accessor-forms type-name (cdr slot-names) (+ 1 slot-index) disable-typecheck))))

(define <type>)
(define <record>)

(if-at-expand bootstrapping?
    (let ()
      (define type-id-of-<type>		(eval-in-host '(<type>-id <type>)))
      (define type-id-of-<record>	(eval-in-host '(<type>-id <record>)))
      (define slots-of-<type>		(eval-in-host '(<record>-direct-slots <type>)))
      (define slots-of-<record>		(eval-in-host '(<record>-direct-slots <record>))))

  (define type-id-of-<type>		(allocate-type-id))
  (define type-id-of-<record>		(allocate-type-id))
  (define slots-of-<type>		'(id name))
  (define slots-of-<record>		'(super direct-slots effective-slots)))

;; define temporary, non-typechecking accessors for <type> and <record>
(eval `(let ()
         ,@(%make-accessor-forms	'<type>		slots-of-<type>		0				true)
         ,@(%make-accessor-forms	'<record>	slots-of-<record>	(list-length slots-of-<type>)	true)))

(assert <type>-name)

(if-at-expand bootstrapping?
;;;
;;; bootstrap is happening, i.e. <type> and <record> is mapped into the slave from the host in early.l
;;;
    (let ()
      (set <type>		(eval-in-host '<type>))
      (set <record>		(eval-in-host '<record>))

      (let ((slave-id (allocate-type-id/slave)))
        (set (array-at %type-id-map/host->slave (<type>-id <type>)) slave-id)
        (set (array-at %types slave-id) <type>))

      (let ((slave-id (allocate-type-id/slave)))
        (set (array-at %type-id-map/host->slave (<type>-id <record>)) slave-id)
        (set (array-at %types slave-id) <record>))

      (define-function <type>-slave-id (type)
        (let* ((type-id  (<type>-id type))
               (slave-id (array-at %type-id-map/host->slave type-id)))
          (assert slave-id "no host->slave mapping exists for host type-id: " type-id "?!")
          slave-id))

      (define-function register-type (type)
        ;; while bootstrapping we instantiate types in the host (so that we can use e.g. method dispatch),
        ;; and keep an additional host-id->slave-id map.
        (let ((slave-id	(allocate-type-id/slave))
              (host-id	(<type>-id type)))
          (set (array-at %type-id-map/host->slave host-id) slave-id)
          (set (array-at %types slave-id) type)
          (eval-in-host `(register-type ',type))))

      (define-function type-object-for-id (type-id)
        (or (array-at %types (let ((slave-id (array-at %type-id-map/host->slave type-id)))
                               ;; we could make this smarter and only do the remap when there's an entry...
                               ;; but do we want to? wouldn't that hide some nasty bugs?
                               (assert slave-id "type-object-for-id: no host->slave mapping exists for host type-id: " type-id)
                               slave-id))
            (error "type-object-for-id has failed for type id "type-id", known types are: "%types))))
;;;
;;; we are not being bootstrapped, therefore we need to instantiate <type> and <record> ourselves
;;;
  (define-function register-type (type)
    (set (array-at %types (<type>-id type)) type))

  (define-function type-object-for-id (type-id)
    (or (array-at %types type-id)
        (error "type-object-for-id has failed for type id "type-id", known types are: "%types)))

  (define-function %bootstrap-type (type-name type-id type-type-id slot-count)
    (let ((type-obj (allocate type-type-id slot-count)))
      (set (<type>-id	type-obj)	type-id)
      (set (<type>-name	type-obj)	type-name)
      (register-type type-obj)
      type-obj))

  (define-function %bootstrap-record (type-name type-id super direct-slots)
    (let ((type-obj (%bootstrap-type type-name type-id type-id-of-<record> (+ (list-length slots-of-<type>)
                                                                              (list-length slots-of-<record>)))))
      (set (<record>-super		type-obj)		super)
      (set (<record>-direct-slots	type-obj)		direct-slots)
      (set (<record>-effective-slots	type-obj)		'not-yet-bootstrapped)
      type-obj))

  (set <type>	(%bootstrap-record '<type>		type-id-of-<type>	()	slots-of-<type>))
  (set <record>	(%bootstrap-record '<record>		type-id-of-<record>	<type>	slots-of-<record>)))

(assert (and <type> <record>))
(assert (= (<type>-id <type>) %first-type-id))
(assert (= (<type>-id <record>) (+ %first-type-id 1)))

(assert (= (type-object-for-id (<type>-id <type>)) <type>))
(assert (= (type-object-for-id (<type>-id <record>)) <record>))

(verbosity 2
  (warn "<type> is bootstrapped: "	<type>		", id: "	(<type>-id <type>)"\n")
  (warn "<record> is bootstrapped: "	<record>	", id: "	(<type>-id <record>)"\n"))

(define-function type-of (obj)
  (type-object-for-id (type-id-of obj)))

(assert (= (type-of <type>) <record>))
(assert (= (type-of <record>) <record>))

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

(define-function sanity-check-record-slots (record slots)
  (let ((f slots))
    (while (pair? f)
      (unless (symbol? (car f))
        (error "slot is not symbol?: "(car f)))
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

(when-at-expand (not bootstrapping?)
  (set (<record>-effective-slots <type>)	(record/compute-effective-slots <type>))
  (set (<record>-effective-slots <record>)	(record/compute-effective-slots <record>)))

(assert (equal slots-of-<type> (<record>-effective-slots <type>)))
(assert (equal (concat-list slots-of-<type> slots-of-<record>) (<record>-effective-slots <record>)))

(define-function record/effective-slot-count (type)
  (list-length (<record>-effective-slots type)))

(define-function record/slot-index (type slot-name)
  (assert (is <record> type))
  (let ((i 0)
        (list (<record>-effective-slots type)))
    (while (and (pair? list)
                (not (= slot-name (car list))))
      (set list (cdr list))
      (incr i))
    (or (and (pair? list)
             i)
        (error "record-slot-index has failed for type "type", slot-name "slot-name))))

;; now that <type> and <record> is instantiated, we can implement type checking in the accessors.
;; let's also redefine the basic accessors that we have defined earlier.
(define-function %accessor-typecheck (expected-type-id slot-name object)
  (unless (= (type-id-of object) expected-type-id)
    (let ((expected-type (type-object-for-id expected-type-id))
          (actual-type (type-of object)))
      (unless (subtype? actual-type expected-type)
        ;; (warn "about to process an %accessor-typecheck failure, which may fail to properly print the error output\nslot name is "slot-name", expected-type-id is "expected-type-id", object's actual type id is "(type-id-of object)"\n")
        (error "type check failed for record slot accessor: expected type "expected-type", slot name "slot-name", got " actual-type))))
  object)

;; slot-value is a "choke-point" that we can override while loading and expanding
;; the level-shifted code. see compile-begin for more details, or compiled peg parsers
;; that inhibit the expansion of slot-value while generating the maru code.
(define-form slot-value (type-name slot-name object)
  (let* ((type (eval type-name))
         (slot-index (record/slot-index type slot-name)))
    `(oop-at
      ,(if feature/typecheck-slot-access
           `(%accessor-typecheck ,(<type>-id type) ',slot-name ,object)
         object)
      ,slot-index)))

;; sometimes (see e.g. compiled peg parsers) we prevent slot-value to get expanded to keep
;; the generated code a little less fragile to changes in the object layout. in those
;; situations, at a later time, when the generated code is expanded, we may
;; encounter set-slot-value forms, so let's provide them, too.
(define-form set-slot-value (type-name slot-name object value)
  (let* ((type (eval type-name))
         (slot-index (record/slot-index type slot-name)))
    `(set-oop-at
      ,(if feature/typecheck-slot-access
           `(%accessor-typecheck ,(<type>-id type) ',slot-name ,object)
         object)
      ,slot-index
      ,value)))

(define-function type/slot-count-of-instances (type)
  (cond
    ((subtype? (type-of type) <record>)	(record/effective-slot-count type))
    ((subtype? (type-of type) <type>)	0)
    (else				(error "type/slot-count-of-instances: called with something unexpected: " type))))

(define-function %make-record-accessors (type)
  (assert (subtype? (type-of type) <record>) "%make-record-accessors called with a non-record type " type)
  (%make-accessor-forms (<type>-name type)
                        (<record>-direct-slots type)
                        (or (and (<record>-super type)
                                 (record/effective-slot-count (<record>-super type)))
                            0)
                        ()))

;; redefine the preliminary bootstrap accessors with full featured ones
(eval `(let ()
         ,@(%make-record-accessors <type>)
         ,@(%make-record-accessors <record>)))

(verbosity 2 (warn "type bootstrap finished\n"))

;;; at this point the type registry is bootstrapped, containing two types: <type> and <record>

(assert (= (type-of <type>)	<record>))
(assert (= (type-of <record>)	<record>))

(assert (= 2 (list-length (<record>-effective-slots <type>))))
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
  (set slots (map-with expand slots *env*))
  (set slots (list-remove () slots))
  (let ((record-type (new-<record> name (eval super) slots)))
    (eval `(define ,name ,record-type))
    `(let ((type-obj ,record-type))
       (define ,name type-obj)
       ,@(%make-record-accessors record-type)
       type-obj)))

;;; immediate type

(define-record <immediate-type> <type> (tag-value tag-width))

(define-function new-<immediate-type> (name tag-value tag-width)
  (let ((type (new-type-instance name <immediate-type>)))
    (set (<immediate-type>-tag-value	type) tag-value)
    (set (<immediate-type>-tag-width	type) tag-width)
    type))

(define-form define-immediate-type (name tag-value tag-width)
  `(define ,name ,(new-<immediate-type> name (eval tag-value) (eval tag-width))))

(define-function immediate-type? (type)
  (subtype? (type-of type) <immediate-type>))

;;; classes

(define-form define-class (name basis fields)
  ;; TODO source-level compatibility. decide whether to delme.
  ;; TODO accessor regression: there used to be <peg>-result, now there's only a <parser>-result (inheritance)
  `(define-record ,name ,basis ,fields))

;;; built-in types

;; NOTE: the primitive-functions provided by the eval executable assume
;; a certain memory layout for the built-in types.
;; what actually happens is encoded in the executable, and if you change any of these
;; then you need to bootstrap to reflect the changes in the next executable.
;; types are represented in the target as successive integers.

;; TODO maybe: type objects should be serialized into the compiled binary and this
;; should be wrapped in a big (eval-at-expand (if bootstrapping? ...)). this would also
;; reflect the fact that editing these and bringing it out of sync with the
;; level-shifted binary is not an option without grave consequences.
;; such a setup would hopefully also simplify the bootstrapping dance above.
(define-type		<data>)					; some opaque blob; used for stuff like the elements of <string> and <array>

(define-immediate-type	<undefined>		0 ())		; nil tag-width means that it's an entire word of a well-known value; in this case zero
(define-immediate-type	<long>			1 1)
;(define-record		<long>			() (_bits))	; bootstrap is about 25% slower

(define-record		<array>			() (size elements))
(define-record		<string>		() (size elements))
(define-record		<expr>			() (parameters body env ctx
                                                     (when-at-expand feature/track-expr-names	name)
                                                     (when-at-expand feature/profiler		profiler-counter)))
(define-record		<form>			() (function symbol))	; these are expander lambda's
(define-record		<fixed>			() (function))
(define-record		<primitive-function>	() (_imp _name (when-at-expand feature/profiler profiler-counter)))	; a "subr" in old lisp parlance
(define-record		<variable>		() (name value env index))
(define-record		<env>			() (parent level offset bindings stable))
(define-record		<context>		() (home env bindings callee pc))
(define-record		<module>		() (globals (when-at-expand feature/debug-info name)))		; globals is the <variable> that holds '*globals*
(define-record		<target-vm-pointer>	() (_bits))		; a pointer into the level-shifted realm, boxed, so that it can be stored in the maru heap
(define-record		<symbol>		() (_bits))
(define-record		<pair>			() (head tail))

;; TODO why are some of these here, and some are primitive-functions? unify one way or another!
(define-function long?		(obj)	(= <long>	(type-of obj)))
(define-function expr?		(obj)	(= <expr>	(type-of obj)))
(define-function variable?	(obj)	(= <variable>	(type-of obj)))

(when-at-expand bootstrapping?
  ;; let's map the following host types to their respective slave equivalents
  ;; so that type-of on one of their instances will return the slave type object.
  ;; this is mainly needed to interact with the data that the host's reader returns
  ;; e.g. to be able to specialize methods on them while in the bootstrap process.
  (list-do entry `(("" ,<string>) (42 ,<long>) (t ,<symbol>) ((1) ,<pair>) (() ,<undefined>))
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

(define-function global-variable? (var)
  (= 0 (<env>-level (<variable>-env var))))

(define-form define-expand (type args . body)   `(set-array-at *expanders*   ,(<type>-id (eval type)) (lambda ,args ,@body)))
(define-form define-encode (type args . body)   `(set-array-at *encoders*    ,(<type>-id (eval type)) (lambda ,args ,@body)))
(define-form define-eval   (type args . body)   `(set-array-at *evaluators*  ,(<type>-id (eval type)) (lambda ,args ,@body)))
(define-form define-apply  (type args . body)   `(set-array-at *applicators* ,(<type>-id (eval type)) (lambda ,args ,@body)))

;;; local syntax

(define-function make-with-form (args-and-body)
  (when args-and-body
    `(lambda (*env* ,@(car args-and-body))
       ,@(cdr args-and-body))))

(define-form with-forms (bindings . body)
  (let ((env (environment *env*)))
    (list-do binding bindings
      (let* ((name    (first  binding))
             (fun     (second binding))
             (var     (third  binding))
             ;; if we take the value of form now, then our expansion will not depend on the
             ;; value of form in the current module. this is useful when bootstrapping.
             (exp     (list form (make-with-form fun) (make-with-form var))))
        (environment-define env name (eval exp *env*))))
    `(let ()
       ,@(map-with expand body env))))

;;; field accesors

(define-function make-instance-accessors (var-name type-name slots)
  (when (pair? slots)
    (cons `(,(concat-symbols var-name '. (car slots))
             ()
             ((_)
              `(slot-value ,type-name ,(car slots) ,var-name)))
          (make-instance-accessors var-name type-name (cdr slots)))))

(define-form with-instance-accessors (var-name type-name . body)
  (let ((type-object (eval type-name)))
    (if (subtype? (type-of type-object) <record>)
        `(with-forms ,(make-instance-accessors var-name type-name (<record>-effective-slots type-object))
           ,@body)
      `(let ()
         ,@body))))

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
     (with-instance-accessors self ,type
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
                       (if-at-expand (and bootstrapping?
                                          (= 0 *optimised*))
                           ;; more correct version that considers the type mappings while bootstrapping (i.e. pretty printing works properly while bootstrapping).
                           ;; this slows down the bootstrap by about 10% though.
                           (<type>-id (type-of (car arguments)))
                         (type-id-of (car arguments))))
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
  (when-at-expand (and feature/track-expr-names
                       (not bootstrapping?))
    ;; expr's (lambdas) are instantiated by the host, so let's not assume anything about their object layout.
    (when (and (expr? method)
               (not (<expr>-name method)))
      (set (<expr>-name method)
           (concat-symbols (name-of-type type) '. (<selector>-name self)))))
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
    (<selector>-add-method self type (eval `(lambda ,args (with-instance-accessors self ,type ,@body))))))

(define-form define-method (selector type args . body)
  (or (defined? selector) (eval `(define-selector ,selector)))
  `(add-method ,selector ,type ',(cons 'self args) ',body))

;;; print

(define-selector do-print (self) (primitive/print "["(type-name-of self)" "(type-id-of self)"]"))
(define-selector do-dump  (self) (primitive/dump self))

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

(define-method do-print <undefined>		()	(primitive/print self))
(define-method do-print <string>		()	(primitive/print self))
(define-method do-print <symbol>		()	(primitive/print self))
(define-method do-print <long>			()	(primitive/print self))
(define-method do-print <array>			()	(primitive/print self))
(define-method do-print <variable>		()	(primitive/print self))
(define-method do-print <primitive-function>	()	(primitive/print self))

(define-method do-dump  <undefined>		()	(primitive/dump self))
(define-method do-dump  <string>		()	(primitive/dump self))
(define-method do-dump  <symbol>		()	(primitive/dump self))
(define-method do-dump  <long>			()	(primitive/dump self))
(define-method do-dump  <array>			()	(primitive/dump self))

(define-method do-print <fixed>		()	(print "<fixed "self.function">"))
(define-method do-print <selector>	()	(print "<selector "self.name">"))
(define-method do-print <expr>		()	(print "<expr "(or (when-at-expand feature/track-expr-names self.name) "?")" "self.parameters">"))
(define-method do-print <env>		()	(print "<env Lv"self.level",Off"self.offset",#"(array-length self.bindings)">"))
(define-method do-print <module>	()	(print "<module "(or (when-at-expand feature/debug-info self.name) "?") ">"))
(define-method do-print <type>		()	(print "<"(<type>-name self)" "(<type>-id self)">"))

(define-function %print-list (lst fn)
  (print "(")
  (let ((first-time?	true)
        (cell		lst))
    (while (pair? cell)
      (if first-time?
          (set first-time? ())
        (print " "))
      (fn (car cell))
      (set cell (cdr cell)))
    (when cell
      (print " . " cell))
    (print ")")))

(define-method do-print <pair> ()
  (%print-list self print))

(define-method do-dump <pair> ()
  (%print-list self dump))

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
                      (set found true)
                      (set arg ())))
              (let ()
                (print ". ")
                (dump-until target arg)))
            (if (set arg (cdr arg))
                (print " ")))
          (print ")"))
      (dump arg))
    found))

;;; generic/multimethod (dispatch on the type of all arguments, but does not support inheritance for now)

(define-record <generic> () (name methods default))

(define-function generic (name default)
  (let ((self (new <generic>)))
    (set (<generic>-name    self) name)
    (set (<generic>-methods self) (array))
    (set (<generic>-default self) default)
    self))

(define-method do-print <generic> () (print "<multimethod:" (<generic>-name self) ">"))

(define-form define-generic (name . default)
  (or default (set default `(args (error "no method in generic "',name" corresponding to: "args", of types: " (map type-of args)))))
  `(define ,name (generic ',name (lambda ,@default))))

;; we store the no-dispatch case at index 0
(define-constant +multimethod-type-id-offset+ 1)

(define-function %add-multimethod (mm types method)
  (when-at-expand (and feature/track-expr-names
                       (not bootstrapping?))
    ;; expr's (lambdas) are instantiated by the host, so let's not assume anything about their object layout.
    (or (<expr>-name method) (set (<expr>-name method) (<generic>-name mm))))
  (if types
      (let ((methods (or (<generic>-methods mm)
                         (set (<generic>-methods mm) (array 32)))))
        (while (cdr types)
          (let* ((type	(awhen (car types)
                          (eval it)))
                 (index	(if type
                            (+ (<type>-id type) +multimethod-type-id-offset+)
                          ;; we store the no-dispatch case at index 0
                          0)))
            (set methods (or (array-at methods index)
                             (set (array-at methods index) (array 32)))))
          (set types (cdr types)))
        (set (array-at methods (aif (car types)
                                   (+ (<type>-id (eval it))
                                      +multimethod-type-id-offset+)
                                 0))
             method))
    (set (<generic>-methods mm) method)))

(define-form define-multimethod (method typed-args . body)
  (let ((args  (map (lambda (x) (if (pair? x) (second x) x))	typed-args))
        (types (map (lambda (x) (when (pair? x) (first x)))	typed-args)))
    (or (defined? method) (eval (list 'define-generic method)))
    `(%add-multimethod ,method (list ,@types) (lambda ,args ,@body))))

(define-function %generic-lookup (method arg)
  (if (and arg (array? method))
      (or (%generic-lookup (array-at method (+ +multimethod-type-id-offset+ (type-id-of (car arg))))
                           (cdr arg))
          (%generic-lookup (array-at method 0)
                           (cdr arg)))
    method))

(define-apply <generic> (self . arguments)
  (let ((method (%generic-lookup (<generic>-methods self) arguments)))
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

;;; load/save

;; (define *load-path* ())

;; (when (= "-L" (car *command-line-arguments*))
;;   (pop *command-line-arguments*)
;;   (set *load-path* (pop *command-line-arguments*)))

;; KLUDGE the following is not well designed, they are here just to remain compatible with the original eval.l for the time being
(define-function file-open (path)
  ;;(assert (= <string> (type-of path)) "file-open: non-string path argument: " path)
  (libc/fopen path "r"))

(define-function file-close (handle)
  ;;(assert (= <target-vm-pointer> (type-of stream)) "close: inappropriate handle: " handle)
  (libc/fclose handle))

;; (define-function read-file-at-path (path)
;;   (read (concat-string (or *load-path* "") path)))

(define-function file-read-character (handle)
  ;;(assert (= <target-vm-pointer> (type-of handle)) "file-read-character: inappropriate handle: " handle)
  (libc/fgetc handle))

;; (define-function file-write-character (stream char)
;;   ;;(assert (= <target-vm-pointer> (type-of stream)) "file-write-character: inappropriate stream argument: " stream)
;;   (libc/fputc char stream))

;; (define-function contents-to-file-named (string path . options)
;;   (let ((f (or (file-open path "w")
;;                (error "cannot open for writing: "path)))
;;         (p (or (car options) file-write-character)))
;;     (for (i 0 (length string))
;;       (p (at string i) f))
;;     (close f)))

(define-function contents-of-file-named (path)
  (let ((f (or (file-open path)
               (error "cannot open for reading: "path)))
        (s (array))
        (c))
    (while (set c (file-read-character f))
      (array-append s c))
    (file-close f)
    (array->string s)))

(define-function format (fmt arg)
  ;;(assert (= <string> (type-of fmt)) "format: non-string fmt argument: " fmt)
  (libc/format fmt arg))
