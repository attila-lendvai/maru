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
    (environment-define (module-env module) (u/string->symbol name) tmp)))

(define-form instantiate-primitive-functions (module)
  `(let ((__module__ ,module))
     ,@(map (lambda (entry)
              (let* (((name fixed?)	entry)
                     (impl-name		(concat-symbol name '/evaluator-stub)))
                `(instantiate-primitive-function __module__ ,(symbol->string name) ,impl-name ,(if fixed? 'true 'false))))
            *primitive-function-registry*)))

(define-function populate-module-with-maru-primitives (module)
  (debug-print "populate-module-with-maru-primitives for module "module)
  (let ((env (module-env module)))
    (gc/let* ((tmp))
      ;; TODO this way *verbosity* in the evaluator and in the target is not in sync. see how *standard-output* is defined.
      (set tmp (box <long> *verbosity*))	(environment-define env (u/string->symbol "*verbosity*")		tmp)
      (set tmp (box <long> *optimised*))	(environment-define env (u/string->symbol "*optimised*")		tmp)
      ;; create an uninterned singleton symbol (i.e. a unique identity that cannot be recreated in any other way)
      (gc/let* ((name (string-from-cstring "+end+")))
        (set +end+ (or +end+ (set tmp (symbol name))))
        ;; then define this value in the global env under the +end+ name, which is a normal, interned symbol.
        (environment-define env (string->symbol name) +end+)))

    ;; make sure the symbol true evaluates to itself
    (environment-define env symbol/true symbol/true)

    (environment-define env (u/string->symbol "*maru-module*") *maru-module*)

    (instantiate-primitive-functions module)

    (with-forms ((var-value ((name) `(<variable>-value (defined? ,name env)))))
      (set fixed-primitive-function/quote	(var-value symbol/quote))
      (set fixed-primitive-function/lambda	(var-value symbol/lambda))
      (set fixed-primitive-function/let		(var-value symbol/let))
      (set fixed-primitive-function/define	(var-value symbol/define))
      (set fixed-primitive-function/set		(var-value symbol/set)))

    (assert (and (is <fixed> fixed-primitive-function/quote) (is <fixed> fixed-primitive-function/lambda) (is <fixed> fixed-primitive-function/let) (is <fixed> fixed-primitive-function/define) (is <fixed> fixed-primitive-function/set)) "populate-module-with-maru-primitives: final assert")))

(define-function capture-well-known-module-values ()
  (debug-print "capture-well-known-module-values from *module*, which is "module)
  ;; let's cache some values from *module* to speed up their access in tight loops
  (let ((env (module-env *module*)))
    (set *expanders*	(defined? symbol/*expanders*	env))
    (set *encoders*	(defined? symbol/*encoders*	env))
    (set *evaluators*	(defined? symbol/*evaluators*	env))
    (set *applicators*	(defined? symbol/*applicators*	env)))

  (debug-print "capture-well-known-module-values is done"))

(define-function initialize-vm ()
  (debug (platform/print-diag "alive"))

  (gc/initialize)

  (safety 4 (set gc/frequency 1))
  (debug (platform/print-diag "gc initialized"))
  (assert (= <long>	(type-of (box <long> 42)))	"type-of for <long> is broken")
  (assert (= 42		(unbox <long> (box <long> 42)))	"unbox of <long> is broken")
  (assert (= 1 true)	"true is not 1")
  (assert (= 0 false)	"false is not 0")

  (gc/push-root (address-of *module*))
  (gc/push-root (address-of *maru-module*))
  (gc/push-root (address-of *symbols*))

  (debug (platform/print-diag "gc roots registered"))

  (when-at-expand feature/backtrace
    (debug (platform/print-diag "initializing *call-stack*"))
    (gc/push-root (address-of *call-stack*))
    (set *call-stack* (array 32)))

  (set *symbols* (array 32))
  (initialize-symbol-cache)
  (debug (platform/print-diag "initialized *symbols*"))

  (set *maru-module* (module "maru"))
  (populate-module-with-maru-primitives *maru-module*)
  (debug (platform/print-diag "initialized *maru-module*"))

  (set *module* (module "maru-user"))
  (capture-well-known-module-values)
  (debug (platform/print-diag "finished module initialization")))
