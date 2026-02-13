;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This is a compiler that emits IA-32 text, aka x86 assembly, that
;;; needs to be fed to the gcc toolchain.
;;;
;;; Status: it should successfully compile eval.l into eval.s,
;;; that in turn can be compiled by the gcc toolchain into an executable eval binary.
;;;

;;; TODO
;;;  - factor out the C ffi stuff into a separate file

;;; It can compile a subset of Maru.
;;;
;;; Limitations and peculiarities:
;;;   - no closures
;;;   - no variable number of args for functions
;;;   - some literal objects are emitted as valid objects that can participate
;;;     in the heap; see the EMIT-OBJECT methods for an up-to-date list.
;;;   - probaby more
;;;   - see +special-operators+ and *special-forms* for the list of specially
;;;     handled constructs
;;;
;;; Naming:
;;;   - EMIT: emit instructions into the output stream
;;;   - GEN:  like EMIT, but collect instructions into a buffer for later emission
;;;   - -foo- is an implicit var in the lexenv
;;;   - +foo+ is a constant
;;;   - *foo* is a global

(require "source/compiler/emit-early.l")
(require "source/compiler/emit-x86-common.l")

;; KLUDGE replace the env binding for the base class. the reason is
;; that this way we can use (LITERAL 42) in some parts of the code
;; that is shared between 32 and 64 bits... but there must be a nice
;; way to achieve this.
(define LITERAL LI64)

;;;
;;; x86-64 -- INSTRUCTIONS
;;;

;; ENTER is slow, so don't use it (LEAVE is fine): https://stackoverflow.com/questions/5959890/enter-vs-push-ebp-mov-ebp-esp-sub-esp-imm-and-leave-vs-mov-esp-ebp
(define-instruction ENTER	()
  ((long)			(println "	push	%rbp")
                                (println "	mov	%rsp, %rbp")
                                (unless (= 0 $1)
                                  (println "	sub	$"$1", %rsp"))))

(define-instruction SEXT	()
  ((R32 R64)			(println "	movslq	"$1", "$2)))

(define-instruction/emit-forms LOAD 0
  ((LABEL)			(println "	lea	"$1"(%rip), %rax")))

;;;
;;; Compiler Infrastructure
;;;
(define-constant +param-registers+ ''("%rdi" "%rsi" "%rdx" "%rcx" "%r8" "%r9"))

(define-record <x86-64-compiler> <x86-compiler>
  (arg-registers))

(define-function x86-64-compiler (level)
  (make <x86-64-compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (gen-buffer			(array))

    (param-offset		0)
    (arg-offset			0)
    (arg-limit			0)
    (asm-cell-type		".8byte")

    (arg-registers		+param-registers+)
    ))

(define-function run-compiler (env)
  (compile-env env (x86-64-compiler 1)))

(define-function new-temp (-c-)
  (TEMP64 (* (new-temp-index -c-) +word-size-in-bytes+)))

(define-function %free-temp (-c- obj)
  (when (is <TEMP64> obj)
    (push (<compiler>-temps -c-) obj)))

;; (define-function new-param (c)
;;   (with-instance-accessors c <x86-64-compiler>
;;     (let ((reg (pop c.param-registers)))
;;       (if reg
;;           (let ()
;;             (assert (string? reg))
;;             (R64 reg))
;;         (let ((offset	c.param-offset))
;;           (set c.param-offset (+ offset +word-size-in-bytes+))
;;           (TEMP64 offset))))))

(define-function new-arg (c)
  (with-instance-accessors c <x86-64-compiler>
    (let ((reg (pop c.arg-registers)))
      (if reg
          (let ()
            (assert (string? reg))
            (R64 reg))
        (let ((offset	c.arg-offset))
          (set c.arg-offset (+ offset +word-size-in-bytes+))
          (TEMP64 offset))))))

(define-function free-args (c args)
  (with-instance-accessors c <x86-64-compiler>
    (when (< c.arg-limit c.arg-offset)
      (set c.arg-limit c.arg-offset))
    (set c.arg-offset 0)
    (set c.arg-registers +param-registers+)))

;;;
;;; Compiling lambdas
;;;

(define-function compile/expr-into-temp-or-literal (expr -c-)
  (cond
    ((long? expr)
     (LI64 expr))
    (else
      (comp expr)
      (let ((temp (alloc-temp -c-)))
        (gen STORE temp)
        temp))))

