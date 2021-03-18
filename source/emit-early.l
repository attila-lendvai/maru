;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")

;; NOTE for debugging only, because this breaks the output due to multiline string literals escaping the line-comment syntax
(define *compiler-verbose* '())

(define-constant +maru-label-prefix+ "m_")

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

(define-constant feature/redefinable-functions-in-target ()) ; costs about 20-30% time increase in the bootstrap process
(define-constant feature/strict-semantics-for-compiled-set true) ; compiled set-oop-at & co. also returns the value that was just set

(define-selector compile)
(define-selector compile-definition)
(define-selector compile-call-to)

;;;
;;; FFI
;;;
(define-record <C-function> ()
  (name
   return-type
   parameter-types
   n-params
   vararg?))

(define-print-method <C-function>
  (print-all -stream- "<<C-function> "self.return-type", "self.name", "self.parameter-types", "self.vararg?">"))

(define-function C-function (return-type foreign-name parameter-types)
  (let* ((rev-types (list-reverse parameter-types))
         (vararg? (= '... (first rev-types))))
    (when vararg?
      (pop rev-types))
    (set parameter-types (list-reverse! rev-types))
    (make <C-function>
      (name		foreign-name)
      (return-type	return-type)
      (parameter-types	parameter-types)
      (n-params		(list-length parameter-types))
      (vararg?		vararg?))))

(define-record <C-variable> ()
  (name
   type))

(define-function C-variable (foreign-name type)
  (make <C-variable>
    (name	foreign-name)
    (type	type)))

;;;
;;; Utils
;;;
(let ((counter 0))
  (define-function unique-name (prefix)
    (concat-string prefix (number->string (incr counter)))))

(define-function align (alignment value)
  (bitwise-and (+ value (- alignment 1))
               (- alignment)))

;; TODO this is naive, should also deal with varargs explicitly instead of just returning nil
(define-function expr-n-required-parameters (op)
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
       (error "expr-n-required-parameters: error parsing <expr> " op ", parameters " params)))
    n-params))

;; this is kinda KLUDGEy
(define emit-object/<long>) ; forward
(define compile-expr) ; forward
(define-function compile-array (self -c-)
  (let ((compiled (array (array-length self))))
    (for (i 0 (array-length self))
      (let ((obj (array-at self i)))
        (set (array-at compiled i)
             (typecase obj
               (<long>		(emit-object/<long> obj -c-))
               (<expr>		(compile-expr obj () -c-))
               (else (error "compile-array: don't know how to compile: "obj))))))
    compiled))

;;;
;;; Operands
;;;

(define-function define-operand/make-setters (type-name fields)
  (when (pair? fields)
    (cons `(set (slot-value ,type-name ,(car fields) self) ,(car fields))
          (define-operand/make-setters type-name (cdr fields)))))

(define-form define-operand (name super direct-slots . printing)
  (let* ((type-name	(symbol->type-name name))
         (type		(eval `(define-record ,type-name ,(when super (symbol->type-name super)) ,direct-slots)))
         (effective-slots (<record>-effective-slots type)))
    (assert (is <record> type))
    (eval `(define-function ,name ,effective-slots
             (let ((self (new ,type-name)))
               ,@(define-operand/make-setters type-name effective-slots)
               self)))
    `(define-print-method ,type-name (print-all -stream- ,@printing))))

;;; compiler infrastructure
;;;

(define-record <compiler> ()
  (level
   temp-counter
   temp-limit
   temps
   gen-buffer
   current-value              ; the output of the previous-instruction
   ))

(define new-temp) ; forward
(define %free-temp) ; forward

(define-function new-temp-index (c)
  (with-instance-accessors c <compiler>
    (let ((i c.temp-counter))
      (incr c.temp-counter)
      (when (< c.temp-limit c.temp-counter)
        (set c.temp-limit c.temp-counter))
      i)))

(define-function alloc-temp (-c-)
  (or (pop (<compiler>-temps -c-))
      (new-temp -c-)))

(define-function %free-temps (-c- temps)	(list-do temp temps (%free-temp -c- temp)))
(define-form free-temp (temp)			`(%free-temp -c- ,temp))
(define-form free-temps (temp)			`(%free-temps -c- ,temp))

