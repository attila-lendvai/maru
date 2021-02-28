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
(define *safety* 1)

(define error)

(define primitive/print		print)
(define primitive/print-all	print-all)
(define primitive/dump		dump)
(define primitive/dump-all	dump-all)

(define error/nested/2
  (lambda args
    (set error abort) ; let's give up in case of more recursive errors
    (apply primitive/dump-all (cons *error-output* (cons "\nNESTED ERROR LEVEL 2: " args)))
    (primitive/print-all *error-output* "\n")
    (abort)))

(define error/nested/1
  (lambda args
    (set error error/nested/2)
    (apply primitive/print-all (cons *error-output* (cons "\nNESTED ERROR LEVEL 1: " args)))
    (primitive/print-all *error-output* "\n")
    (abort)))

(set error
  (lambda args
    (set error error/nested/1) ; in case a nested error happens while reporting
    (apply primitive/print-all (cons *error-output* (cons "\nerror: " args)))
    (primitive/print-all *error-output* "\n")
    (abort)))

(define list (lambda args args))

;;;
;;; require
;;;

;; TODO FIXME REQUIRE loads from the current directory. therefore the
;; host, during the bootstrap process, loads the slave's
;; definitions. fix LOAD so that the host's boot.l loads the host's
;; files.
(define *load-history* ())

(define primitive/load load)

;; NOTE using SET instead of DEFINE wouldn't introduce a new binding
;; in *maru-user*, but overwrite the one holding the primitive in *maru*.
(define load
  (lambda (path)
    (and (<= 1 *verbosity*) (warn "loading file: "path"\n"))
    (set *load-history* (cons path *load-history*))
    (primitive/load path)))

(define require
  (lambda (path)
    (let ((list *load-history*))
      (while (and list
                  (not (= path (car list))))
        (set list (cdr list)))
      (if (not list)
          (load path)))))

(require "source/list-min.l")

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

