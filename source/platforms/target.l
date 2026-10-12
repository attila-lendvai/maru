;;; -*- mode: lisp; coding: us-ascii -*-

(define false (form () (lambda _ (<immediate-type>-tag-value <undefined>))))
(define true  (form () (lambda _ 1)))

(safety 1
  (assert (not (= *globals* *slave-env*)))
  (assert (not (= *globals* (host-value *slave-env*))))
  (assert (= 0 false)) ; in the current setup
  (assert (= 1 true))  ; in the current setup
  (eval-in-slave '(assert (= () false)))
  (eval-in-slave '(assert (symbol? true)))
  (assert (= 42 (eval-in-slave '(+ 40 2))))
  (assert (= 42 ((eval-in-slave '(lambda () 42)))))
  (eval-in-slave '(define %im-a-test 42))
  (assert (defined? '%im-a-test))
  ;; (eval-in-host `(load "source/env-lower.l"))
  ;; (eval-in-host `(assert (not (find-local-variable ,*globals* '%im-a-test))))
  ;; (eval-in-host `(assert (find-local-variable *slave-env* '%im-a-test)))
  (eval-in-host `(assert (defined? '%im-a-test *slave-env*))))

;; shadow DEFINE-FORM in the target env with one that expand/encode/eval the body in the slave env.
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
(list-do name '(return address-of u8-at set-u8-at u32-at set-u32-at
                arithmethic-shift-left arithmethic-shift-right
                stack-pointer-on-entry
                C-string                ; zero terminated C string
                ;;C-call ; calls the pointer in the first arg using the C calling convention on the rest of the args
                ;; nothing should call these before their target version gets defined:
                eval cons list car cdr form)
  (environment-define *globals* name (fixed (lambda args (eval-in-slave `(error ',name" encountered in interpreted code with args "',args))))))

;; NOTE that this must be defined here if we want to provide
;; BITWISE-SHIFT as a higher level API for left/right arithmetic shift
;; supported by the compiler (e.g. in the compiler tests). the machine
;; code instructions ignore signs, and in general ignore values larger
;; than the maximum shift that makes sense.
(define-function %bitwise-shift (value shift)
  (cond
    ((<= target/cell-size/bits shift)
     0)
    ((<= shift (- target/cell-size/bits))
     (if (< value 0) -1 0))
    ((< 0 shift)
     (arithmethic-shift-left value shift))
    ((< shift 0)
     (arithmethic-shift-right value (- shift)))
    (else value)))

(define-form bitwise-shift (value shift)
  (typecase shift
    (<long>	(cond
                  ((<= target/cell-size/bits shift)
                   0)
                  ((<= shift (- target/cell-size/bits))
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
