;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; The Maru VM, written in a dialect of Maru.
;;;

;;;
;;; Naming convention in this file:
;;;
;;; vm     - Virtual Machine, i.e. a universe capable of executing code.
;;;          It has its own set of laws that are accepted as axioms.
;;;
;;; host   - The Maru vm animating the bootstrap process.
;;;
;;; target - The target vm of the "level-shift" operation (e.g. x86 machines).
;;;
;;; kernel - It's the part of the code that runs in the target vm.
;;;
;;; slave  - The Maru vm that is being bootstrapped and that will
;;;          spring to life when the result of the level-shift
;;;          (the compilation) gets executed on the target.
;;;          Its name comes from the idea that, having a dynamic compiler,
;;;          the host could start up the slave vm under its full
;;;          supervision.
;;;
;;; oop    - Ordinary Object Pointer, pointing to a lisp value.
;;;
;;; get, put
;;;        - These are the kernel "accessors" for low-level Maru values.
;;;
;;; *foo* is global
;;; +foo+ is a constant
;;; -foo- comes from the implicit lexical scope
;;; <foo> is a type
;;;
;;; size means bytes; if not, then it should be indicated.

;;;
;;; types and their kernel accessors (get, put, is)
;;;
;;; unsurprisingly, types are represented in the target as integers.
;;; <undefined> doesn't necessarily need to be denoted by zero.
;;; the primitive-functions encode/implement the behavior of the primitive types.
;;; ----------------------------------------------------------------

(define-function %allocate-boxed (type-id payload)
  (let ((obj (gc/allocate-opaque type-id (words-to-bytes 1))))
    (set (oop-at obj 0) payload)
    obj))

(define-form box (type-name payload)
  (let ((type (eval type-name)))
    (cond
      ((is <boxed-type> type)
       (assert (<boxed-type>-one-word? (eval type-name)) "cannot know how to allocate a boxed type that is not one-word?")
       `(%allocate-boxed ,type-name ,payload))
      ((is <immediate-type> type)
       ;; TODO error when overflow
       `(bitwise-or (<< ,payload ,(<immediate-type>-tag-width type))
                    ,(<immediate-type>-tag-value type)))
      (else
       (error "box: don't know how to deal with "type)))))

