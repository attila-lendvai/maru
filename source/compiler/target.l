;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; target env setup
;;;

(let (arch word-size)
  (case target/arch
    ("x86_64"
     (set arch		'x86-64)
     (set word-size	64))

    (("i686" "i386")
     (set arch		'IA-32)
     (set word-size	32))

    (("aarch64")
     (set arch		'aarch64)
     (set word-size	64))

    (else
     (error "Couldn't identify architecture and word size from target/arch: "target/arch)))

  ;; define in the host to be able to load cgrov.l
  (define-constant +target-triple+		(concat-strings target/arch "-" target/vendor "-" target/os
                                                                (if (equal "" target/abi)
                                                                    ""
                                                                  (concat-string "-" target/abi))))

  (eval-in-slave
   `(let ()
      (define-constant +architecture+		'',arch)
      (define-constant +operating-system+	'',(string->symbol target/os))
      (define-constant +little-endian?+		true) ; this is needed by the compiler tests
      ;; TODO why do i need that eval here? without this the value will be a FORM
      (define-constant +target-triple+		,(eval '+target-triple+))
      (define-constant +word-size-in-bits+	,word-size)
      (define-constant +word-size-in-bytes+	,(/ word-size 8)))))

(switch-to-slave-env)

(set (feature redefinable-functions-in-target) false) ; costs about 20-30% time increase in the bootstrap process
(set (feature strict-semantics-for-compiled-set) true) ; compiled set-oop-at & co. also returns the value that was just set
(set (feature backtrace)		(or true (feature profiler) (< 0 *safety*)))
(set (feature object-canary)		(or () (<= 3 *safety*)))
(set (feature emit-with-object-headers)	false)
(set (feature platform/libc)		false)
(set (feature platform/posix)		false)
(set (feature platform/linux)		false)
;; this is used in the assembler experiments. let's comment it out for now
;; when compiling with the 32 bit x86 backend.
(set (feature lower/array)		(not (= 32 +word-size-in-bits+)))

;; TODO set up proper framework for optimization control, merge with *optimised*
(set (feature optimize-space)		true)
(set (feature optimize-speed)		(and (not (feature optimize-space)) (<= *safety* 2)))

;; FIXME these would be too much trouble to define above because nested quasiquote doesn't work
(define-form bytes-to-words (value)
  (if (long? value)
      (/  value +word-size-in-bytes+)
    `(/ ,value ,+word-size-in-bytes+)))

(define-form words-to-bytes (value)
  (if (long? value)
      (* value  +word-size-in-bytes+)
    `(* ,value ,+word-size-in-bytes+)))

;; we rebind these to point to the actual definitions (as opposed to the symbols naming them),
;; so that CONS can be redefined in the target and the expansion of quasiquotes still work as expected
(define qq-concat-list	concat-list)
(define qq-cons		cons)

;; make these also available in the slave module
(define *slave-env*   (host-value *slave-env*))
(define eval-in-slave (host-value eval-in-slave))

(safety 1
  (eval-in-host
   `(let ()
      (assert (is <env> ,*slave-env*))
      (assert (is <expr> ,eval-in-slave)))))

;; TODO what about this? if it's retained, then audit the code for
;; every usage of EVAL-IN-SLAVE...
(define-form begin-for-syntax forms
  `(eval-in-slave '(let () ,@forms)))

;;;
;;; create an empty env (stored in *target-env*) to hold the
;;; definitions that will be level-shifted to the target.
;;;

;; *target-env* will hold the definitions that need to be
;; level-shifted (compiled). *slave-env* (*globals* here) will be the
;; parent of *target-env*, therefore all <form>'s that are defined in
;; *slave-env* are available "in" the *target-env*.
(assert (= *slave-env* *globals*))
(define *target-env* (environment *slave-env*))

(when-at-expand (feature debug-info)
  (eval-in-host `(set (<env>-name ,*target-env*) "target")))

(eval-in-host `(define *target-env* ,*target-env*))

(define-function switch-to-target-env ()
  (verbosity 2 (warn "---> target env\n"))
  (set *globals* *target-env*))

(eval-in-host `(define switch-to-target-env ,switch-to-target-env))

(switch-to-target-env)

(define false (form () (lambda _ (<immediate-type>-tag-value <undefined>))))
(define true  (form () (lambda _ 1)))

(safety 1
  (assert (not (= *globals* *slave-env*)))
  (assert (not (= *globals* (host-value *slave-env*))))
  (assert (= 0 false))
  (assert (= 1 true))
  (eval-in-slave '(assert (= () false)))
  (eval-in-slave '(assert (symbol? true)))
  (assert (= 42 (eval-in-slave '(+ 40 2))))
  (assert (= 42 ((eval-in-slave '(lambda () 42)))))
  (eval-in-slave '(define %im-a-test 42))
  (assert (defined? '%im-a-test))
  ;; (eval-in-host `(load "source/env-min.l"))
  ;; (eval-in-host `(assert (not (find-local-variable ,*globals* '%im-a-test))))
  ;; (eval-in-host `(assert (find-local-variable *slave-env* '%im-a-test)))
  (eval-in-host `(assert (defined? '%im-a-test *slave-env*))))

;; hide DEFINE-FORM in the target env with one that expand/encode/eval the body in the slave env.
;; this way the body code can use everything that's available in the slave module,
;; even when it is redefined in the target (e.g. CONS in the form body vs. the target's definition
;; of CONS, i.e. the one that implements it).
(define-form define-form (name args . body)
  (let* ((thunk	(eval-in-slave `(lambda (*env* ,@args) ,@body)))
         (form	(form (lambda runtime-args
                        (let ((prev-globals *globals*)
                              (result ()))
                          (set *globals* *slave-env*)
                          (set result (apply thunk runtime-args))
                          (set *globals* prev-globals)
                          result)))))
    ;; NOTE we define the form into the target env, because we want to
    ;; redefine the meaning of stuff like ERROR only in the target
    ;; env, not on its syntax-level (the slave module).
    `(define ,name ,form)))

;; TODO the body of WITH-FORMS is executed in the target env, but it's used
;; here and there (e.g. disable %ACCESSOR-TYPECHECK locally), so we can't just do this:
;; (define-form with-forms args
;;   (error "with-forms is not yet supported in the kernel code: "args))

(assert (not (= define-form (eval-in-slave 'define-form))))

;; FIXME what's going on here? true should be resolved to the variable in slave, not in target
;; (define-form test123 ()
;;   true)
;; (assert (not (= 1 (test123))))

;; hide DEFINE-CONSTANT in the target env with one that defines the constant into the slave env.
;; this way constants will be available inside the form bodies, too.
(define-form define-constant (name value-form)
  ;; NOTE as per the custom DEFINE-FORM above, we are expanded/encoded in the slave env,
  ;; but at runtime we're run in the target env.
  (let* ((value		(eval value-form))
         (form-obj	(eval `(form () (lambda _ ',value))))
         (definer-form	`(define ,name ',form-obj)))
    (eval definer-form)     ; this way it will define into *slave-env* due to using the custom define-form above
    ()))

(safety 1
  (define-form %im-a-test () (+ 1 41)))
(safety 1
  ;; (assert (not (find-local-variable *globals* '%im-a-test)))
  (assert (defined? '%im-a-test *slave-env*))
  (assert (= 42 (%im-a-test))))

;; redefine DEFINE-RECORD so that it defines into the slave env (sometimes forms, i.e. constant
;; want to access types, e.g. <header> in gc.l).
(define-form define-record args
  (eval `(define-record ,@args)) ; this way it will define into *slave-env*
  ())

;; install stubs for the +special-forms+, and also for some primitive functions,
;; so that any accidental use of them will result in an early and useful error message.
(list-do name '(return address-of byte-at set-byte-at
                arithmethic-shift-left arithmethic-shift-right
                stack-pointer-on-entry
                C-string                ; zero terminated C string
                ;;C-call ; calls the pointer in the first arg using the C calling convention on the rest of the args
                ;; nothing should call these before their target version gets defined:
                eval cons list car cdr form)
  (environment-define *globals* name (fixed (lambda args (eval-in-slave `(error ',name" encountered in interpreted code with args "',args))))))

(define-function %bitwise-shift (value shift)
  (cond
    ((<= +word-size-in-bits+ shift)
     0)
    ((<= shift (- +word-size-in-bits+))
     (if (< value 0) -1 0))
    ((< 0 shift)
     (arithmethic-shift-left value shift))
    ((< shift 0)
     (arithmethic-shift-right value (- shift)))
    (else value)))

(define-form bitwise-shift (value shift)
  (typecase shift
    (<long>	(cond
                  ((<= +word-size-in-bits+ shift)
                   0)
                  ((<= shift (- +word-size-in-bits+))
                   (if (< value 0) -1 0))
                  ((< 0 shift)
                   `(arithmethic-shift-left ,value ,shift))
                  ((< shift 0)
                   `(arithmethic-shift-right ,value ,(- shift)))
                  (else value)))
    (else	`(%bitwise-shift ,value ,shift))))

;; install stubs for the *special-operators*
;; (list-do name '()
;;   ;; they need to be <target-function>'s (why?)
;;   (eval `(define ,name error) *target-env*))

(switch-to-host-env)

;; the *globals* of the slave-module is the env that holds the target's definitions
(define-function eval-in-target (form)
  (eval form *target-env*))

(define-form target-value (form)
  `(eval-in-target ',form))

(assert (= 1 (target-value true)))
(assert (= 0 (target-value false)))