(define qq-concat-list	'concat-list)
(define qq-cons		'cons)

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
                                   (list qq-concat-list (cadr obj) (qq-list (cdr l)))
                                 (cadr obj))
                             (if (and (= 'unquote obj)
                                      (pair? (cdr l))
                                      (not (cddr l)))
                                 (cadr l)
                               ;; in the bootstrap process we want to be able to directly reference the
                               ;; cons primitive-function (as opposed to the 'cons symbol) so that our
                               ;; expansion will not depend on the environment of the module that is using us.
                               ;; this is relevant in the bootstrap process when the *target-module* gets
                               ;; filled with definitions and it redefines e.g. the cons evaluator
                               ;; primitive with the lowlevel implementation that is going to be
                               ;; level-shifted. same applies to car below.
                               (list qq-cons (qq-object obj) (qq-list (cdr l))))))
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
  ;; NOTE unless we instantiate the FORM in the body of the macro
  ;; then in the bootstrap environment it will be bound to the target
  ;; implementation of FORM.
  (let ((replacement (eval replacement *env*)))
    `(define ,name ,(form () (lambda _ replacement)))))

(define-form define-constant (name value-form)
  `(define ,name (form () (lambda _ ',(eval value-form)))))

(define-form define-function (name args . body)
  `(define ,name (lambda ,args ,@body)))

;; a trivial let* without destructuring. it will be redefined later in destructuring.l
;; with one that can also do destructuring.
(define-form let* (bindings . body)
  (if bindings
      `(let (,(car bindings)) (let* ,(cdr bindings) ,@body))
    `(let () ,@body)))

(define-form != (a b)
  `(not (= ,a ,b)))

(require "source/control-structures.l")

(define-symbol-form *globals* '(current-globals))

;; KLUDGE: the compiler cannot yet automatically keep track of gc
;; roots. to be able to share code between the evaluator and the
;; compiler, we register a few NOPs in the interpreter.
(define-symbol-form gc/let* 'let*)
;; NOTE do NOT try to mess here with box/unbox! it will screw you up
;; when in the compiler you want to box a literal and emit it into the
;; target...

(define-form assert (test . args)
  (unless args
    (set args (list "assertion failed: " `(quote ,test))))
  `(or ,test (error ,@args)))

(define-form verbosity (level . body)
  `(when (<= ,level *verbosity*)
     ,@body))

(define-form safety (level . prog)
  (when (<= level *safety*)
    `(let () ,@prog)))

(define-constant false ()) ; just a convenience to facilitate code readability

;;; configuration

;; this may or may not be defined by the makefile, so let's hide the reading of the var feature/profiler behind an eval
(define-constant feature/profiler		(when (defined? 'feature/profiler)
                                                  (eval '(not (= feature/profiler 0)))))
(define-constant feature/profiler/cumulative	true) ; walk the stack and increment everyone found
(define-constant feature/debug-info		true)
(define-constant feature/track-expr-names	(or feature/debug-info feature/profiler))
(define-constant feature/typecheck-slot-access	(or (<= 3 *safety*)
                                                    (and (<= 2 *safety*) (<= *optimised* 0))))

(define-function compose (a b)
  (lambda args
    (b (apply a args))))

(require "source/list-basic.l")
(require "source/destructuring.l")
(require "source/iteration-min.l")

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

(require "source/sequences-basic.l")

(require "source/types.l")

;; KLUDGE fake defunct slot accessors for source position to remain compatible
(define-function <pair>-source (x) ())
(define-function set-<pair>-source (x pos) pos)

(define-function global-variable? (var)
  (= 0 (<env>-level (<variable>-env var))))

(define-function self-evaluating-value? (x)
  (or (is <string> x)
      (is <long> x)))

(define-form define-expand (type args . body)   `(set (array-at *expanders*	,(<type>-id (eval type))) (lambda ,args ,@body)))
(define-form define-encode (type args . body)   `(set (array-at *encoders*	,(<type>-id (eval type))) (lambda ,args ,@body)))
(define-form define-eval   (type args . body)   `(set (array-at *evaluators*	,(<type>-id (eval type))) (lambda ,args ,@body)))
(define-form define-apply  (type args . body)   `(set (array-at *applicators*	,(<type>-id (eval type))) (lambda ,args ,@body)))

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
  (let ((accessors	())
        (super		(eval type-name)))
    (while (is <record> super)
      (list-do accessor (make-instance-accessors var-name
                                                 (<type>-name super)
                                                 (<record>-direct-slots super))
        (push accessors accessor))
      (set super (<record>-super super)))
    `(with-forms ,accessors
       ,@body)))

(define-form new (type-name . inits)
  (let* ((i -1)
         (type (eval type-name))
         (allocate-form `(allocate ,type-name ,(type/slot-count-of-instances type))))
    ;; TODO singletons for types whose instances have no slots?
    (if inits
        `(gc/let* ((_self_ ,allocate-form))
           ;; TODO the usefulness of this is questionable... delme and rename make to new?
           ,@(map (lambda (_init_) (list 'set-oop-at '_self_ (set i (+ i 1)) _init_)) inits)
           _self_)
      allocate-form)))

(define-form new* (type . inits)
  ;; this one doesn't need to know the type at expand-time
  (let ((i -1))
    `(gc/let* ((_type_ ,type)
               (_self_ (allocate (<type>-id _type_)
                                 (type/slot-count-of-instances _type_))))
       ,@(map (lambda (_init_) (list 'set-oop-at '_self_ (set i (+ i 1)) _init_)) inits)
       _self_)))

(define-function %make-make-inits (env prefix inits)
  (when inits
    (let ((entry (first inits)))
      (when (= (first entry) 'when-at-expand) ; well, if we look at it as a DSL... or is it a KLUDGE?
        (set entry (expand entry env)))
      (when entry
        (cons `(set ,(concat-symbol prefix (first entry)) ,(second entry))
              (%make-make-inits env prefix (cdr inits)))))))

(define-form make (type . inits)
  `(gc/let* ((self (new ,type)))
     (with-instance-accessors self ,type
       ,@(%make-make-inits *env* 'self. inits)
       self)))

(require "source/selector.l")
(require "source/printing.l")
(require "source/generic.l")