(define-form unbox (type-name obj)
  (let ((type (eval type-name)))
    (cond
      ((is <boxed-type> type)
       (if (<boxed-type>-one-word? type)
           `(oop-at ,(if feature/typecheck-slot-access
                         `(%accessor-typecheck ,type-name ,obj)
                       obj)
                    0)
         ;; then we just return its address, the payload is right there inlined
         (if feature/typecheck-slot-access
             `(%accessor-typecheck ,type-name ,obj)
           obj)))

      ((is <immediate-type> type)
       (if (< *safety* 2)
           `(>> ,obj ,(<immediate-type>-tag-width <long>))
         `(let ((__obj__ ,obj))
            (assert (is ,type-name __obj__))
            (>> __obj__ ,(<immediate-type>-tag-width <long>)))))

      (else
       (error "unbox: don't know how to deal with "type)))))

;; NOTE this is not exactly the same as the one in the user-land, it lacks the slot-name
;; parameter (because the compiler cannot deal with symbol literals yet).
(define-function %accessor-typecheck (expected-type-id object)
  (let ((type (type-of object)))
    (or (= type expected-type-id)
        (fatal2 "kernel get/put type error: expected type id %ld, got %ld" expected-type-id type)))
  object)

;; shorthands (and optimizations)
(if-at-expand feature/optimize-space
    (let ()
      (define-function long?	(obj)	(is <long>	obj))
      (define-function pair?	(obj)	(is <pair>	obj))
      (define-function string?	(obj)	(is <string>	obj))
      (define-function symbol?	(obj)	(is <symbol>	obj))
      (define-function array?	(obj)	(is <array>	obj)))
  (define-form long?		(obj)	`(is <long>	,obj))
  (define-form pair?		(obj)	`(is <pair>	,obj))
  (define-form string?		(obj)	`(is <string>	,obj))
  (define-form symbol?		(obj)	`(is <symbol>	,obj))
  (define-form array?		(obj)	`(is <array>	,obj)))

(define-form get/head		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'head))	`(<pair>-head ,obj)))
(define-form put/head		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'head) ,val)	`(set (<pair>-head ,obj) ,val)))
(define-form get/tail		(obj)		(if (< *safety* 2)		`(oop-at ,obj ,(record/slot-index <pair> 'tail))	`(<pair>-tail ,obj)))
(define-form put/tail		(obj val)	(if (< *safety* 2)	    `(set-oop-at ,obj ,(record/slot-index <pair> 'tail) ,val)	`(set (<pair>-tail ,obj) ,val)))

(define-form get/string		(obj)		`(<string>-elements (string-ensure-zero-terminated ,obj)))

;; TODO should we turn these into macros? or introduce compiler macros?
(define-primitive-function car (list)
  (when list
    (safety 2 (assert (pair? list) "car called on non-list: " list))
    (get/head list)))

(define-primitive-function cdr (list)
  (when list
    (safety 2 (assert (pair? list) "cdr called on non-list: " list))
    (get/tail list)))

(load "source/list-min.l")

;;;
;;; object instantiation
;;; ----------------------------------------------------------------

;; TODO try to eliminate this opaque anomaly leaking here... maybe by annotating this on the type?
(define-form make/opaque (type-name . inits)
  (let ((type (eval type-name)))
    `(gc/let* ((self (gc/allocate-opaque ,type-name ,(words-to-bytes (record/effective-slot-count type)))))
       (with-instance-accessors self ,type-name
         ,@(%make-make-inits *env* 'self. inits)
         self))))

(define-primitive-function (allocate ()) (type (slot-count <long>))
  ;; allocates a lisp object with the given type. size is given as a count of the slots (pointers).
  (allocate (cond
              ((is <long> type)
               (unbox <long> type))
              ((or (is <type> type)
                   (is <record> type))
               ;; KLUDGE we need to disable accessor typecheck here, because when it's a <record>, then it gets triggereed, because the target universe is unaware of inheritance
               (unbox <long> (with-forms ((%accessor-typecheck ((type obj) obj)))
                               (<type>-id type))))
              (else
               (error "allocate: illegal type specifier: "type)))
            slot-count))

(define-primitive-function allocate-data ((byte-size <long>))
  (gc/allocate-opaque <data> byte-size))

(define-primitive-function cons ((head () ()) (tail () ()))
  (make <pair>
    (head head)
    (tail tail)))

(define-primitive-function string ((length <long> 0))
  (make <string>
    (size	(box <long> 0))
    (elements	(when (< 0 length)
                  (allocate-data length)))))

;; TODO merge this into the box/unbox API?
;; TODO would be nice if we could get rid of this
(define-function string-from-cstring (cstr)
  (let* ((len (platform/string-length cstr))
         (obj (string len)))
    (set (slot-value <string> size obj) (box <long> len))
    (copy-bytes cstr (<string>-elements obj) len)
    obj))

(define-function symbol (cstr)
  (let ((len (+ 1 (platform/string-length cstr)))) ; +1 is for the zero termination (TODO libc leakage)
    (gc/let* ((obj (gc/allocate-opaque <symbol> len)))
      (copy-bytes cstr obj len)
      obj)))

(define-primitive-function array ((capacity <long> 0))
  (make <array>
    (size	(box <long> 0))
    (elements	(when (> capacity 0)
                  (allocate <data> capacity)))))

(define-function expr (parameters body env ctx)
  (make <expr>
    (parameters	parameters)
    (body	body)
    (env	env)
    (ctx	ctx)
    (when-at-expand feature/profiler
      (profiler-counter (box <long> 0)))))

(define-primitive-function form (fn (sym () ()))
  (make <form>
    (function	fn)
    (symbol	sym)))

(define-primitive-function fixed (fn)
  (make <fixed>
    (function fn)))

(define-function primitive-function (_imp _name)
  (make/opaque <primitive-function>
    (_imp		_imp)
    (_name		_name)
    (when-at-expand feature/profiler
      (profiler-counter	0))))

(define-primitive-function variable ((name <symbol>) value (env <env>) (index <long>))
  (make <variable>
    (name	name)
    (value	value)
    (env	env)
    (index	(box <long> index))))

(define-primitive-function environment ((parent <env>) (level <long> 0) (offset <long> (unbox <long> (<env>-offset parent))))
  (make <env>
    (parent	parent)
    (level	(box <long> (if parent (+ (unbox <long> (<env>-level parent)) level) 0)))
    (offset	(box <long> offset))
    (bindings	(array 0))))

(define-function base-context (home env)
  (make <context>
    (home	home)
    (env	env)
    (bindings	(array 0))))

;; (define-function context (home caller env)
;;   (let ((obj ()))
;;     (if (and caller
;;              (set obj (<context>-callee caller)))
;;         (let ()
;;           (set (<context>-home obj) home)
;;           (set (<context>-env  obj) env))
;;       (set obj (base-context home env))
;;       (when caller
;;         (set (<context>-callee caller) obj)))
;;     obj))

(define-function context (home caller env)
  (let ((obj (base-context home env)))
    (when caller
      (set (<context>-callee caller) obj))
    obj))

;;;
;;; more utils
;;; ----------------------------------------------------------------

(define-function list2 (a b)
  (gc/let* ((tmp (cons b ())))
    (cons a tmp)))

(define-function list3 (a b c)
  (gc/let* ((tmp (list2 b c)))
    (cons a tmp)))

(define-function concat-list (head tail)
  (if (pair? head)
      (gc/let* ((new-tail (concat-list (get/tail head) tail)))
        (cons (get/head head) new-tail))
    tail))

(require "source/evaluator/arrays.l")
(require "source/conversion-min.l")
(require "source/evaluator/buffer.l")
(require "source/sequences-min.l")

;;;
;;; env
;;; ----------------------------------------------------------------

(load "source/env-min.l")

(define-primitive-function (current-module ()) ()
  *module*)

(define-primitive-function set-current-module ((module <module>))
  (debug (libc/printf "set-current-module {%p}\n" module))
  (set *module* module)
  (capture-well-known-module-values)
  module)

(define-form with-current-module (module . body)
  `(gc/let* ((__previous-module__ *module*)
             __result__)
     (set-current-module ,module)
     (set __result__ (let () ,@body))
     (set-current-module __previous-module__)
     __result__))

;; TODO this is ready to be moved into env-min.l, but then it redefines the host's defined?
;; and breaks something when it's loaded while not bootstrapping.
;; think this through: the host hands over to us <env>'s in e.g. <form>s
;; or as the module's env, and we need to access them, even while we load our own stuff
;; into the slave. we can't just redefine the host's DEFINED? function. this also applies to
(define-primitive-function defined? ((name <symbol>) (env <env> (module-env *module*)))
  (let ((result ()))
    (while (and env
                (not (set result (find-local-variable env name))))
      (set env (<env>-parent env)))
    result))

(define-function new-variable (env name)
  (safety 2 (assert (is <env> env)	"new-variable: env arg is not of type <env>: "env))
  (safety 2 (assert (symbol? name)	"new-variable: name arg is not of type <symbol>: "name))
  (let ((offset (unbox <long> (<env>-offset env))))
    (gc/let* ((var (variable name () env offset)))
      (set (<env>-offset env) (box <long> (+ offset 1)))
      (array-append (<env>-bindings env) var))))

(define-primitive-function environment-define ((env <env>) (name <symbol>) value)
  (debug (platform/print-diagnostics "environment-define called, name is "(unbox <symbol> name)"\n"))
  (let ((var (find-local-variable env name)))
    (if var
        (let ()
          ;; TODO
          ;;(error "environment-define: variable "it" is already defined in env "env)
          ;;(platform/print-diagnostics "warning: environment-define: variable '"(unbox <symbol> (<variable>-name var))"' is already defined in this env.\n")
          )
      (set var (new-variable env name)))
    (set (<variable>-value var) value)
    var))

(define-primitive-function string->symbol ((str <string>))
  (array-binary-search *symbols*
                       str
                       (lambda (str candidate) ; TODO there's no support yet for capturing str into the closure
                         ;; NOTE this assumes that the payload in our strings has the
                         ;; same representation as that of symbols.
                         (let ((candidate-payload (unbox <symbol> candidate)))
                           ;; TODO this could be simpler/faster if closures could capture
                           ;; TODO eliminate libc/strlen
                           (compare-characters str (libc/strlen str)
                                               candidate-payload (libc/strlen candidate-payload))))
                       (lambda (array index str)
                         (debug (platform/print-diagnostics "interning "(get/string str)"\n"))
                         (gc/let* ((sym (symbol str)))
                           (array-insert array index sym)
                           sym))))

(define-function maybe-object-in-variable (var type)
  (let ((tmp var))
    (and tmp
         (is <variable> tmp)
         (set tmp (<variable>-value tmp))
         (or (not type)
             (= type (type-of tmp)))
         tmp)))

(define-function maybe-object-in-env (env name type)
  (when (symbol? name)
    (maybe-object-in-variable (defined? name env) type)))

;; TODO move this also into env-min.l, but for that we need smart accessors in the
;; level-shifted code that automatically do the unboxing of slot values
(define-function global-variable? (var)
  (let ((env (<variable>-env var)))
    (= 0 (unbox <long> (<env>-level env)))))

(load "source/evaluator/reader.l")
(load "source/evaluator/printer.l")

;;;
;;; backtrace
;;; ----------------------------------------------------------------

(define-record <call-frame> () (callee-designator callee arguments))

(define-form with-new-call-frame (args . body)
  (let ((call-depth-check `(when (> (incr *call-stack-index*) +maximum-call-stack-depth+)
                             (fatal1 "infinite recursion guard triggered at call depth %ld" *call-stack-index*))))
    `(let ((__result__ ,(if feature/backtrace
                            `(let ((-call-frame- (%new-call-frame ,@args)))
                               ,call-depth-check
                               ,@body)
                          `(let ()
                             ,call-depth-check
                             ,@body))))
       (decr *call-stack-index*)
       ,(when feature/backtrace
          '(when (<= 0 *call-stack-index*)
            ;; gc optimization: clear the now unused call-frame
            (let ((frame (array-at *call-stack* *call-stack-index*)))
              (with-instance-accessors frame <call-frame>
                (set frame.callee-designator	())
                (set frame.callee		())
                (set frame.arguments		())))))
       ;;(debug (platform/print-diagnostics "with-new-call-frame returning with result: ") (println __result__))
       __result__)))

(when-at-expand feature/backtrace
  (define-function %new-call-frame (callee-designator callee args)
    (safety 3 (unless (gc/valid-maru-value? callee-designator)	(fatal1 "new-call-frame: encountered an untagged callee-designator: %p" callee-designator)))
    (safety 3 (unless (gc/valid-maru-value? callee)		(fatal1 "new-call-frame: encountered an untagged callee %p" callee)))
    (let ((frame (array-at *call-stack* *call-stack-index*)))
      (if frame
          (safety 3 (assert (is <call-frame> frame) "new-call-frame: found a non-<call-frame> in the *call-stack*, type: " (type-of frame)))
        (gc/let* ((new-frame (new <call-frame>)))
          (set (array-at *call-stack* *call-stack-index*) new-frame)
          (set frame new-frame)))
      (with-instance-accessors frame <call-frame>
        (set frame.callee-designator	callee-designator)
        (set frame.callee		callee)
        (set frame.arguments		args))
      frame))

  (define-function current-call-frame ()
    (when (< 0 *call-stack-index*)
      (array-at *call-stack* (- *call-stack-index* 1)))))

(define-function print-backtrace ()
  (if-at-expand feature/backtrace
      (let ()
        (for (i 0 *call-stack-index*)
          (let ((call-frame (array-at *call-stack* i))
                (index-label (long->string i)))
            (times-do (- 3 (string-length index-label))
              (string-insert index-label 0 ?\ ))
            (print index-label)
            (platform/print ": ")
	    (println (<call-frame>-callee-designator call-frame))

            (platform/print "\tcallee:\t")
	    (println (<call-frame>-callee call-frame))

            (when (and (<= *error-level* 1)
                       (<call-frame>-arguments call-frame))
              (let ((arg-index 0))
                (list-do arg (<call-frame>-arguments call-frame)
                  (platform/print "\targ ")
                  (print (long->string arg-index))
                  (platform/print ":\t")
                  (println arg)
                  (incr arg-index))))))
        ;; man exit says that it's flushed, but looks like it's not. plus there's this: https://wiki.sei.cmu.edu/confluence/display/c/FIO23-C.+Do+not+exit+with+unflushed+data+in+stdout+or+stderr
        (platform/flush-streams))
    (platform/print-diagnostics "print-backtrace: call-frame tracking is disabled in this build. current call depth is "(get/string (long->string *call-stack-index*))"\n")))

;;;
;;; apply
;;; TODO move this into the expand-encode-eval-apply order
;;; ----------------------------------------------------------------

(define-function apply/expr (fun arguments parent-ctx)
  (verbosity 3 (platform/print "  A  ") (print fun)  (platform/print " ")  (print arguments) (platform/print " ") (println parent-ctx))
  (let ((env	(<expr>-env fun))
        (params	(<expr>-parameters fun)))
    (gc/let* ((innter-ctx (context (<expr>-ctx fun) parent-ctx env)))
      (let ((locals (<context>-bindings innter-ctx))
            (args   arguments))
        (while (pair? params)
          (or (pair? args) (error "too few arguments for "fun": "arguments))
          (set (array-at locals (unbox <long> (<variable>-index (get/head params))))
               (get/head args))
          (set params	(get/tail params))
          (set args	(get/tail args)))
        ;; the cdr position
        (when (is <variable> params)
          (set (array-at locals (unbox <long> (<variable>-index params))) args)
          (set args ()))
        (when args
          (error "too many arguments for "fun": "arguments)))
      (let ((prg (<expr>-body fun))
            (result ()))
        (list-do exp prg
          (set result (eval exp innter-ctx)))
        (when (<env>-stable env)
          (set (<context>-callee innter-ctx) ()))
        result))))

(define-function apply (fun arguments ctx)
  (debug (libc/printf "apply, function ") (print fun) (libc/printf ", arguments: ") (print arguments) (libc/printf "\n"))
  (with-new-call-frame (symbol/apply fun arguments)
    (let ((type (type-of fun)))
      ;; TODO use typecase
      (cond
        ((= type <expr>)
         (apply/expr fun arguments ctx))

        ((= type <primitive-function>)
         ((<primitive-function>-_imp fun) arguments ctx))

        (else
         (aif (and *applicators*
                   (set it (maybe-object-in-variable *applicators* <array>))
                   (array-at it type))
             (gc/let* ((args (cons fun arguments)))
               (apply it args ctx))
           (error "cannot apply: "fun", current module: "*module*", *applicators* is: "
                  (and *applicators* (<variable>-value *applicators*)))))))))

(define-primitive-function (apply ()) (fn args)
  (apply fn args -ctx-))

;;;
;;; expand
;;; ----------------------------------------------------------------

(define-function maybe-form-in-env/function (env name)
  (awhen (maybe-object-in-env env name <form>)
    (<form>-function it)))

(define-function maybe-form-in-env/symbol (env name)
  (awhen (maybe-object-in-env env name <form>)
    (<form>-symbol it)))

(define-function expand-all (list env one-step?)
  (if (pair? list)
      (gc/let* ((head (expand		(get/head list) env one-step?))
                (tail (expand-all	(get/tail list) env one-step?)))
        (cons head tail))
    (expand list env one-step?)))

(define-function setter-name-for (fn-name env)
  (gc/let* ((buf (buffer)))
    (buffer-append-string buf "set-")
    (buffer-append-string buf (unbox <symbol> fn-name))
    (let ((setter-name (string->symbol (buffer-contents buf))))
      (when (maybe-object-in-env env setter-name ())
        setter-name))))

(define-function maybe-fn-name-from-expr (expr)
  (when (pair? expr)
    (let ((fn-name (get/head expr)))
      (when (symbol? fn-name)
        fn-name))))

(define-function attempt-set-convert (place value env one-step?)
  (let ((fn-name (maybe-fn-name-from-expr place)))
    (when fn-name
      ;; it's a set form such as: (set (fn-name a b c) new-value). let's try to convert it to
      ;; (set-fn-name a b c new-value) if set-fn-name is defined.
      (awhen (setter-name-for fn-name env)
        ;; TODO the value should be inserted as the first arg to not disrupt &rest parsing
        (gc/let* ((args (get/tail place))
                  (last (cons value ())))
          (set args (expand-all args env one-step?))
          (set args (concat-list args last))
          (cons it args))))))

(define-function expand/pair (exp env one-step? -call-frame-)
  (gc/let* ((head (expand (get/head exp) env one-step?)))
    (debug (libc/printf "expand/pair on head ") (println head))
    (when-at-expand feature/backtrace
      (unless (= head (get/head exp))
        (set (<call-frame>-callee		-call-frame-) head))
      (set (<call-frame>-arguments		-call-frame-) exp))
    (let (expander)
      ;; TODO use switch
      (cond
        ((= head symbol/let)
         ;; TODO use a collecting macro to simplify this
         (gc/let* ((new-bindings ()))
           (let ((bindings (cadr exp))
                 new-bindings/last)
             (list-do entry bindings
               (let (var-name)
                 (gc/let* (var-init-prog)
                   (if (pair? entry)
                       (let ()
                         (set var-name		(get/head entry))
                         (set var-init-prog	(expand-all (get/tail entry) env one-step?)))
                     (set var-name	entry)
                     (set var-init-prog	(cons () ())))
                   (gc/let* ((new-entry (cons var-name var-init-prog)))
                     (set new-bindings/last (if new-bindings
                                                (put/tail new-bindings/last (cons new-entry ()))
                                              (set new-bindings (cons new-entry ())))))))))
           (gc/let* ((tmp (expand-all (cddr exp) env one-step?))) ; the body
             (set tmp (cons new-bindings tmp))
             (set tmp (cons symbol/let tmp))
             tmp)))

        ((= head symbol/quote)
         (cons symbol/quote (get/tail exp)))

        ((= head symbol/set)
         (safety 1 (assert (and (cddr exp) (not (cdddr exp))) "illegal set form: " exp))
         (debug (libc/printf "expand/set on form ") (println exp))
         ;; try to set-transform (set (place-accessor ...) value) forms while expanding. try "more abstract" set-foo forms first,
         ;; and only recursively expand the body if they are not defined.
         ;; this setup allows defining e.g. a SET-SLOT-VALUE form to override its behavior. the old way was to first expand
         ;; the body, i.e. a (SLOT-VALUE ...) form into an (OOP-AT ...) form, and only then attempt to set-convert it to SET-OOP-AT.
         (let ((vanilla-place	(second exp)))
           (gc/let* ((value	(expand (third exp) env one-step?))
                     (converted	(attempt-set-convert vanilla-place value env one-step?)))
             (if converted
                 (if one-step?
                     converted
                   (expand converted env one-step?))
               ;; we descend here with one-step? = true, so that we can attempt the set-conversion at each step of expansion
               (gc/let* ((expanded-place (expand vanilla-place env true)))
                 (if (set converted (attempt-set-convert expanded-place value env one-step?))
                     (if one-step?
                         converted
                       (expand converted env one-step?))
                   (let ((fn-name (maybe-fn-name-from-expr expanded-place)))
                     ;; we need to "look ahead" and only attempt recursive expansion when there's any work left to do.
                     ;; otherwise the following form would lead to infinite recursion: (set (without-set-version ...) ...)
                     (set converted (list3 symbol/set expanded-place value))
                     (if (and (not one-step?)
                              fn-name
                              (setter-name-for fn-name env))
                         (expand converted env one-step?)
                       converted))))))))

        ((= head symbol/define)
         (safety 1 (assert (not (cdddr exp)) "illegal define form: " exp))
         (let ((name	(second exp))
               (value	(third exp)))
           (gc/let* ((expanded-value (expand value env one-step?)))
             (list3 symbol/define name expanded-value))))

        ((= head symbol/lambda)
         (let ((params	(cadr exp))
               (body	(cddr exp)))
           (gc/let* ((tmp (expand-all body env one-step?)))
             (set tmp (cons params tmp))
             (cons symbol/lambda tmp))))

        ((set expander (maybe-form-in-env/function env head))
         ;; head is a <form> found in *env* (which may hold lexically scoped forms, and i think delegates all the way up to the module's env)
         (gc/let* ((args (cons env (get/tail exp)))
                   (expansion (apply expander args ())))
           (debug (libc/printf "expand/pair, found in local env, expanded to ") (println expansion))
           (if one-step?
               expansion
             (expand expansion env one-step?))))

        (else
         ;; head is not a <form> nor a fixed special form
         (gc/let* ((tail (expand-all (get/tail exp) env one-step?)))
           (cons head tail)))))))

(define-function expand/symbol (exp env one-step?)
  (debug (libc/printf "expand/symbol, exp ") (print exp) (libc/printf ", env ") (println env))
  (aif (maybe-form-in-env/symbol env exp)
      ;; head is a <form> found in *env* (which may hold lexically scoped forms, and i think delegates all the way up to the module's env)
      (gc/let* ((args (list2 env exp))
                (expansion (apply it args ())))
        (debug (libc/printf "expand/symbol, found in local env, expanded to ") (println expansion))
        (if one-step?
            expansion
          (expand expansion env one-step?)))
    exp))

;; TODO that <long> for the boolean is not ok
(define-primitive-function expand (exp (env <env> (<context>-env -ctx-)) (one-step? <long> false))
  (debug (libc/printf "expand, exp ") (print exp) (libc/printf ", env ") (println env))
  (with-new-call-frame (symbol/expand () exp)
    ;; TODO use typecase
    (cond
      ((pair? exp)	(expand/pair	exp env one-step? -call-frame-))
      ((symbol? exp)	(expand/symbol	exp env one-step?))
      (else
       ;; consult the *expanders* array to see if there's any custom expander for this type
       (aif (and *expanders*
                 (set it (maybe-object-in-variable *expanders* <array>))
                 (array-at it (type-of exp)))
           (gc/let* ((args (cons exp ())))
             (apply it args ()))
         exp)))))

;;;
;;; encode
;;; ----------------------------------------------------------------

(define-function encode-all (list env)
  (if (pair? list)
      (gc/let* ((head (encode		(get/head list) env))
                (tail (encode-all	(get/tail list) env)))
        (cons head tail))
    (encode list env)))

(define-function encode/pair (exp env)
  (gc/let* ((head (encode (get/head exp) env))
            (tail (get/tail exp)))
    (debug (libc/printf "encode/pair of head ") (print head) (libc/printf ", in env ") (println env))
    ;; TODO use switch
    (cond
      ((= head fixed-primitive-function/let)
       ;; KLUDGE? to make encode idempotent, this is how we detect that this let has already been encoded. same below.
       (unless (is <env> (first tail))
         (gc/let* ((vars	())
                   (inner-env	(environment env 0 (unbox <long> (<env>-offset env)))))
           ;; phase 1: first define the let variables into inner-env
           (let (vars/last)
             (list-do entry (first tail)
               (debug (libc/printf "encode/let visiting entry ") (println entry))
               (let* ((var-name	(first entry))
                      (var-obj	(environment-define inner-env var-name ())))
                 (set vars/last (if vars
                                    (put/tail vars/last (cons var-obj ()))
                                  (set vars (cons var-obj ())))))))
           ;; update the offset of the parent env to "skip" the indices of our let variables
           (set (<env>-offset env) (<env>-offset inner-env))
           ;; phase 2: encode-all the init-progs and build the new bindings list
           (gc/let* (var
                     new-bindings)
             (let (new-bindings/last)
               (list-do entry (first tail)
                 (gc/let* ((init-prog	(encode-all (get/tail entry) env))
                           (new-entry	(cons (pop vars) init-prog)))
                   (set new-bindings/last (if new-bindings
                                              (put/tail new-bindings/last (cons new-entry ()))
                                            (set new-bindings (cons new-entry ())))))))
             (set tail (encode-all (cdr tail) inner-env)) ; encode the body
             (set tail (cons new-bindings tail))
             (set tail (cons inner-env tail))))))

      ((= head fixed-primitive-function/lambda)
       (let ((args (first tail)))
         (unless (is <env> args)
           (gc/let* ((inner-env (environment env 1 0)))
             (while (pair? args)
               (environment-define inner-env (get/head args) ())
               (set args (get/tail args)))
             (when args
               (environment-define inner-env args ()))
             (set tail (encode-all tail inner-env))
             (set tail (cons inner-env tail))))))

      ((= head fixed-primitive-function/define)
       (unless (is <variable> (first tail))
         ;; DEFINE unconditionally defines into *globals*
         ;; TODO ponder about this... it leads to a somewhat confusing behavior.
         ;; maybe DEFINE should define locally that sometimes happens to be *globals*?
         ;; what about this: (define foo (lambda (arg) (define nested 42)))
         (let ((var (environment-define (module-env *module*) (first tail) ())))
           (set tail (encode-all (cdr tail) env))
           (set tail (cons var tail)))))

      ((= head fixed-primitive-function/set)
       (unless (is <variable> (first tail))
         (let ((var (or (defined? (first tail) env)
                        (error "set: undefined variable: " (first tail)))))
           (assert (and (car tail) (not (cddr tail))) "encode: malformed SET expression: "exp)
           (set tail (encode-all (cdr tail) env))
           (set tail (cons var tail)))))

      ((= head fixed-primitive-function/quote)) ; ignore quotes

      (else
       (set tail (encode-all tail env))))
    ;; return value
    (cons head tail)))

(define-function encode/symbol (exp env)
  (debug (libc/printf "encode/symbol of %s" (unbox <symbol> exp)) (libc/printf ", in env ") (println env))
  (let ((var (or (defined? exp env)
                 (error "encode/symbol: failed for "exp", current module "*module*", env "env))))
    (if (global-variable? var)
        (let ((val (<variable>-value var)))
          (when (or (is <form> val)
                    (is <fixed> val))
            (return val)))
      (let ((venv (<variable>-env var)))
        (unless (= (unbox <long> (<env>-level venv))
                   (unbox <long> (<env>-level env)))
          (set (<env>-stable venv) symbol/true))))
    var))

(define-primitive-function encode (exp (env <env> (<context>-env -ctx-)))
  (debug (libc/printf "encode of exp ") (print exp) (libc/printf ", in env ") (println env))
  (with-new-call-frame (symbol/encode () exp)
    (debug (libc/printf "encode is dispatching on type %ld\n" (type-of exp)))
    ;; TODO use typecase
    (cond
      ((pair? exp)	(encode/pair	exp env))
      ((symbol? exp)	(encode/symbol	exp env))
      (else
       (aif (and *encoders*
                 (set it (maybe-object-in-variable *encoders* <array>))
                 (array-at it (type-of exp)))
           (gc/let* ((args (list2 exp env)))
             (debug (libc/printf "encode/other: applying fn: ") (println it) (libc/printf " ") (print args) (libc/printf " ") (println env))
             (apply it args ()))
         exp)))))

;;;
;;; eval
;;; ----------------------------------------------------------------

(define-function eval-all (obj ctx)
  (if (pair? obj)
      (gc/let* ((head (eval	(get/head obj) ctx))
                (tail (eval-all	(get/tail obj) ctx)))
        (cons head tail))
    obj))

(define-function eval/with-call-frame (type exp ctx)
  (with-new-call-frame (() () ())
    (cond
      ((= type <pair>)
       (when-at-expand feature/backtrace
         (set (<call-frame>-callee-designator	-call-frame-) (get/head exp))
         (set (<call-frame>-arguments		-call-frame-) (get/tail exp)))
       (gc/let* ((evaled-head (eval (get/head exp) ctx)))
         (debug (libc/printf "eval of pair, head eval'ed to ") (println evaled-head))
         (when-at-expand feature/backtrace
           (set (<call-frame>-callee -call-frame-) evaled-head))
	 (if (is <fixed> evaled-head)
	     (apply (<fixed>-function evaled-head) (get/tail exp) ctx)
	   (gc/let* ((args (eval-all (get/tail exp) ctx)))
             (when-at-expand feature/backtrace
               (set (<call-frame>-arguments -call-frame-) args))
             (apply evaled-head args ctx)))))
      (else
       (when-at-expand feature/backtrace
         (set (<call-frame>-callee-designator -call-frame-) exp))
       (aif (and *evaluators*
                 (set it (maybe-object-in-variable *evaluators* <array>))
                 (array-at it type))
	   (gc/let* ((args (cons exp ())))
	     (when-at-expand feature/backtrace
               (set (<call-frame>-callee -call-frame-) it))
	     (apply it args ctx))
         exp)))))

(define-function eval (exp ctx)
  (verbosity 3 (platform/print "  E  ") (print exp) (platform/print " ") (println ctx))
  (let ((type (type-of exp)))
    ;; TODO use typecase
    (cond
      ((= type <undefined>)	exp)
      ((= type <long>)		exp)
      ((= type <string>)	exp)
      ((= type <variable>)	(if (global-variable? exp)
				    (let ()
                                      (debug (libc/printf "eval is reading global var ") (println exp))
                                      (<variable>-value exp))
				  (let ((delta (- (unbox <long> (<env>-level (<context>-env ctx)))
					      (unbox <long> (<env>-level (<variable>-env exp))))))
				    (debug (libc/printf "eval is reading local var ") (print exp) (libc/printf " with delta %ld\n" delta))
				    (while (< 0 delta)
				      (set ctx (<context>-home ctx))
				      (decr delta))
                                    (let* ((index (unbox <long> (<variable>-index exp)))
                                           (value (array-at (<context>-bindings ctx) index)))
                                      (debug (libc/printf "eval is reading local var from context ") (print ctx) (libc/printf " at index %ld, holding value " index) (println value))
				      value))))
      ((= type <symbol>)	(error "encountered a <symbol> in eval. this shouldn't happen!"))
      (else			(eval/with-call-frame type exp ctx)))))


(define-function expand-encode-eval (form env)
  (debug (libc/printf "expand-encode-eval for form ") (println form))
  (gc/let* ((x form)
            (ctx (base-context () env)))
					(verbosity 2 (platform/print ";;; ? ")		(println x))
    (set x (expand x env false))	(verbosity 2 (platform/print ";;; expd--> ")	(println x))
    (set x (encode x env))		(verbosity 2 (platform/print ";;; encd--> ")	(println x))
    (set x (eval   x ctx))
					(verbosity 2 (platform/print ";;; => ")		(println x))
    (debug (libc/printf "expand-encode-eval for form ") (print form) (libc/printf " is returning with ") (println x))
    x))

(define-primitive-function module ((name <string>))
  (debug (libc/printf "module constructor\n"))
  (gc/let* ((module (new <module>))
            (env    (environment () 0 0))
            tmp)
    (when-at-expand feature/debug-info
      (set (<module>-name module)
	   (string-from-cstring (or name ""))))

    (set (<module>-globals module)
	 (environment-define env symbol/*globals* env))

    (when *maru-module*
      ;; *globals* is special in that it should point back to the module's env, therefore we skip that
      (copy-module-bindings *maru-module* module
                            (lambda (name value)
                              (not (= name symbol/*globals*)))))

    ;; overwrite these with empty arrays in the new module. TODO why? maybe clone the array instead?
    (let ((doit (lambda (env name)
                  (gc/let* ((tmp (array 0)))
                    (set (<variable>-value (or (defined? name env)
                                               (new-variable env name)))
                         tmp)))))
      (doit env symbol/*expanders*)
      (doit env symbol/*encoders*)
      (doit env symbol/*evaluators*)
      (doit env symbol/*applicators*))

    (debug (libc/printf "module constructor returning with ") (println module))
    module))

(when-at-expand feature/profiler
  ;; these are coming from profiler.c
  (define-C-function install_profiler_handler void install_profiler_handler (*))
  (define-C-function set_profiler_interval void set_profiler_interval (int))

  (define profiler/sample-counter 0)

  (define-function profiler/take-sample-at-frame (frame)
    (let* ((callee	(<call-frame>-callee frame))
           (callee-type	(type-of callee)))
      (with-forms ((incr-boxed ((place) `(set ,place (box <long> (+ 1 (unbox <long> ,place)))))))
        ;; TODO use typecase
        (cond
          ((= callee-type <expr>)
           (incr-boxed (<expr>-profiler-counter callee)))

          ((= callee-type <primitive-function>)
           (incr (<primitive-function>-profiler-counter callee)))))))

  (define-function profiler/take-sample (_)
    (incr profiler/sample-counter)
    (if-at-expand feature/profiler/cumulative
        (for (i 0 *call-stack-index*)
          (profiler/take-sample-at-frame (array-at *call-stack* i)))
      (awhen (current-call-frame)
        (profiler/take-sample-at-frame it))))

  (define-function profiler/disable ()
    (set_profiler_interval 0)
    (when (< 0 profiler/sample-counter)
      (platform/print-diagnostics "Profiler took "(get/string (long->string profiler/sample-counter)) " samples:\n")
      (let ((obj (gc/first-object)))
        (while obj
          (let ((type (type-of obj))
                (name ())
                (counter ()))
            (cond
              ((and (= type <expr>)
                    (< 0 (set counter (unbox <long> (<expr>-profiler-counter obj)))))
               (set name (<expr>-name obj))
               (when name
                 (set name (unbox <symbol> name))))

              ((and (= type <primitive-function>)
                    (< 0 (set counter (<primitive-function>-profiler-counter obj))))
               (set name (<primitive-function>-_name obj))))
            (when counter
              (platform/print-diagnostics (get/string (long->string counter)) "\t" (or name "n/a") "\n")))
          (set obj (gc/next-object obj)))))))
