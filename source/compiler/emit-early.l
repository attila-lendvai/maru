;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")
(require "source/compiler/c-ffi.l")

;; FIXME only works at 1 and below. comments need to be escaped:
;; there's only single-line comment syntax in llvm and gas. escape
;; newlines and the comment syntax chars.
(define *compiler-verbosity* 0)

(define-constant +maru-label-prefix+ "m_")

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

;; TODO shouldn't these be in the slave? or maybe even in the target (it's a form, i.e. not emitted)
(define-constant feature/redefinable-functions-in-target ()) ; costs about 20-30% time increase in the bootstrap process
(define-constant feature/strict-semantics-for-compiled-set true) ; compiled set-oop-at & co. also returns the value that was just set

(define-selector compile-object)
;; TODO its default should be specified like this:
;; (define-selector compile (-c-)
;;   (compile-object self -c-))
;; but due to load order headaches we set the default in emit-x86-objects.l
(define-selector compile)
(define-selector compile-definition)
(define-selector compile-call-to)
;; forwards
(define compile-expr)
(define compile-env)
(define new-arg)
(define free-args)
(define new-temp) ; forward
(define %free-temp) ; forward

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

;; this, and the whole emit-object business is kinda KLUDGEy
(define-function compile-array (self -c-)
  (let ((compiled (array (array-length self))))
    (for (i 0 (array-length self))
      (let ((obj (array-at self i)))
        (set (array-at compiled i)
             (typecase obj
               (<long>		(compile-object obj -c-))
               (<expr>		(compile-expr   obj () -c-))
               (<undefined>	(compile-object obj -c-))
               (else (error "compile-array: don't know how to compile: "obj))))))
    compiled))

;;;
;;; Operands
;;;

(define-function define-operand/make-setters (type-name fields)
  (when (pair? fields)
    (cons `(set (slot-value ,type-name ,(car fields) self) ,(car fields))
          (define-operand/make-setters type-name (cdr fields)))))

(define-form define-operand (name super . rest)
  (let* ((direct-slots	(pop rest))
         (type-name	(symbol->type-name name))
         (type		(eval `(define-record ,type-name ,(when super (symbol->type-name super))
                                 ,direct-slots)))
         (effective-slots (<record>-effective-slots type)))
    (assert (is <record> type))
    (eval `(define-function ,name ,effective-slots
             (let ((self (new ,type-name)))
               ,@(define-operand/make-setters type-name effective-slots)
               self)))
    (when rest
      `(define-print-method ,type-name (print-all -stream- ,@rest)))))

;;;
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
        (when (< var-level comp-level)
          (error "cannot access variable "var", closures are not yet supported by the compiler.")))))

;;;
;;; Instructions
;;;

(define-record <instruction> ()
  ;; TODO some of these slots are the same for all instances; they should reside on the type
  (regs
   has-input?
   n-regs
   produces-output?
   ))

(define-generic emit-instruction)

(define-form emit (instr-name . args)
  `(%emit -c- ,instr-name (list ,@args)))

(define-function %emit (-c- factory args)
  (let* ((instr (factory ())))
    (when (<= 3 *compiler-verbosity*)
      ;; TODO move this into emit-instruction?
      (println "; EMIT of "instr", args: " args))
    (apply emit-instruction (cons -c- (cons instr args)))))

(define-function %emit-form/mm-params (index types)
  (when (pair? types)
    (let ((param-name (string->symbol (concat-string "$" (number->string index)))))
      (cons (list (awhen (and (not (= (first types) '_))
                              (first types))
                    (symbol->type-name it))
                  param-name)
            (%emit-form/mm-params (+ index 1) (cdr types))))))

(define-function %emit-form/reg-accessor (index)
  (let ((var-name (string->symbol (concat-string "$reg" (number->string (+ index 1)))))
        (body `(array-at __regs__ ,index)))
    (list var-name () `((_) ',body))))

(define-function %emit-form/reg-accessors (index)
  (when (<= 0 index)
    (cons (%emit-form/reg-accessor index)
          (%emit-form/reg-accessors (- index 1)))))

(define-function %define-instruction/emit-forms (instr-name n-regs type-name emit-forms)
  (when (pair? emit-forms)
    (let* ((emit-form (first emit-forms))
           (args (first emit-form))
           (body (rest emit-form)))
      ;; TODO what about dispatching on -c-?
      ;; (cons `(define-multimethod emit-instruction ((<llvm-compiler> -c-) (,type-name self) ,@(%emit-form/mm-params 1 args))
      (cons `(define-multimethod emit-instruction (-c- (,type-name self) ,@(%emit-form/mm-params 1 args))
               ;;(println "; emitting " self)
               (let ((__regs__ (<instruction>-regs self)))
                 (with-forms (,@(%emit-form/reg-accessors (- n-regs 1)))
                   ,@body)))
            (%define-instruction/emit-forms instr-name n-regs type-name (rest emit-forms))))))

;; FIXME n-regs should be extracted from the definition
(define-form define-instruction/emit-forms (instr-name n-regs . emit-forms)
  `(let ()
     ,@(%define-instruction/emit-forms instr-name n-regs (symbol->type-name instr-name) emit-forms)))

;; (define-instruction name (has-input? n-regs produces-output?) emit-forms)
(define-form define-instruction (instr-name reg-spec . emit-forms)
  (let ((has-input?		(first reg-spec))
        (n-regs			(or (second reg-spec) 0))
        (produces-output?	(third reg-spec))
        (type-name		(symbol->type-name instr-name))
        (singleton-name		(concat-symbol instr-name '-instance)))
    `(let ()
       (define-record ,type-name <instruction> ())
       ;;(define-print-method ,type-name (print-all -stream- ,(symbol->string name)))
       (define ,singleton-name (make ,type-name
                                 (has-input?		,has-input?)
                                 (n-regs		',n-regs)
                                 (produces-output?	,produces-output?)))
       (define-function ,instr-name (regs)
         (if regs
             (make ,type-name
               (regs			regs)
               (has-input?		,has-input?)
               (n-regs			',n-regs)
               (produces-output?	,produces-output?))
           ,singleton-name))

       ,@(%define-instruction/emit-forms instr-name n-regs type-name emit-forms))))

;; this is faster than (emit COMMENT ...) by skipping the evaluation early
(define-form emit-comment (level . args)
  `(when (<= ,level *compiler-verbosity*)
     (emit COMMENT (list ,@args))))

;;;
;;; Compiler
;;;

(define-form comp (obj)
  `(let ((__obj__ ,obj))
     (emit-comment 2 "COMPILE of "__obj__)
     (compile __obj__ -c-)
     (<compiler>-current-value -c-)))

(define-form gen (instr-name . args)
  `(%gen -c- ,instr-name (list ,@args)))

(define-function emit-gen-buffer (-c-)
  (array-do entry (<compiler>-gen-buffer -c-)
    (let* ((instr (first entry))
           (args (rest entry)))
      ;; TODO commented out due to load order headache...
      ;; (emit-comment 2 "EMIT-INSTRUCTION of "instr", args: "args)
      (apply emit-instruction (cons -c- (cons instr args))))))

(load "source/compiler/target.l")
