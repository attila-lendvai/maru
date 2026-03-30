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
;;;   - see *special-operators* and *special-forms* for the list of specially
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

(define-print-method <STACK-CELL> (print-all -stream- self.offset"(%rsp)"))

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

(define-instruction/emit-forms MUL 0
  ((STACK-CELL)			(println "	mulq	"$1)))

(define-instruction/emit-forms DIV 0
  ((STACK-CELL)			(println "	xor	%rdx, %rdx")
                                (println "	divq	"$1)))

(define-instruction ADDR	(false 0 true)
  ((GLOBAL-CELL)		(println "	lea	"$1"(%rip), %rax"))
  ((STACK-CELL)			(println "	lea	"$1", %rax")))

(define-instruction/emit-forms MOVE 0
  ((STACK-CELL STACK-CELL)	(println "	mov	"$1", %rbx")
                                (println "	mov	%rbx, "$2)))

(define-instruction/emit-forms LOAD 0
  ((GLOBAL-CELL)		(println "	lea	"$1"(%rip), %rax")
				(println "	mov	(%rax), %rax"))
  ((STACK-CELL)			(println "	mov	"$1", %rax"))
  ;; TODO working inheritance would make this superfluous
  ((STACK-PARAM)		(println "	mov	"$1", %rax")))

(define-instruction/emit-forms LOAD-I8 0
  ((STACK-CELL)			(println "	mov	"$1", %rbx")
                                (println "	lea	(%rax, %rbx), %rbx")
                                (println "	xor	%rax, %rax")
                                (println "	mov	(%rbx), %al")))

(define-instruction/emit-forms STORE-I8 0
  ((STACK-CELL _)		(if-at-expand (feature strict-semantics-for-compiled-set)
				    ;; NOTE this works out just fine for a STACK-CELL, too, because we are little-endian.
                                    (let ()
                                      (println "	mov	"$1", %rbx")
                                      (println "	lea	(%rax, %rbx), %rbx")
                                      (println "	xor	%rax, %rax")
                                      (println "	movb	"$2", %al")
                                      (println "	movb	%al, (%rbx)"))
                                  (println "	lea	"$1"(%rip), %rbx")
                                  (println "	lea	(%rax, %rbx), %rax")
                                  (println "	movb	"$2", (%rax)"))))

(when-at-expand (feature lower/array)
  ;; TODO these two are the same as the -OOP versions, except the lea's multiplier
  (define-instruction/emit-forms LOAD-CELL 0
    ((STACK-CELL)		(println "	mov	"$1", %rbx")
				(println "	lea	(%rax, %rbx, 1), %rbx")
				(println "	mov	(%rbx), %rax")))

  (define-instruction/emit-forms STORE-CELL 0
    ((STACK-CELL _)		(if-at-expand (feature strict-semantics-for-compiled-set)
                                    (let ()
                                      (println "	mov	"$1", %rbx")
                                      (println "	lea	(%rax, %rbx, 1), %rbx")
                                      (println "	mov	"$2", %rax")
                                      (println "	mov	%rax, (%rbx)"))
                                  (println "	mov	"$1", %rbx")
                                  (println "	lea	(%rax, %rbx, 1), %rax")
                                  (println "	mov	"$2", (%rax)")))))

(define-instruction/emit-forms LOAD-OOP 0
  ((STACK-CELL)			(println "	mov	"$1", %rbx")
				(println "	lea	(%rax, %rbx, 8), %rbx")
				(println "	mov	(%rbx), %rax")))

(define-instruction/emit-forms STORE-OOP 0
  ((STACK-CELL _)		(if-at-expand (feature strict-semantics-for-compiled-set)
                                    (let ()
                                      (println "	mov	"$1", %rbx")
                                      (println "	lea	(%rax, %rbx, 8), %rbx")
                                      (println "	mov	"$2", %rax")
                                      (println "	mov	%rax, (%rbx)"))
                                  (println "	mov	"$1", %rbx")
                                  (println "	lea	(%rax, %rbx, 8), %rax")
                                  (println "	mov	"$2", (%rax)"))))

