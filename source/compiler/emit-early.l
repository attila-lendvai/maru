;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")

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

(define-selector compile)
(define-selector compile-definition)
(define-selector compile-call-to)

;;;
;;; FFI
;;;
;; TODO these should be in the c based platform file, but that is loaded into the target...
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
   type
   attributes ; for stuff like thread_local for llvm
   ))

(define-function C-variable (foreign-name type . attributes)
  (make <C-variable>
    (name	foreign-name)
    (type	type)
    (attributes	attributes)))

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
        (when (< var-level comp-level)
          (error "cannot access variable "var", closures are not yet supported by the compiler.")))))

(load "source/compiler/target.l")
