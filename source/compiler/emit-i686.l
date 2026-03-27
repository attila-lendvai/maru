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
(define LITERAL LI32)

(define-print-method <STACK-CELL> (print-all -stream- self.offset"(%esp)"))

;;;
;;; IA-32 -- INSTRUCTIONS
;;;

;; ENTER is slow, so don't use it (LEAVE is fine): https://stackoverflow.com/questions/5959890/enter-vs-push-ebp-mov-ebp-esp-sub-esp-imm-and-leave-vs-mov-esp-ebp
(define-instruction ENTER	()
  ((long)			(println "	push	%ebp")
				(println "	mov	%esp, %ebp")
				(unless (= 0 $1)
				  (println "	sub	$"$1", %esp"))))

(define-instruction/emit-forms LOAD 0
  ((LABEL)			(println "	mov	$"$1", %eax")))

(define-instruction/emit-forms MUL 0
  ((STACK-CELL)			(println "	mull	"$1)))

(define-instruction/emit-forms DIV 0
  ((STACK-CELL)			(println "	xor	%edx, %edx")
                                (println "	divl	"$1)))

(define-instruction ADDR	(false 0 true)
  ((GLOBAL-CELL)		(println "	mov	$"$1", %eax"))
  ((STACK-CELL)			(println "	lea	"$1", %eax")))

(define-instruction/emit-forms MOVE 0
  ((STACK-CELL STACK-CELL)	(println "	mov	"$1", %ebx")
				(println "	mov	%ebx, "$2)))

(define-instruction/emit-forms LOAD 0
  ((GLOBAL-CELL)		(println "	mov	"$1", %eax"))
  ((STACK-CELL)			(println "	mov	"$1", %eax")))

(define-instruction/emit-forms LOAD-I8 0
  ((STACK-CELL)			(println "	mov	"$1", %ebx")
				(println "	lea	(%eax, %ebx), %ebx")
				(println "	xor	%eax, %eax")
				(println "	movb	(%ebx), %al")))

(define-instruction/emit-forms STORE-I8 0
  ((STACK-CELL _)		(if-at-expand (feature strict-semantics-for-compiled-set)
                                    ;; NOTE this works out just fine for a STACK-CELL, too, because we are little-endian.
                                    (let ()
                                      (println "	mov	"$1", %ebx")
                                      (println "	lea	(%eax, %ebx), %ebx")
                                      (println "	xor	%eax, %eax")
                                      (println "	mov	"$2", %al")
                                      (println "	mov	%al, (%ebx)"))
                                  (println "	mov	"$1", %ebx")
                                  (println "	lea	(%eax, %ebx), %eax")
                                  (println "	movb	"$2", (%eax)"))))

(define-instruction/emit-forms LOAD-OOP 0
  ((STACK-CELL)			(println "	mov	"$1", %ebx")
                                (println "	lea	(%eax, %ebx, 4), %ebx")
                                (println "	mov	(%ebx), %eax")))

(define-instruction/emit-forms STORE-OOP 0
  ((STACK-CELL _)		(if-at-expand (feature strict-semantics-for-compiled-set)
                                    (let ()
                                      (println "	mov	"$1", %ebx")
                                      (println "	lea	(%eax, %ebx, 4), %ebx")
                                      (println "	mov	"$2", %eax")
                                      (println "	mov	%eax, (%ebx)"))
                                  (println "	mov	"$1", %ebx")
                                  (println "	lea	(%eax, %ebx, 4), %eax")
                                  (println "	mov	"$2", (%eax)"))))

;;;
;;; Compiler Infrastructure
;;;
(define-record <x86-32-compiler> <x86-compiler>
  ())

(define-function x86-32-compiler (level)
  (make <x86-32-compiler>
    (level			level)
    (temp-counter		0)
    (temp-limit			0)
    (gen-buffer			(array))


    (param-offset		0)
    (arg-offset			0)
    (arg-limit			0)
    (asm-cell-type		".4byte")
    ))

(define-function run-compiler (env)
  (compile-env env (x86-32-compiler 1)))

(define-function new-temp (-c-)
  (STACK-CELL (* (new-temp-index -c-) +word-size-in-bytes+)))

(define-function %free-temp (-c- obj)
  (when (is <STACK-CELL> obj)
    (push (<compiler>-free-temps -c-) obj)))

;; parameters are what functions have
(define-function new-param (c)
  (with-instance-accessors c <x86-32-compiler>
    (let ((temp	(STACK-CELL c.param-offset)))
      (incr c.param-offset +word-size-in-bytes+)
      temp)))

;; arguments are what we pass to functions when we call them
(define-function new-arg (c)
  (with-instance-accessors c <x86-32-compiler>
    (let* ((offset	c.arg-offset)
           (temp	(STACK-CELL offset)))
      (set c.arg-offset (+ offset +word-size-in-bytes+))
      temp)))

(define-function free-args (c args)
  (with-instance-accessors c <x86-32-compiler>
    (when (< c.arg-limit c.arg-offset)
      (set c.arg-limit c.arg-offset))
    (set c.arg-offset 0)))

;;;
;;; Compiling lambdas
;;;