;;;
;;; Compiler Infrastructure
;;;
(define-constant +param-registers+   `(quote ,(list op/rdi op/rsi op/rdx op/rcx op/r8 op/r9)))
(define-constant +n-param-registers+ (list-length +param-registers+))

(define-record <x86-64-compiler> <x86-compiler>
  ())

(define-function x86-64-compiler (level)
  (make <x86-64-compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (gen-buffer			(array))

    (arg-offset			0)
    (arg-limit			0)
    (asm-cell-type		".8byte")
    ))

(define-function run-compiler (env)
  (compile-env env (x86-64-compiler 1)))

(define-function new-stack-cell (-c-)
  (STACK-CELL (* (new-temp-index -c-) +word-size-in-bytes+)))

(define-function %free-temp (-c- obj)
  ;; FIXME this is a mess! %free-temp is called with all kinds of objects...
  (typecase obj
    (<STACK-CELL>	(push (<compiler>-free-stack-cells -c-) obj))))

;;;
;;; Compiling lambdas
;;;

;; this implements the System V AMD64 ABI, i.e. we can call into C
;; code without differenciating between calling into the internal and
;; the C world.
(define-function emit-expr-code (self entry-point-label parent-comp)
  ;; NOTE printing the code as-is, i.e. without escaping, may break the comment syntax
  (let* ((body		(<expr>-body self))
         (-c-		(x86-64-compiler (+ 1 (<compiler>-level parent-comp))))
         (spill-locs	())
         (params	(<expr>-parameters self))
         (param-count	(list-length params)))

    ;; allocate stack-cells for spilling the reg params
    (times-do (min param-count +n-param-registers+)
      (let ((spill-loc	(new-stack-cell -c-))
            (var	(pop params)))
        (set (<variable>-value var) spill-loc)
        (push spill-locs spill-loc)))

    ;; assign the stack locations to the params passed on the stack
    (let ((i 2)) ; 2 is the pushed RBP and the return address
      (list-do var params
        (let ((offset (* i +word-size-in-bytes+)))
          (set (<variable>-value var) (STACK-PARAM offset)))
        (incr i)))

    (emit-comment 1 "emitting "self", at level: "(<compiler>-level parent-comp))
    (emit-comment 3 ", code: "(<expr>-body self))
    ;; Unconditionally spill the params to the stack.
    (let ((regs		+param-registers+)
          (stack-cells	(list-reverse! spill-locs)))
      (times-do (min param-count +n-param-registers+)
        (gen MOVE (pop regs) (pop stack-cells))))

    ;; Compile the fn body first into the gen buffer (COMP is a form,
    ;; we cannot map it).
    (list-do el body
      (comp el))

    ;; Calculate the frame and emit the entire fn
    (let* ((temp-size	(* (<compiler>-temp-limit -c-)
                           +word-size-in-bytes+))
           (frame-size	(align +call-frame-alignmet+
                               (+ temp-size
                                  ;; the pushed %ebp and the return address
                                  (* 2 +word-size-in-bytes+))))
           (frame-body-size (- frame-size (* 2 +word-size-in-bytes+))))
      ;; actual emitting begins
      (emit TEXT)
      (emit DEFLABEL entry-point-label)
      (emit-comment 1 "params: "(list-length (<expr>-parameters self))
                    ", frame-size: "frame-size"("(/ frame-size +word-size-in-bytes+)
                    "), temp-size: "temp-size "("(/ temp-size  +word-size-in-bytes+)")")
      (emit ENTER frame-body-size)
      (emit-comment 1 "emitting gen buffer of "self)
      (emit-gen-buffer -c-)
      (awhen (<x86-compiler>-fn-epilogue-label -c-)
        (emit DEFLABEL it))
      (emit LEAVE frame-body-size)))
  entry-point-label)

;;;
;;; Compiling calls
;;;

(define-function compile-call-form (op args -c-)
  (emit-comment 2 "compile-call: "op", args: "args)
  (safety 2 (assert (or (pair? op) (variable? op))))
  ;; NOTE this implements a left-to-right evaluation order, including the operator.
  ;; i.e. moving this op-tmp means changing the evaluation order!
  (let* ((tmps-to-free	())
         (maybe-store	(lambda (operand)
                          ;; TODO cleanup
                          (if (or (is <R64> operand)
                                  (is <R32> operand))
                              (let ((temp (alloc-temp -c-)))
                                (push tmps-to-free temp)
                                (gen STORE temp)
                                temp)
                            operand)))
         (arg-operands	(map (lambda (expr)
                               (maybe-store (compile/expression-to-operand expr -c-)))
                             args))
         (arg-count	(list-length args))
         (op-value	(if (variable? op)
                            ;; get the value for dispatch purposes
                            (<variable>-value op)
                          ;; compile to a temp or a literal
                          (maybe-store (compile/expression-to-operand op -c-))))
         ;; NOTE here we *must* store the arg values calculated by
         ;; expression into temps (as opposed to storing them straight
         ;; into the arg locations, i.e. first 6 into registers)
         ;; because the arg expression can be of any complexity;
         ;; i.e. they may call other functions, which would overwrite
         ;; the arg registers...
         (arg-stack-cell-count	(max 0 (- arg-count +n-param-registers+)))
         (arg-regs	+param-registers+))

    ;; move the reg passed operands into the regs
    (times-do (min arg-count +n-param-registers+)
      (gen MOVE (pop arg-operands) (pop arg-regs)))

    ;; push the remaining (i.e. stack-passed) arguments in reverse order
    (list-do op (list-reverse! arg-operands)
      (gen PUSH op))

    (let* ((n-params	 (emit-comment 2 "compile-call-to: "op-value)
                         ;; FIXME delete unused arg-locs
                         (compile-call-to op-value op -c-))
           (arity	(list-length args)))
      (when (and n-params
                 (not (= n-params arity)))
        (error "compile: calling "op" with the wrong number of arguments: "
               args", while expecting "n-params)))
    ;;(gen SUB (R64 "%rsp") (LI64 (* arg-stack-cell-count +word-size-in-bytes+)))
    (when (< 0 arg-stack-cell-count)
      (gen INLINE (concat-strings "	add	$"
                                  (number->string
                                   (* arg-stack-cell-count
                                      +word-size-in-bytes+))
                                  ", %rsp")))
    (free-temps tmps-to-free)))

(define-method compile-call-to <STACK-CELL> (op -c-)
  (gen LOAD self)
  (compile-call-to-<target-function> -c-))

;; currently not used anywhere
;; (define-method compile-call-to <R64> (op -c-)
;;   (gen LOAD self)
;;   (compile-call-to-<target-function> -c-))

(define-method compile-call-to <C-function> (op -c-)
  (gen CALL (EXTERNAL-LABEL (<C-function>-name self)))
  (case (<C-function>-return-type self)
    ;; TODO introduce a proper infrastructure for this
    (int
     (gen SEXT op/eax op/rax))
    (short
     (error "TODO sign-extend a short to 64 bits")))
  (unless (<C-function>-vararg? self)
    (list-length (<C-function>-parameter-types self))))

;;;
;;; Special Forms
;;;
(define-function compile/set (expr -c-)
  (let* ((var	(second expr))
         (value	(<variable>-value var)))
    (accessible-variable-or-die var -c-)
    (comp (third expr))
    (cond
      ((or (is <STACK-CELL> value)
           (is <R64> value))
       (gen STORE value))
      ((is <C-variable> value)
       ;; TODO dispatch on the type of the C-variable
       (gen STORE ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
                   (EXTERNAL-LABEL (<C-variable>-name value)))))
      (else
       (gen STORE (GLOBAL-CELL (LABEL (<variable>-name var))))))))

(define-function compile/address-of (expr -c-)
  (let ((var (cadr expr)))
    (or (variable? var) (error "address-of: non-variable argument: "var))
    (let ((val (<variable>-value var)))
      (cond
        ((global-variable? var)
         (gen ADDR (GLOBAL-CELL (LABEL (<variable>-name var)))))
        ((is <STACK-CELL> val)
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
          (gen INLINE "	lea	8(%rbp), %rax")
          (set (<compiler>-current-value -c-) op/rax)))
  ))

;;;
;;; Special Operators
;;;

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (is <R64> value)
           (is <LI64> value)
           (is <STACK-CELL> value)
           (is <STACK-PARAM> value))
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
          (gen LOAD ((if (= 'darwin (target-value +operating-system+)) GOT64 GLOBAL-CELL)
                     (EXTERNAL-LABEL (<C-variable>-name value)))))
         ((and (not (feature redefinable-functions-in-target))
               (is <expr> value))
          (gen LOAD (LABEL self.name)))
         (else
          (gen LOAD (GLOBAL-CELL (LABEL self.name))))))
      (else
       (error "compile of <variable> failed for "self", holding the value: "value", type: "(type-of value))))))

(require "source/compiler/emit-x86-late.l")