;; When a function calls another function then it will need to
;; overwrite the registers where it has received its own params. A
;; simple solution is to spill the params to the stack when we
;; encounter the first function call.
;; (define-function spill-params (expr -c-)
;;   (emit-comment 1 "spilling "(list-length (<expr>-parameters expr))" params to the stack")
;;   (map (lambda (var)
;;          (let ((loc (<variable>-value var)))
;;            (unless (is <TEMP64> loc)
;;              (let ((reg (<variable>-value var))
;;                    (temp (pop (<x86-64-compiler>-param-spill-locs -c-))))
;;                (assert temp)
;;                (assert (is <R64> reg))
;;                (set (<variable>-value var) temp)
;;                (gen MOVE reg temp)))))
;;        (<expr>-parameters expr)))

(define-function emit-expr-code (self entry-point-label parent-comp)
  ;; NOTE printing the code as-is, i.e. without escaping, may break the comment syntax
  (let* ((body	(<expr>-body self))
         (-c-	(x86-64-compiler (+ 1 (<compiler>-level parent-comp))))
         (param-locs
           (let ((param-regs +param-registers+))
             (map (lambda (var)
                    ;; KLUDGE this writes some internal compiler state (the
                    ;; location of this param on the stack) into the source
                    ;; code.
                    (aif (pop param-regs)
                        (let ((spill-loc (new-temp -c-)))
                          ;; preallocate spill locations; used by MAYBE-SPILL-PARAMS
                          (set (<variable>-value var) spill-loc)
                          (R64 it))
                      (let ((offset (<x86-compiler>-param-offset -c-)))
                        (incr (<x86-compiler>-param-offset -c-) +word-size-in-bytes+)
                        ;; this extends the stack frame size as needed
                        (TEMP64 offset))))
                  (<expr>-parameters self)))))
    (emit-comment 1 "emitting "self", at level: "(<compiler>-level parent-comp))
    (emit-comment 3 ", code: "(<expr>-body self))
    ;; Unconditionally spill the params to the stack.
    (emit-comment 1 "spilling "(list-length param-locs)" params to the stack")
    (map (lambda (param-loc var)
           (when (is <R64> param-loc)
             (let ((spilled-loc (<variable>-value var)))
               (gen MOVE param-loc spilled-loc))))
         param-locs (<expr>-parameters self))

    ;; Compile the fn body first into the gen buffer (COMP is a form,
    ;; we cannot map it).
    (list-do el body
      (comp el))

    ;; Calculate the frame and emit the entire fn
    (let* ((arg-size	(<x86-compiler>-arg-limit -c-))
           (temp-size	(+ arg-size
                           (* (<compiler>-temp-limit -c-)
                              +word-size-in-bytes+)))
           (frame-size	(align +call-frame-alignmet+
                               ;; the pushed %ebp and the return address (?)
                               (+ temp-size
                                  (* 2 +word-size-in-bytes+))))
           (frame-body-size (- frame-size (* 2 +word-size-in-bytes+))))
      ;; Now that we know the frame size, fix up the offsets of the
      ;; temps allocated on the stack.
      (map (lambda (el)
             (incr (<TEMP>-offset el) arg-size))
           (<compiler>-temps -c-))
      ;; Params could also be accessed through %ebp, but for that we
      ;; would need another operand class. Let's just offset them by
      ;; the frame size and use %esp through simple TEMP64.
      (map (lambda (loc)
             (when (is <TEMP64> loc) ; the first few loc's are in registers
               (incr (<TEMP>-offset loc) frame-size)))
           param-locs)
      ;; actual emitting begins
      (emit TEXT)
      (emit DEFLABEL entry-point-label)
      (emit-comment 1 "params: "(list-length (<expr>-parameters self))
                    ", frame-size: "frame-size"("(/ frame-size +word-size-in-bytes+)
                    "), arg-size: " arg-size  "("(/ arg-size   +word-size-in-bytes+)
                    "), temp-size: "temp-size "("(/ temp-size  +word-size-in-bytes+)")")
      (emit ENTER frame-body-size)
      (emit-gen-buffer -c-)
      (awhen (<x86-compiler>-fn-epilogue-label -c-)
        (emit DEFLABEL it))
      (emit LEAVE frame-body-size)))
  entry-point-label)

;;;
;;; Compiling calls
;;;

