;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; the primitive-functions
;;;
;;; ----------------------------------------------------------------

(load "source/evaluator/primitive-functions.l")

(define-function %instantiate-primitive-function (env name imp fixed?)
  ;; NOTE <target-function> is an opaque object, but it's ok to use
  ;; <symbols>'s as their name because they are held as gc roots by
  ;; the *symbols* array.
  (gc/let* ((tmp (primitive-function (box <target-pointer> imp) name)))
    (when fixed?
      (set tmp (fixed tmp)))
    ;; NOTE string->symbol doesn't need gc/let* because *symbols* is a gc root
    (environment-define env (string->symbol name) tmp)))

(define-form %instantiate-primitive-functions (env)
  `(let ()
     ,@(map (lambda (entry)
              (let* (((name fixed?)	entry)
                     (impl-name		(concat-symbol name '/evaluator-stub)))
                `(%instantiate-primitive-function ,env ,(symbol->string name) ,impl-name ,(if fixed? 'true 'false))))
            *primitive-function-registry*)))

(define-function populate-env-with-maru-primitives (env)
  (debug-print "populate-env-with-maru-primitives for env "env)
  (gc/let* ((tmp))
    (set tmp (box <long> *verbosity*)) (environment-define env symbol/*verbosity* tmp)
    (set tmp (box <long> *optimised*)) (environment-define env symbol/*optimised* tmp)
    ;; create an uninterned singleton symbol (i.e. a unique identity that cannot be recreated in any other way)
    (set +end+ (or +end+ (set tmp (symbol "+end+"))))
    ;; then define this value in the global env under the +end+ name, which is a normal, interned symbol.
    (environment-define env (string->symbol "+end+") +end+))

  ;; make sure the symbol true evaluates to itself
  (environment-define env symbol/true symbol/true)

  (environment-define env (string->symbol "*maru*") *maru*)

  (%instantiate-primitive-functions env)

  (with-forms ((var-value ((name) `(<variable>-value (defined? ,name env)))))
    (set fixed-primitive-function/quote	(var-value symbol/quote))
    (set fixed-primitive-function/lambda	(var-value symbol/lambda))
    (set fixed-primitive-function/let		(var-value symbol/let))
    (set fixed-primitive-function/define	(var-value symbol/define))
    (set fixed-primitive-function/set		(var-value symbol/set)))

  (let ((doit (lambda (env name)
                (gc/let* ((tmp (array 0)))
                  (set (<variable>-value (or (defined? name env)
                                             (new-variable env name)))
                       tmp)))))
    (doit env symbol/*expanders*)
    (doit env symbol/*encoders*)
    (doit env symbol/*evaluators*)
    (doit env symbol/*applicators*))

  (assert (and (is <fixed> fixed-primitive-function/quote) (is <fixed> fixed-primitive-function/lambda) (is <fixed> fixed-primitive-function/let) (is <fixed> fixed-primitive-function/define) (is <fixed> fixed-primitive-function/set)) "populate-env-with-maru-primitives: final assert"))

(define-function capture-well-known-globals ()
  (debug-print "capture-well-known-globals, *globals* is "*globals*)
  ;; let's cache some values from *globals* to speed up their access in tight loops
  (let ((env *globals*))
    ;; TODO find a smarter way than this.
    ;; TODO the -var suffix is needed to avoid hiding the meta-level's arrays
    (set *expanders-var*	(defined? symbol/*expanders*	env))
    (set *encoders-var*		(defined? symbol/*encoders*	env))
    (set *evaluators-var*	(defined? symbol/*evaluators*	env))
    (set *applicators-var*	(defined? symbol/*applicators*	env)))

  (debug-print "capture-well-known-globals is done"))

(define-function initialize-vm ()
  (debug (platform/diag-print "initialize-vm is alive\n"))

  (safety 2
    (or (= 42 (unbox <long> (box <long> 42)))		(fatal "box-unbox of <long> is broken"))
    (when-at-expand (eval-in-slave '(is <immediate-type> <long>))
      (or (= 85 (box <long> 42))			(fatal "box of <long> is broken"))
      (or (= 42 (unbox <long> 85))			(fatal "unbox of <long> is broken")))
    (or (= <long> (type-of (box <long> 42)))		(fatal "type-of for <long> is broken"))
    (or (= 42 (unbox <long> (box <long> 42)))		(fatal "unbox of <long> is broken"))
    (or (= 1 true)					(fatal "true is not 1"))
    (or (= 0 false)					(fatal "false is not 0"))
    (let ((lit-str "a literal string"))
      (or (= <string> (type-of lit-str))	(fatal "type-of a literal <string> is broken"))
      (or (string? lit-str)			(fatal "string? for a literal <string> is broken"))
      (or (= 16 (string-length lit-str))	(fatal "string-length broken for a literal <string>"))))

  (gc/initialize)

  (safety 4 (set gc/allocations-until-gc 1))
  (debug (platform/diag-print "gc initialized\n"))

  (gc/push-root (address-of *globals*))
  (gc/push-root (address-of *symbols*))
  (gc/push-root (address-of *maru*))

  (debug (platform/diag-print "gc roots registered\n"))

  (set *symbols* (array 32))
  (initialize-symbol-cache)
  (debug (platform/diag-print "initialized *symbols*\n"))

  (safety 2
    (let ((str (string 16)))
      (string-append-all str "foo")
      (string-append-all str "bar")
      (or (string= str "foobar") (fatal "string-append-all is broken"))))

  (when-at-expand feature/backtrace
    (debug (platform/diag-print "initializing *call-stack*\n"))
    (gc/push-root (address-of *call-stack*))
    (set *call-stack* (array 32)))

  (set *maru* (environment () 0 0))                            (when-at-expand feature/debug-info (set (<env>-name *maru*) "maru"))
  (populate-env-with-maru-primitives *maru*)
  (environment-define *maru*
                      (string->symbol "*maru*")
                      *maru*)
  (debug (platform/diag-print "initialized *maru*\n"))

  (set *globals* (set *maru-user* (environment *maru* 0 0)))   (when-at-expand feature/debug-info (set (<env>-name *maru-user*) "maru-user"))
  (capture-well-known-globals)
  (debug (platform/diag-print "initialize-vm is done\n")))

(define-function gc/print-statistics ()
  (print-all *error-output*
             "Heap: "
             (box <long> gc/objects-live)" objects in "
             (box <long> gc/bytes-used)" bytes, "
             (box <long> gc/bytes-free)" bytes free, "
             (box <long> gc/collection-count)" GC runs\n"
             ))

(define-function main/common (argc argv stdin stdout stderr)
  (initialize-vm)
  (initialize-streams stdin stdout stderr)

  (process-command-line-arguments argc argv)

  (debug-print "main is on the way out")

  (verbosity 1
    (gc/collect)
    (gc/print-statistics))
  (when-at-expand feature/profiler
    (profiler/disable))
  (platform/flush-streams)

  (debug-print "main is returning normally")
  0)