(define-function accessible-variable-or-die (var -c-)
  (or (global-variable? var)
      (let ((comp-level	(<compiler>-level -c-))
            (var-level	(<env>-level (<variable>-env var))))
        (assert (<= comp-level var-level) "err, what!? encountered a variable whose env is *below* the compiler's lambda nesting level!? it's "var)
        (when (< var-level comp-level)
          (error "cannot access variable "var", closures are not supported yet.")))))

;;;
;;; target env setup
;;;

(let (arch word-size)
  (case target/cpu
    ("x86_64"
     (set arch		'x86-64)
     (set word-size	64))

    (("i686" "i386")
     (set arch		'IA-32)
     (set word-size	32))

    (else
     (error "Couldn't identify architecture and word size from target/cpu: "target/cpu)))

  (eval-in-slave
   `(let ()
      (define-constant +architecture+		'',arch)
      (define-constant +operating-system+	'',(string->symbol target/os))
      ;;(define-constant +cpu+			,target/cpu)
      ;;(define-constant +vendor+		,target/vendor)
      (define-constant +little-endian?+		true) ; this is needed by the compiler tests
      ;;(define-constant +target-triplet+	,(concat-strings target/cpu "-" target/vendor "-" target/os))
      (define-constant +word-size-in-bits+	,word-size)
      (define-constant +word-size-in-bytes+	,(/ word-size 8)))))

;; KLUDGE move this somewhere into a 'linux' namespace
(define-constant +linux/syscall-registers/32+ `(quote ,(map symbol->string '(eax ebx ecx edx esi edi ebp))))
(define-constant +linux/syscall-registers/64+ `(quote ,(map symbol->string '(rax rdi rsi rdx r10 r8 r9))))
(eval-in-slave
 '(let ()
   (define-constant linux/O_RDONLY		0)
   (define-constant linux/O_WRONLY		1)
   (define-constant linux/O_RDWR		2)
   (define-constant linux/O_CREAT		64)
   (define-constant linux/SEEK_SET		0)
   (define-constant linux/SEEK_CUR		1)
   (define-constant linux/SEEK_END		2)
   (define-constant linux/stdin			0)
   (define-constant linux/stdout		1)
   (define-constant linux/stderr		2)
   (cond
     ((= +architecture+ 'IA-32)
      (define-constant linux/exit		1)
      (define-constant linux/read		3)
      (define-constant linux/write		4)
      (define-constant linux/open		5)
      (define-constant linux/close		6)
      (define-constant linux/chdir		12)
      (define-constant linux/lseek		19)
      (define-constant linux/brk		45)
      (define-constant linux/fsync	        118)
      )
     ((= +architecture+ 'x86-64)
      (define-constant linux/read		0)
      (define-constant linux/write		1)
      (define-constant linux/open		2)
      (define-constant linux/close		3)
      (define-constant linux/lseek		8)
      (define-constant linux/brk		12)
      (define-constant linux/exit		60)
      (define-constant linux/fsync		74)
      (define-constant linux/chdir		80)
      ))))

(set *globals* *slave-env*)

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

(define-form begin-for-syntax forms
  `(eval-in-slave '(let () ,@forms)))

;;;
;;; create an empty env to hold the definitions that will be
;;; level-shifted to the target. let's mention *target-env* here for
;;; grep'ability.
;;;
(define *target-env* (environment *globals*))
(eval-in-host `(define *target-env* ,*target-env*))
(define primitive/eval eval) ; we will need to reach back to this when starting the compiler

(set *globals* *target-env*)

(safety 1
  (assert (not (= *globals* *slave-env*)))
  (assert (not (= *globals* (host-value *slave-env*))))
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
         (form	(form (lambda rtargs
                        (let ((prev-globals *globals*)
                              (result ()))
                          (set *globals* *slave-env*)
                          (set result (apply thunk rtargs))
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

(define-constant false 0)
(define-constant true  1)

(safety 1
  (define-form %im-a-test () (+ true 41)))
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
                   `(arithmethic-shift-right ,value ,(- shift)))))
    (else	`(%bitwise-shift ,value ,shift))))

;; install stubs for the +special-operators+
;; (list-do name '()
;;   ;; they need to be <primitive-function>'s (why?)
;;   (eval `(define ,name error) *target-env*))

(set *globals* *host-env*)

;; the *globals* of the slave-module is the env that holds the target's definitions
(define-function eval-in-target (form)
  (eval form *target-env*))

(define-form target-value (form)
  `(eval-in-target ',form))

(assert (= 1 (target-value true)))
(assert (= 0 (target-value false)))
