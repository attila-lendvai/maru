;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; These are the definitions the platform API can use.
;;;
;;; Various examples of platforms:
;;;   libc
;;;   metacircular: eval.exe running the code in eval.l
;;;   raspberry-pi: running directly on an ARM board
;;;   linux: static binary using direct syscalls
;;;
;;; A platform needs to provide the following API:
;;;  - strings
;;;  - integers
;;;  - memory
;;;    - provide chunk(s) of memory for our GC
;;;    - moving, copying, comparing oops, bytes
;;;  - basic input/output
;;;  - bridge execution into and out of our universe;
;;;    e.g. main() and exit() in the case of libc.

(eval-in-slave '(set (feature emit-with-object-headers) true))

(define-constant +maximum-call-stack-depth+	10000) ; to detect infinite recursion before the info gets lost into a sigsegv...

;; we can't have a function in the target for print-all, because
;; there's no support for &rest args yet in the compiler.
(define-form print-all (stream . objs)
  `(let ()
     ,@(map (lambda (obj)
              `(do-print ,stream ,obj false))
            objs)))

;; TODO use print-to-string eventually to generate the default assertion message, or add support for list literals in the compiler
;;(define-form assert		prog ())
(define-form assert		(test . args)	`(or ,test (error ,@(or args (list "kernel assertion failed")))))

(define-form to-upper-boolean (form)
  `(if ,form symbol/true))

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
  (let* ((type		(eval type-name *env*))
         (slot-index	(record/slot-index type slot-name)))
    `(oop-at ,(if (feature typecheck-slot-access)
                  `(%accessor-typecheck ,(<type>-slave-id type) ,object)
                object)
             ,slot-index)))

(define-form set-slot-value (type-name slot-name object value)
  (let* ((type		(eval type-name *env*))
         (slot-index	(record/slot-index type slot-name)))
    `(set (oop-at ,(if (feature typecheck-slot-access)
                       `(%accessor-typecheck ,(<type>-slave-id type) ,object)
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
    *globals* *maru* *symbols*

    *expanders-var* *encoders-var* *evaluators-var* *applicators-var*

    fixed-primitive-function/quote
    fixed-primitive-function/lambda
    fixed-primitive-function/let
    fixed-primitive-function/define
    fixed-primitive-function/set

    +end+ ; a unique value that cannot ever be read from any source file; it will be initialized at startup to an uninterned symbol.

    ;; and finally, these are the names of our own functions. we need to resolve some circular references this way.
    print-backtrace capture-well-known-globals
    print println read encode expand eval string->symbol %accessor-typecheck
    abort %string->C-string long->string/emit

    symbol/*standard-input* symbol/*standard-output* symbol/*error-output* symbol/*debug-output*

    ;; and some of these are here to hide the host's primfns, otherwise those primfn's will be referenced by the
    ;; bodies of our impl functions below, leading to primfns reaching the compiler.
    environment-define defined? variable-value set-variable-value

    ;; KLUDGE to ease load order constraints
    main/common
    )

(define *call-stack-index*	0)
(when-at-expand (feature backtrace)
  (define *call-stack*		0))

;; this installs symbol macros that get/set the value from/to the
;; interpreter's global state, namely the maru module's global
;; variables.
(define-symbol-form *standard-input*  '(variable-value *maru* symbol/*standard-input*))
(define-symbol-form *standard-output* '(variable-value *maru* symbol/*standard-output*))
(define-symbol-form *error-output*    '(variable-value *maru* symbol/*error-output*))
(define-symbol-form *debug-output*    '(variable-value *maru* symbol/*debug-output*))

;; TODO this is dog slow, we cannot use it as-is to replace *verbosity*
;; (define-symbol-form *verbosity*       '(variable-value *maru* symbol/*verbosity*))
;; (define-symbol-form *optimised*       '(variable-value *maru* symbol/*optimised*))

;; TODO this is fast, but this way *verbosity* in the vm and in the target is not in sync automatically.
;; ideally, these variables could be in a super-module, and the codebase would't even have a global-variable?
;; TODO (define-vm-variable *verbosity* <long> 0)
(define *verbosity* 0)
(define *optimised* 0)

(define-form error args
  (error "ERROR referenced too early while loading the target definitions; args: " args))

(load "source/math-min.l")
