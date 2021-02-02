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
  (debug-print "populate-module-with-maru-primitives for module "module)
  (let ((env (module-env module)))
    (gc/let* ((tmp))
      ;; TODO this way *verbosity* in the evaluator and in the target is not in sync. see how *standard-output* is defined.
      (set tmp (box <long> *verbosity*))	(environment-define env (string->symbol "*verbosity*")		tmp)
      (set tmp (box <long> *optimised*))	(environment-define env (string->symbol "*optimised*")		tmp)
      ;; create an uninterned singleton symbol (i.e. a unique identity that cannot be recreated in any other way)
      (set +end+ (or +end+ (set tmp (symbol (string-from-cstring "+end+")))))
      ;; then define this value in the global env under the +end+ name, which is a normal, interned symbol.
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
  (debug-print "capture-well-known-module-values from *module*, which is "module)
  ;; let's cache some values from *module* to speed up their access in tight loops
  (let ((env (module-env *module*)))
    (set *expanders*	(defined? symbol/*expanders*	env))
    (set *encoders*	(defined? symbol/*encoders*	env))
    (set *evaluators*	(defined? symbol/*evaluators*	env))
    (set *applicators*	(defined? symbol/*applicators*	env)))

  (debug-print "capture-well-known-module-values is done"))

(define-function initialize-vm ()
  (debug (platform/print-diag "alive\n"))

  (gc/initialize)

  (safety 4 (set gc/frequency 1))
  (debug (platform/print-diag "gc initialized\n"))
  (assert (= <long>	(type-of (box <long> 42)))	"type-of for <long> is broken")
  (assert (= 42		(unbox <long> (box <long> 42)))	"unbox of <long> is broken")
  (assert (= 1 true)	"true is not 1")
  (assert (= 0 false)	"false is not 0")

  (gc/push-root (address-of *module*))
  (gc/push-root (address-of *maru-module*))
  (gc/push-root (address-of *symbols*))

  (when-at-expand feature/backtrace
    (debug-print "initializing *call-stack*")
    (gc/push-root (address-of *call-stack*))
    (set *call-stack* (array 32)))

  (set *symbols* (array 32))
  (initialize-symbol-cache)
  (debug-print "initialized *symbols*")

  (set *maru-module* (module "maru"))
  (populate-module-with-maru-primitives *maru-module*)
  (set *module* (module "maru-user"))
  (capture-well-known-module-values)
  (debug-print "finished module initialization"))

(define-function process-command-line-arguments (argc argv)
  (debug-print "start processing argv")

  ;; *command-line-arguments*
  (let ((cla-var (environment-define (module-env *module*) (string->symbol "*command-line-arguments*") ())))
    ;; initialize *cla*
    (gc/let* ((tmp ()))
      (let ((idx argc))
        (while (< 0 (decr idx)) ; skip the first, which is the name of the executable
          (set tmp (cons () tmp))
          (put/head tmp (string-from-cstring (oop-at argv idx)))
          (debug-print "processing argv "(box <long> idx)" = "(get/head tmp))))
      (set (<variable>-value cla-var) tmp))

    (debug-print "*command-line-arguments* is initialized to: " (<variable>-value cla-var))

    ;; process *cla*
    (let (cla
          arg)
      (gc/let* (arg-string
                tmp)
        (with-forms ((pop-cla (_ '(set (<variable>-value cla-var) (set cla (get/tail cla))))))
          (while (pair? (set cla (<variable>-value cla-var)))
            (set arg-string	(get/head cla))
            (set arg		(get/string arg-string))
            (pop-cla)
            (cond
              ;; -v
              ((libc/string= arg "-v")
               (incr *verbosity*)
               (set tmp (box <long> *verbosity*))
               (set (global-variable-value (string->symbol "*verbosity*")) tmp))

              ;; -O
              ((libc/string= arg "-O")
               (incr *optimised*)
               (set tmp (box <long> *optimised*))
               (set (global-variable-value (string->symbol "*optimised*")) tmp))

              ;; -p
              ((libc/string= arg "-p")
               (if-at-expand feature/profiler
                   (let ((usecs 1000))
                     (install_profiler_handler profiler/take-sample)
                     (set_profiler_interval usecs)
                     (platform/print-diag "profiling at every %ld uSec(s)\n" usecs))
                 (platform/print-diag "WARNING: this build has no profiler, ignoring -p\n")))

              ;; -
              ((libc/string= arg "-")
               (repl-stream *standard-input*))

              ;; --call to call a function
              ((libc/string= arg "--call")
               (debug-print "processing a --call")
               (unless (pair? cla)
                 (fatal "--call requires an argument"))
               (set arg-string (get/head cla))
               (set arg (get/string arg-string))
               (pop-cla)
               (let ((sym (string->symbol arg)))
                 (gc/let* ((form (cons sym ())))
                   (expand-encode-eval form (module-env *module*)))))

              ;; --define to define a variable
              ((libc/string= arg "--define")
               (debug-print "processing a --define")
               (unless (and (pair? cla)
                            (pair? (get/tail cla)))
                 (fatal "--define requires two arguments"))
               (gc/let* ((name	(first  cla))
                         (value	(second cla)))
                 (pop-cla)
                 (pop-cla)
                 ;; convert to long when possible
                 (let ((i (string->long* value 10)))
                   (unless (= +end+ i)
                     (set value (box <long> i))))
                 (environment-define (module-env *module*)
                                     (string->symbol (get/string name))
                                     value)))

              ;; read file as a program
              (else
               (verbosity 1 (platform/print-diag "loading file: "arg"\t(as a CLA)\n"))
               (with-input-from-file (stream arg-string)
                 (repl-stream stream))))))))))