(define-function compile-call-form (op args raw? -c-)
  (emit-comment 2 "compile-call: "op", args: "args", raw?: "raw?)
  (safety 2 (assert (or (pair? op) (variable? op))))
  ;; (set (<x86-64-compiler>-params-must-be-spilled -c-) true)
  ;; NOTE this implements a left-to-right evaluation order, including the operator.
  ;; i.e. moving this op-tmp means changing the evaluation order!
  (let ((op-tmp		(when (pair? op)
                          ;; optimization:
                          ;; we can spare a STORE/LOAD when we know that op
                          ;; doesn't evaluate anything; i.e. we can delay
                          ;; its evaluation, i.e. a simple LOAD, to the
                          ;; final, COMPILE-CALL-TO step.
                          (compile/expr-into-temp-or-literal op -c-)))
        (arg-tmps	(map-with compile/expr-into-temp-or-literal args -c-))
        (arg-locs	(map (lambda (_) (new-arg -c-)) args)))
    ;; set up the stack for the call
    (map (lambda (a b) (gen MOVE a b)) arg-tmps arg-locs)
    (free-temps arg-tmps)

    (let* ((op-value	(or op-tmp
                            (if (variable? op)
                                (<variable>-value op)
                              op)))
           (n-params	(if raw?
                            (let ()
                              (gen LOAD op-value)
                              (gen CALLPTR arg-locs)
                              ())
                          (emit-comment 2 "compile-call-to: "op-value)
                          (compile-call-to op-value op arg-locs -c-)))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))

    (free-args -c- arg-locs)
    (free-temp op-tmp)))

