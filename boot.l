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

;;;
;;; require
;;;

(define *load-history* ())

(define primitive/load load)

(set load (lambda (path)
            (and (<= 1 *verbosity*) (warn "loading file: "path"\n"))
            (set *load-history* (cons path *load-history*))
            (let ((exps (or (read path)
                            (error "file not found or empty: "path))))
              (while exps
                (eval (car exps))
                (set exps (cdr exps))))))

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
  `(define ,name (form () (lambda _ ',replacement))))

(define-symbol-form *module* (current-module))

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

;; this smells like a KLUDGE: we let gc/let* leak here from eval.l so that we can use
;; certain constructs in the implementation of the evaluator. ideally, the compiler
;; should be smart enough to inform the GC about ephemeral GC roots on the stack.
(define-symbol-form gc/let* let*)

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
(require "source/sequences-basic.l")

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
  (let ((type-object (eval type-name)))
    (if (is <record> type-object)
        (let ((accessors ())
              (super type-object))
          (while (is <record> super)
            (list-do accessor (make-instance-accessors var-name
                                                       (<type>-name super)
                                                       (<record>-direct-slots super))
              (push accessors accessor))
            (set super (<record>-super super)))
          `(with-forms ,accessors
             ,@body))
      `(let ()
         ,@body))))

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

(require "source/generic.l")

;;; conversion

(define-function string->number (str . rest)
  (let ((radix (if rest (first rest) 10))
        (n 0)
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
