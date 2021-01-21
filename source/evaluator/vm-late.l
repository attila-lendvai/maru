;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; the primitive-functions
;;;
;;; ----------------------------------------------------------------

(load "source/evaluator/primitive-functions.l")

(define-function instantiate-primitive-function (module name imp fixed?)
  (gc/let* ((tmp (primitive-function imp name)))
    (when fixed?
      (set tmp (fixed tmp)))
    (environment-define (module-env module) (string->symbol name) tmp)))

(define-form instantiate-primitive-functions (module)
  `(let ((__module__ ,module))
     ,@(map (lambda (entry)
              (let* (((name fixed?)	entry)
                     (impl-name		(concat-symbol name '/evaluator-stub)))
                `(instantiate-primitive-function __module__ ,(symbol->string name) ,impl-name ,(if fixed? 'true 'false))))
            *primitive-function-registry*)))

(define-function populate-module-with-maru-primitives (module)
  (debug (libc/printf "populate-module-with-maru-primitives for module {%p}\n" module))
  (let ((env (module-env module)))
    (gc/let* ((tmp))
      (set tmp (box <long> *verbosity*))	(environment-define env (string->symbol "*verbosity*")		tmp)
      (set tmp (box <long> *optimised*))	(environment-define env (string->symbol "*optimised*")		tmp)
      ;; an uninterned singleton symbol, i.e. a unique identity that cannot be recreated any other way
      (set +end+ (or +end+ (set tmp (symbol "+end+"))))
      (environment-define env (string->symbol "+end+") +end+))

    ;; make sure the symbol true evaluates to itself
    (environment-define env symbol/true symbol/true)

    (environment-define env (string->symbol "*maru-module*") *maru-module*)

    (instantiate-primitive-functions module)

    (with-forms ((var-value ((name) `(<variable>-value (defined? ,name env)))))
      (set fixed-primitive-function/quote	(var-value symbol/quote))
      (set fixed-primitive-function/lambda	(var-value symbol/lambda))
      (set fixed-primitive-function/let		(var-value symbol/let))
      (set fixed-primitive-function/define	(var-value symbol/define))
      (set fixed-primitive-function/set		(var-value symbol/set)))

    (assert (and (is <fixed> fixed-primitive-function/quote) (is <fixed> fixed-primitive-function/lambda) (is <fixed> fixed-primitive-function/let) (is <fixed> fixed-primitive-function/define) (is <fixed> fixed-primitive-function/set)) "populate-module-with-maru-primitives: final assert")))

(define-function capture-well-known-module-values ()
  (debug (libc/printf "capture-well-known-module-values from *module*, which is %p\n" *module*))
  ;; let's cache some values from *module* to speed up their access in tight loops
  (let ((env (module-env *module*)))
    (set *expanders*	(defined? symbol/*expanders*	env))
    (set *encoders*	(defined? symbol/*encoders*	env))
    (set *evaluators*	(defined? symbol/*evaluators*	env))
    (set *applicators*	(defined? symbol/*applicators*	env)))

  (debug (libc/printf "capture-well-known-module-values is done\n")))

(define-function initialize-vm ()
  (debug (libc/printf "alive\n"))

  (gc/initialize)

  (safety 4 (set gc/frequency 1))
  (debug (libc/printf "gc initialized\n"))
  (assert (= <long>	(type-of (box <long> 42)))	"type-of for <long> is broken")
  (assert (= 42		(unbox <long> (box <long> 42)))	"unbox of <long> is broken")
  (assert (= 1 true)	"true is not 1")
  (assert (= 0 false)	"false is not 0")

  (gc/push-root (address-of *module*))
  (gc/push-root (address-of *maru-module*))
  (gc/push-root (address-of *symbols*))

  (when-at-expand feature/backtrace
    (debug (libc/printf "initializing *call-stack*\n"))
    (gc/push-root (address-of *call-stack*))
    (set *call-stack* (array 32)))

  (set *symbols* (array 32))
  (initialize-symbol-cache)
  (debug (libc/printf "initialized *symbols*\n"))

  (set *maru-module* (module "maru"))
  (populate-module-with-maru-primitives *maru-module*)
  (set *module* (module "maru-user"))
  (capture-well-known-module-values)
  (debug (libc/printf "finished module initialization\n")))
