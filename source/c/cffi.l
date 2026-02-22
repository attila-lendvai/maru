;;; -*- mode: lisp; coding: us-ascii -*-

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
   type
   attributes ; for stuff like thread_local for llvm
   ))

(define-function C-variable (foreign-name type . attributes)
  (make <C-variable>
    (name	foreign-name)
    (type	type)
    (attributes	attributes)))
