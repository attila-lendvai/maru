;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; These are the common definitions of the platform API.
;;;
;;; Various examples of platforms:
;;;   libc
;;;   metacircular: eval.exe running the code in eval.l
;;;   raspberry-pi: running directly on an ARM board
;;;
;;; A platform needs to provide the following API:
;;;  - strings
;;;  - integers
;;;  - memory
;;;    - provide chunk(s) of memory for our GC
;;;    - moving, copying, comparing oops, bytes
;;;  - basic input/output
;;;  - entry point and exit into/from our universe (e.g. libc's main and exit)

(define-constant +maximum-call-stack-depth+	10000) ; to detect infinite recursion before the info gets lost into a sigsegv...
(define-constant feature/backtrace		(or true feature/profiler (< 0 *safety*)))
(define-constant feature/object-canary		(or () (<= 3 *safety*)))
(define-constant feature/debug-output		(or () (<= 3 *safety*)))
;; TODO set up proper framework for optimization control, merge with *optimised*
(define-constant feature/optimize-space		true)
(define-constant feature/optimize-speed		(and (not feature/optimize-space) (<= *safety* 2)))

(define-form debug		prog ())
(define-form debug/identities	prog ())
(define-form gc/debug		prog ())

(when-at-expand feature/debug-output
  (define *debug-output-enabled?* false)

  (define-form debug		prog	`(when *debug-output-enabled?* ,@prog))
  ;;(define-form debug/identities	prog	`(when *debug-output-enabled?* ,@prog))
  ;;(define-form gc/debug		prog	`(when *debug-output-enabled?* ,@prog))
  )

;; we can't have a function in the target for print-all, because
;; there's no support for &rest args yet in the compiler.
(define-form print-all (stream . objs)
  `(let ()
     ,@(map (lambda (obj)
              `(do-print ,stream ,obj false))
            objs)))

(define-form debug-print objs
  `(debug
    ;; only after streams are initialized. use platform/print-diag for debug output prior to that point.
    (when *debug-output*
      (print-all *debug-output* ,@objs)
      ;; TODO? use $put
      (do-print *debug-output* "\n" false))))

;; TODO use print-to-string eventually to generate the default assertion message, or add support for list literals in the compiler
;;(define-form assert		prog ())
(define-form assert		(test . args)	`(or ,test (error ,@(or args (list "kernel assertion failed")))))

;;;
;;; override slot access with a specialized getter and setter
;;; for the possibility of implementing e.g. read/write barriers.
;;;
;;; the customized slot-value is used for accessing heap objects
;;; that have a <header>. on high enough safety level all slot access
;;; is typechecked at runtime.
;;;
;;; "one of the reasons for having all accesses to object fields go
;;; through get() and set() was to make it ridiculously easy to add
;;; read and write barriers" - Piumarta (NOTE: that get/set has been
;;; replaced by the [set-]slot-value macro choke-points below)
;;;
;;; ----------------------------------------------------------------

(define-form slot-value (type-name slot-name object)
  (let* ((type		(eval type-name))
         (slot-index	(record/slot-index type slot-name)))
    `(oop-at ,(if feature/typecheck-slot-access
                  `(%accessor-typecheck ,type-name ,object)
                object)
             ,slot-index)))

(define-form set-slot-value (type-name slot-name object value)
  (let* ((type		(eval type-name))
         (slot-index	(record/slot-index type slot-name)))
    `(set (oop-at ,(if feature/typecheck-slot-access
                       `(%accessor-typecheck ,type-name ,object)
                     object)
                  ,slot-index)
          ,value)))

;;;
;;; forward definitions, so that the variables get created early enough for building the graph
;;; ----------------------------------------------------------------
(define-form define-forwards names
  `(let ()
     ,@(map (lambda (name) (list 'define name))
            names)))

(define-forwards
    *module* *maru-module* *maru-user-module* *symbols*

    *expanders* *encoders* *evaluators* *applicators*

    fixed-primitive-function/quote
    fixed-primitive-function/lambda
    fixed-primitive-function/let
    fixed-primitive-function/define
    fixed-primitive-function/set

    +end+ ; a unique value that cannot ever be read from any source file; it will be initialized at startup to an uninterned symbol.

    ;; and finally, these are the names of our own functions. we need to resolve some circular references this way.
    print-backtrace capture-well-known-module-values populate-module-with-maru-primitives
    print println read encode expand eval string->symbol %accessor-typecheck
    abort %string->C-string
    ;; and some of these are here to hide the host's primfns, otherwise those primfn's will be referenced by the
    ;; bodies of our impl functions below, leading to primfns reaching the compiler.
    environment-define defined? global-variable-value set-global-variable-value
    )

;; cache some symbols into the symbol/foo global variables
;; TODO add compilation of symbols and drop this cache
(define-form define-symbol-cache symbols
  `(let ()
     ,@(map (lambda (name)
              `(define ,(concat-symbol 'symbol/ name)))
            symbols)
     (define-function initialize-symbol-cache ()
       ,@(map (lambda (name)
                `(set ,(concat-symbol 'symbol/ name)
                      (string->symbol ,(symbol->string name))))
              symbols))))

(define-symbol-cache
    true define set quote quasiquote unquote unquote-splicing expand encode apply "." ; dot has a syntactic meaning
  lambda let *globals* *expanders* *encoders* *evaluators* *applicators*
  *standard-input* *standard-output* *error-output* *debug-output* *verbosity* *optimised*)

;; this installs symbol macros that get/set the value from/to the
;; interpreter's global state, namely the maru module's global
;; variables.
(define-symbol-form *standard-input*  (global-variable-value *maru-module* symbol/*standard-input*))
(define-symbol-form *standard-output* (global-variable-value *maru-module* symbol/*standard-output*))
(define-symbol-form *error-output*    (global-variable-value *maru-module* symbol/*error-output*))
(define-symbol-form *debug-output*    (global-variable-value *maru-module* symbol/*debug-output*))

;; TODO this is dog slow, we cannot use it as-is to replace *verbosity*
;; (define-symbol-form *verbosity*       (global-variable-value *maru-module* symbol/*verbosity*))
;; (define-symbol-form *optimised*       (global-variable-value *maru-module* symbol/*optimised*))

;; TODO this is fast, but this way *verbosity* in the evaluator and in the target is not in sync automatically.
;; ideally, these variables could be in a super-module, and the codebase would't even have a global-variable?
(define *verbosity* 0)
(define *optimised* 0)

;;;
;;; error handling
;;; ----------------------------------------------------------------

(define *call-stack-index*	0)
(when-at-expand feature/backtrace
  (define *call-stack*		0))

(define *error-level* 0)

;;
;; FATAL is a low-level facility, it directly uses the libc's printf
;; (i.e. it cannot print maru objects, but works early in the init).
;;
(define-function fatal-prologue ()
  (incr *error-level*)
  (platform/print-diag "\nERROR: "))

(define-function fatal-epilogue ()
  (platform/print-diag) ; newline
  (abort))

;; NOTE: FATAL needs to be a form so that platform/print-diag expands
;; to a C-string compiler special form; i.e. no advanced facility is
;; called while early in the init.
(define-form fatal  (fmt)           `(let () (fatal-prologue) (platform/print-diag ,fmt)                 (fatal-epilogue)))
(define-form fatal1 (fmt arg)       `(let () (fatal-prologue) (platform/print-diag-fmt ,fmt ,arg)        (fatal-epilogue)))
(define-form fatal2 (fmt arg1 arg2) `(let () (fatal-prologue) (platform/print-diag-fmt ,fmt ,arg1 ,arg2) (fatal-epilogue)))

;;
;; ERROR (and ASSERT!) goes through the maru printing facility
;; (i.e. it must not get called with an unboxed .asciz, nor before
;; streams and the VM is properly initialized).
;;
(define-function error-prologue ()
  (incr *error-level*)
  (unless (and *symbols* *error-output*)
    (platform/print-diag "WARNING: error-prologue was reached too early in init. We'll most probably crash before printing the actual error message."))
  (cond
    ((= 2 *error-level*)
     (platform/print-diag "NESTED ERROR 1, attempting to print a limited backtrace")
     (abort))
    ((< 2 *error-level*)
     (platform/print-diag "NESTED ERROR 2, giving up...")
     (platform/halt)))
  (platform/print-diag "\nERROR: "))

(define-function error-epilogue ()
  (platform/print-diag) ; newline
  (abort))

(define-function %error (arg)
  (do-print *error-output* arg false))

(define-form error args
  `(let ()
     (error-prologue)
     ,@(map (lambda (arg)
              `(%error ,arg))
            args)
     (error-epilogue)))

;;;
;;; primitive-function infrasrtucture
;;; ----------------------------------------------------------------

(begin-for-syntax
 (define *primitive-function-registry* ())
 (define *primitive-function-type-accessors*
     '((<long>			(long?)				(unbox <long>))
       (<string>		(string?))
       (<target-pointer>	(is <target-pointer>)		(unbox <target-pointer>))
       (<symbol>		(symbol?))
       (<pair>			(pair?))
       (<array>			(array?)))))

(define-function %not-enough-arguments (name args)
  (error name": not enough arguments: "args))

(define-function %too-many-arguments (name args)
  (error name": too many arguments: "args))

(define-form define-primitive-function (name-and-props args . body)
  ;; NAME: optionally a list of (prim-name (or level-shifted-name null) . (properties: fixed))
  ;; ARGS: may be _ to skip arg parsing
  ;;       otherwise a list of entries like:
  ;;         (arg-name (or arg-type null) (or default-value _) . (properties: nounbox))
  (set name-and-props (ensure-list name-and-props))
  (let ((prim-name	(pop name-and-props))
        impl-name
        impl-name?
        fixed?)
    (when (pair? name-and-props)
      (set impl-name (pop name-and-props))
      (set impl-name? true))
    (list-do prop name-and-props
      (case prop
        (fixed	(set fixed? true))
        (else	(error "define-primitive-function: unexpected property "prop))))
    (let* ((stub-name		(concat-symbol prim-name '/evaluator-stub))
           (arg-names		())
           (binders		()))
      ;; TODO what about redefining a function? e.g. number->string in libc.l
      (push *primitive-function-registry* (list prim-name fixed?))
      (let ((entries args))
        (while (pair? entries)
          (let* ((entry		(ensure-list (first entries)))
                 (arg-name	(pop entry))
                 (type		(pop entry))
                 (unbox?	true)
                 default-value
                 default-value?)
            (when (pair? entry)
              (set default-value (pop entry))
              (if (= '_ default-value)
                  (set default-value ())
                (set default-value? true)))
            (list-do prop entry
              (case prop
                (nounbox	(set unbox? ()))
                (else		(error "define-primitive-function: unexpected property "prop))))
            (assert (or (not type) (symbol? type)))
            (push arg-names arg-name)
            (let* ((type-entry		(when type
                                          (or (assq type *primitive-function-type-accessors*)
                                              `(,type (is ,type) ()))))
                   (type-checker	(second type-entry))
                   (unboxer		(third type-entry)))
              (push binders `(if (pair? __args)
                                 (let ()
                                   (set ,arg-name (get/head __args))
                                   ,@(when type-checker
                                       ;; TODO this emits quite some duplicity
                                       `((safety 1 (assert (,@type-checker ,arg-name) ,(symbol->string prim-name)": arg '",(symbol->string arg-name)"' is not of type ",(symbol->string type)))))
                                   ,@(when (and unbox?
                                                unboxer)
                                       ;; qq is broken... `((set ,arg-name (,unboxer arg-name)))
                                       (list (list 'set arg-name (concat-list unboxer (cons arg-name ())))))
                                   (set __args (get/tail __args)))
                               ,(if default-value?
                                    `(set ,arg-name ,default-value)
                                  `(%not-enough-arguments ,(symbol->string prim-name) -args-))))))
          (set entries (cdr entries)))
        ;; handle &rest arg
        (unless (= '_ entries)
          (push binders (if entries    ; i.e. it was in a cdr position
                            `(set ,entries __args)
                          `(safety 1 (when __args (%too-many-arguments ,(symbol->string prim-name) -args-)))))
          (when entries
            (push arg-names entries))))
      (set binders	(list-reverse! binders))
      (set arg-names	(list-reverse! arg-names))
      (let* ((effective-impl-name (if body
                                      (if impl-name? impl-name prim-name)
                                    prim-name))
             (impl (when (and body
                              effective-impl-name)
                     `((define-function ,effective-impl-name ,arg-names
                         ;; TODO (safety 1 (assert (is <env> env) "environment-define: env is not of type <env>: "env))
                         ,@body)))))
        `(let ()
           ,@impl
           (define-function ,stub-name (-args- -ctx-)
             ;; bind the args
             (let (,@(when binders `((__args -args-)))
                   ,@arg-names)
               ,@binders
               ,@(if effective-impl-name
                     `((,effective-impl-name ,@arg-names))
                   body))))))))

(define-primitive-function abort _
  (platform/print-diag "ABORTED")
  (print-backtrace)
  (platform/flush-streams)
  (platform/halt))

;;;
;;; utils
;;; ----------------------------------------------------------------

(define-function max (a b)
  (if (> a b) a b))

(define-function min (a b)
  (if (< a b) a b))

;;;
;;; copy the types here that should be visible to the target code
;;; ----------------------------------------------------------------

(define-form level-shift-types names
  `(let ()
     ,@(map (lambda (name)
              `(define ,name (eval-in-slave ',name)))
            names)))

(level-shift-types
 <type> <record>
 <data> <undefined> <long> <array> <string> <expr> <form> <fixed> <target-function>
 <variable> <env> <context> <module> <target-pointer> <symbol> <pair>)