(let ((program-code-offset (slave-value (record/slot-index <target-function> 'program-code))))
  (define-function compile-call-to-object (arg-locs -c-)
    ;; TODO assert the type to be <target-function>
    ;; TODO assert nr of args = params
    (gen LOAD-OOP (LI64 program-code-offset))
    (gen CALLPTR arg-locs)
    ()))

(define-function compile-call-to-global-function (op arg-locs -c-)
  (if feature/redefinable-functions-in-target
      (let ()
        (comp op)
        (compile-call-to-object arg-locs -c-))
    (gen CALL (closure-code-label (<variable>-name op)) arg-locs))
  ())

(define-method compile-call-to (slave-value <target-function>) (op arg-locs -c-)
  (comp op)
  (compile-call-to-object arg-locs -c-))

(define-method compile-call-to <TEMP64> (op arg-locs -c-)
  (gen LOAD self)
  (compile-call-to-object arg-locs -c-))

(define-method compile-call-to <R64> (op arg-locs -c-)
  (gen LOAD self)
  (compile-call-to-object arg-locs -c-))

;; this case is handled early in compile-call
;; (define-method compile-call-to <pair> (op arg-locs -c-)
;;   (comp op)
;;   (compile-call-to-object arg-locs -c-))

(define-method compile-call-to <expr> (op arg-locs -c-)
  ;; NOTE the fact that a literal <expr> is found in a variable's
  ;; value slot at compile time implies that it's a global definition.
  (compile-call-to-global-function op arg-locs -c-)
  (expr-n-required-parameters self))

(define-method compile-call-to <C-function> (op arg-locs -c-)
  (gen CALL (EXTERNAL-LABEL (<C-function>-name self)) arg-locs)
  (case (<C-function>-return-type self)
    ;; TODO introduce a proper infrastructure for this
    (int
     (gen SEXT (R32 "%eax") (R64 "%rax")))
    (short
     (error "TODO sign-extend a short to 64 bits")))
  (unless (<C-function>-vararg? self)
    (list-length (<C-function>-parameter-types self))))

(define-method compile-call-to (slave-value <selector>) (op arg-locs -c-)
  (compile-call-to-global-function op arg-locs -c-)
  ;; TODO extract and return n-params
  ())

;;;
;;; Special Forms
;;;
(define-function compile/set (expr -c-)
  (let* ((var	(second expr))
         (value	(<variable>-value var)))
    (accessible-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ((or (is <TEMP64> value)
           (is <R64> value))
       (gen STORE value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (gen STORE ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL64)
                   (EXTERNAL-LABEL (<C-variable>-name value)))))
      (else
       (gen STORE (GLOBAL64 (LABEL (<variable>-name var))))))))

(define-function compile/address-of (expr -c-)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (cond
        ((global-variable? var)
         (gen ADDR (GLOBAL64 (LABEL (<variable>-name var)))))
        ((is <TEMP64> val)
         (gen ADDR val))
        ;; ((is <R64> val)
        ;;  (maybe-spill-params -c-)
        ;;  (gen ADDR (<variable>-value var)))
        (else
         (error "address-of: don't know how to compile for variable " var ", holding the value " val))))))

;;;
;;; *special-forms*
;;;
(define *special-forms* (list
  (cons (target-value let)		compile/let)
  (cons (target-value and)		compile/and)
  (cons (target-value or)		compile/or)
  (cons (target-value if)		compile/if)
  (cons (target-value while)		compile/while)
  (cons (target-value set)		compile/set)
  (cons (target-value lambda)		compile/lambda)
  (cons (target-value return)		compile/return)
  (cons (target-value address-of)	compile/address-of)
  (cons (target-value C-string)		compile/C-string)
  ;;(cons (target-value C-call)		(lambda (expr -c-) (compile-call-form (second expr) (cddr expr) true -c-)))
  (cons (target-value stack-pointer-on-entry)
        (lambda (expr -c-)
          ;; the function prologue we also employ is like this:
          ;;
          ;; push	%rbp
          ;; mov	%rsp, %rbp
          ;; sub	$n, %rsp
          ;; ...
          ;;
          ;; so, the 8(%rbp) is to undo the push %rbp, so that we
          ;; regain the %rsp value at the entry point to the function.
          (gen INLINE "	lea	8(%rbp), %rax")))
  ))

;;;
;;; Special Operators
;;;

(define-function compile/unary-operator (op args -c-)
  (comp (car args))
  (gen op))

;; FIXME? these implement a right-to-left evaluation order, while
;; function calls implement the opposite. note that this is entangled
;; with e.g. the LOAD/STORE instructions above, as they expect arg0 to
;; be loaded in %rax.
(define-function compile/binary-operator (op args -c-)
  (let ((tmp (compile/expr-into-temp-or-literal (cadr args) -c-)))
    (comp (car args))
    (free-temp tmp)
    (gen op tmp)))

(define-function compile/ternary-operator (op args -c-)
  (let ((tmp2 (compile/expr-into-temp-or-literal (caddr args) -c-))
        (tmp1 (compile/expr-into-temp-or-literal (cadr  args) -c-)))
    (comp (car args))
    (free-temp tmp1)
    (free-temp tmp2)
    (gen op tmp1 tmp2)))

(define +operator-compilers+ (list->array (list () compile/unary-operator compile/binary-operator compile/ternary-operator)))

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (is <R64> value)
           (is <LI64> value)
           (is <TEMP64> value))
       (gen LOAD value))
      ((global-variable? self)
       (cond
         ((= 'true self.name)
          (gen LOAD (LI64 (target-value true))))
         ((subtype? (type-of value) <type>)
          (gen LOAD (LI64 (eval-in-slave `(<type>-slave-id ,value)))))
         ((is <C-function> value) ; handles the situation when e.g. libc/strcmp is passed as a comparator fn for array-binary-search
          (gen LOAD (EXTERNAL-LABEL (<C-function>-name value))))
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (gen LOAD ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL64)
                     (EXTERNAL-LABEL (<C-variable>-name value)))))
         ((and (not feature/redefinable-functions-in-target)
               (is <expr> value))
          (gen LOAD (LABEL self.name)))
         (else
          (gen LOAD (GLOBAL64 (LABEL self.name))))))
      (else
       (error "compile of <variable> failed for " self ", holding the value " value)))))

(define-method compile <pair> (-c-)
  (let* ((op		(first self))
         (op-is-a-var?	(variable? op))
         (op-value	(if op-is-a-var?
                            (or (<variable>-value op)
                                (error "error: calling undefined function: "op))
                          op))
         (args		(rest self))
         (arity		(list-length args))
         (handler	()))
    (when (<= 2 *compiler-verbosity*)
      (emit-comment 1 "call of op: "op", op-is-a-var? "op-is-a-var?", args: " args))
    ;; TODO add compiler-macros. use them to optimize stuff on the lisp semantic level
    (cond
      ((set handler (second (assq op-value (array-at +special-operators+ arity))))
       ((array-at +operator-compilers+ arity) handler args -c-))
      ((is <fixed> op)
       (let ((handler (cdr (assq op *special-forms*))))
         (or handler (error "No handler for fixed form: " self))
         (handler self -c-)))
      (else
       (compile-call-form op args false -c-)))))

(require "source/compiler/emit-x86-objects.l")

(define-method emit-prelude <x86-64-compiler> ()
  (verbosity 1 (warn "\nCompiling to x86-64\n\n"))
  (initialize-object-emitters))

(require "source/compiler/emit-x86-late.l")