(define-function emit-expr-code (self entry-point-label parent-comp)
  ;; NOTE printing the code as-is, i.e. without escaping, may break the comment syntax
  (let* ((body		(<expr>-body self))
         (-c-		(x86-32-compiler (+ 1 (<compiler>-level parent-comp))))
         (param-locs
           (map (lambda (var)
                  ;; KLUDGE this writes some internal
                  ;; compiler state (this param's
                  ;; location on the stack) into the
                  ;; source code.
                  (set (<variable>-value var) (new-param -c-)))
                (<expr>-parameters self))))
    (emit-comment 1 "emitting "self", at level: "(<compiler>-level parent-comp))
    (emit-comment 3 ", code: "(<expr>-body self))
    ;; Compile the fn body first into the gen buffer (COMP is a form,
    ;; we cannot map it).
    (list-do el body
      (comp el))
    ;; Calculate the frame and emit the entire fn
    (let* ((arg-size	(<x86-compiler>-arg-limit -c-))
           (temp-size	(* (<compiler>-temp-limit -c-) +word-size-in-bytes+))
           (frame-size	(align +call-frame-alignmet+
                               ;; 2 words: pushed ebp, and the return address (?)
                               (+ arg-size temp-size (* 2 +word-size-in-bytes+))))
           (frame-body-size (- frame-size (* 2 +word-size-in-bytes+))))
      ;; Now that we know the frame size, fix up the offsets of the
      ;; temps allocated on the stack.
      (map (lambda (el)
             (incr (<STACK-CELL>-offset el) arg-size))
           (<compiler>-free-temps -c-))
      ;; Params could also be accessed through %ebp, but for that we
      ;; would need another operand class. Let's just offset them by
      ;; the frame size and use %esp through simple STACK-CELL.
      (map (lambda (el)
             (incr (<STACK-CELL>-offset el) frame-size))
           param-locs)
      ;; actual emitting begins
      (emit TEXT)
      (emit DEFLABEL entry-point-label)
      (emit-comment 1 "params: "(list-length param-locs)
                    ", frame-size: "frame-size"("(/ frame-size +word-size-in-bytes+)
                    "), arg-size: " arg-size  "("(/ arg-size   +word-size-in-bytes+)
                    "), temp-size: "temp-size "("(/ temp-size  +word-size-in-bytes+)")")
      (emit ENTER frame-body-size)
      (emit-gen-buffer -c-) ; emit the body
      (awhen (<x86-compiler>-fn-epilogue-label -c-)
        (emit DEFLABEL it))
      (emit LEAVE frame-body-size)))
  entry-point-label)

;;;
;;; Compiling calls
;;;

(define-method compile-call-to <STACK-CELL> (op arg-locs -c-)
  (gen LOAD self)
  (compile-call-to-<target-function> arg-locs -c-))

;; this case is handled early in compile-call
;; (define-method compile-call-to <pair> (op arg-locs -c-)
;;   (comp op)
;;   (compile-call-to-<target-function> arg-locs -c-))

(define-method compile-call-to <C-function> (op arg-locs -c-)
  (gen CALL (EXTERNAL-LABEL (<C-function>-name self)) arg-locs)
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
    (typecase value
      (<STACK-CELL>
       (gen STORE value))
      (<C-variable>
       ;; TODO dispatch on the type of the C-variable
       (gen STORE (GLOBAL-CELL (EXTERNAL-LABEL (<C-variable>-name value)))))
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
          ;; pushl	%ebp
          ;; movl	%esp, %ebp
          ;; subl	$n, %esp
          ;; ...
          ;;
          ;; so, the 4(%ebp) is to undo the pushl %ebp, so that we
          ;; regain the %rsp value at the entry point to the function.
          (gen INLINE "	lea	4(%ebp), %eax")
          (set (<compiler>-current-value -c-) (R32 "%eax"))))
  ))

;;;
;;; Special Operators
;;;

(define-method compile <variable> (-c-)
  (accessible-variable-or-die self -c-)
  (let ((value self.value))
    (cond
      ((or (is <STACK-CELL> value)
           (is <LI32> value))
       (gen LOAD value))
      ((global-variable? self)
       (cond
         ((= 'true self.name)
          (gen LOAD (LI32 (target-value true))))
         ((subtype? (type-of value) <type>)
          (gen LOAD (LI32 (eval-in-slave `(<type>-slave-id ,value)))))
         ((is <C-function> value) ; handles the situation when e.g. libc/strcmp is passed as a comparator fn for array-binary-search
          (gen LOAD (LI32 (EXTERNAL-LABEL (<C-function>-name value)))))
         ((is <C-variable> value)
          ;; TODO dispatch on the type of the C-variable
          (gen LOAD (GLOBAL-CELL (EXTERNAL-LABEL (<C-variable>-name value)))))
         ((and (not (feature redefinable-functions-in-target))
               (is <expr> value))
          (gen LOAD (LI32 (LABEL self.name))))
         (else
          (gen LOAD (GLOBAL-CELL (LABEL self.name))))))
      (else
       (error "compile of <variable> failed for " self ", holding the value " value)))))

(require "source/compiler/emit-x86-late.l")
