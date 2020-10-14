;;; -*- mode: lisp; coding: us-ascii -*-

;; NOTE for debugging only, because this breaks the output due to multiline string literals escaping the line-comment syntax
(define *compiler-verbose* '())

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

;;;
;;; FFI
;;;
(define-record <foreign-function> ()
  (name
   return-type
   parameter-types
   n-params
   vararg?))

(define-method do-print <foreign-function> ()
  (print "<<foreign-function> "self.return-type", "self.name", "self.parameter-types", "self.vararg?">"))

(define-function foreign-function (return-type foreign-name parameter-types)
  (let* ((rev-types (list-reverse parameter-types))
         (vararg? (= '... (first rev-types))))
    (when vararg?
      (pop rev-types))
    (set parameter-types (list-reverse! rev-types))
    (make <foreign-function>
      (name		foreign-name)
      (return-type	return-type)
      (parameter-types	parameter-types)
      (n-params		(list-length parameter-types))
      (vararg?		vararg?))))

;;;
;;; Utils
;;;
(let ((counter 0))
  (define-function unique-name (prefix)
    (concat-string prefix (long->string (incr counter)))))

(define-function align (alignment value)
  (bitwise-and (+ value (- alignment 1))
               (- alignment)))

;; TODO this is naive, should also deal with varargs explicitly instead of just returning nil
(define-function <expr>-n-required-parameters (op)
  (let ((params		(<expr>-parameters op))
        (n-params	()))
    (cond
      ((not params))                   ; (lambda () ...)
      ((symbol? params))               ; (lambda args ...)
      ((pair? params)
       (set n-params 1)
       (while (pair? (set params (rest params)))
         (incr n-params))
       (when (symbol? params)          ; (lambda (arg1 . rest) ...)
         (set n-params ())))
      (else
       (error "<expr>-n-required-parameters: error parsing <expr> " op ", parameters " params)))
    n-params))

;;;
;;; target module setup
;;;

;; TODO isn't this kinda messy? all these switch-to-foo-module &co...

(eval-in-slave
 (let (arch word-size)
   (cond
     ((or (= target/cpu "x86_64"))

      (set arch		'x86-64)
      (set word-size	64))

     ((or (= target/cpu "i686")
          (= target/cpu "i386"))

      (set arch		'IA-32)
      (set word-size	32))

     (else
      (error "Couldn't identify architecture and word size from target/cpu: "target/cpu)))

   ;; we want these constants (i.e. <form>s) to be present both in the slave and in the target module,
   ;; so that later forms can access them in both modules (forms will be run in the slave module
   ;; while constants will be referenced both directly from the target and in the form bodies).
   `(let ()
      (define-constant +architecture+		'',arch)
      (define-constant +operating-system+	'',(string->symbol target/os))
      ;;(define-constant +cpu+			,target/cpu)
      ;;(define-constant +vendor+		,target/vendor)
      (define-constant +little-endian?+		true) ; this is needed by the compiler tests
      ;;(define-constant +target-triplet+	,(concat-strings target/cpu "-" target/vendor "-" target/os))
      (define-constant +word-size-in-bits+	,word-size)
      (define-constant +word-size-in-bytes+	,(/ word-size 8)))))

(switch-to-slave-module)

;; FIXME these would be too much trouble to define above because nested quasiquote doesn't work
(define-form bytes-to-words (value)
  (if (long? value)
      (/  value +word-size-in-bytes+)
    `(/ ,value ,+word-size-in-bytes+)))

(define-form words-to-bytes (value)
  (if (long? value)
      (* value  +word-size-in-bytes+)
    `(* ,value ,+word-size-in-bytes+)))

;; redefine DEFINE-FORM with one that evaluates the body in *slave-module*.
;; this way the body code can use everything that's available in the slave module
;; even when used in the target, i.e. in eval.l.
(define-form define-form/target (name args . body)
  (let ((form-form	`(form (lambda (*env* ,@args) ,@body))))
    `(define ,name (eval-in-module *slave-module* ',form-form))))

(switch-to-host-module)

(load "source/env-min.l")

(define *target-module* (create-module "target"))

;; let's make all the slave's <form>s available in the *target-module*
;; TODO FIXME when we are doing this we inherit the definition order of the primitive-functions
;; from the host, and therefore we cannot reorder our own. this new setup also defines
;; the order of the definitions in the asm output, as opposed to having it in the same order
;; as in the source files.
(copy-module-bindings *slave-module* *target-module*
                      (lambda (name value)
                        (and (= (type-of value) <form>)
                             ;; *module* will be a global variable in the target, while in the interpreter
                             ;; it's a ([set-]current-module), because we need to update some caches when it's set.
                             (not (member? name '(*module*))))))

(define-function eval-in-target (form)
  (eval-in-module *target-module* form))

(define-form target-value (form)
  `(eval-in-module *target-module* ',form))

(define-function switch-to-target-module ()
  (set *module* *target-module*))

(when evolving?
  ;; there's a nasty bug in the host with expand that prevents us from redefining false using define-constant...
  (eval-in-target '(eval-encoded (encode '(set false -42)))))

(eval-in-target
 `(let ()
    (define *host-module*	,*module*)
    (define *slave-module*	,*slave-module*)
    (define slave-value		,slave-value)
    ;;(define eval-in-slave	,eval-in-slave)
    ;;(define eval-in-host	,(slave-value eval-in-host))
    ;; this cannot be a function because functions are supposed to be lowered to the target VM
    ;; (define-form switch-to-host-module ()
    ;;   `(set *module* *host-module*))

    (define evolving?		,evolving?)
    ;;(define bootstrapping?	,bootstrapping?) this is always true here

    ;; we want these variables to be lowered into the target, but not the arrays in them
    (set *expanders*	())
    (set *encoders*	())
    (set *evaluators*	())
    (set *applicators*	())

    (define define-form		,(slave-value define-form/target))

    (define qq/cons		,(slave-value qq/cons))
    ;; this will also be needed once a ,@ is at the "wrong" place, but then this is a closure,
    ;; and as such the compiler tires to lower it and fails.
    ;;(define qq/concat-list	,(slave-value qq/concat-list))

    (define-constant false 0)
    (define-constant true  1)))

(assert (= 1 (target-value true)))
(assert (= 0 (target-value false)))

(define-function target-boolean (value)
  (eval-in-target (if value 'true 'false)))

(assert (= 1 (target-boolean "foo")))
(assert (= 0 (target-boolean ())))

(eval-in-slave
 `(let ()
    (define *target-module*	,*target-module*)
    ;;(define eval-in-target	,(host-value eval-in-target))
    ;;(define target-value	,target-value)
    (define target-boolean	,target-boolean)))

;; install stubs for the +special-forms+, and also for some primitive functions,
;; so that any accidental use of them will result in an early and useful error message.
(list-do name '(return address-of << >> eval cons list car cdr
                ;; TODO with-instance-accessors uses with-forms that needs form to be present in the target.
                ;; because of that we can't rename new-<form> -> form
                ;; form
                )
  (eval-in-target `(define ,name (fixed (lambda args (abort ',name " encountered in interpreted code with args " args))))))

;; install stubs for the +special-operators+
;; (list-do name '()
;;   ;; they need to be <primitive-function>'s, so that encode doesn't insert them
;;   (eval-in-module *target-module* `(define ,name error)))

(when evolving?
  (eval-in-target
   `(let ()
      (define char-at		string-at)
      (define set-char-at	set-string-at))))
