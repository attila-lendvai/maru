;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

(define-form when (test . body)
  `(if ,test (let () ,@body) ()))

(define-form unless (test . body)
  `(if ,test () ,@body))

(define-form assert (test . args)
  (unless args
    (set args (list "assertion failed: " `(quote ,test))))
  `(unless ,test
     (error ,@args)))

(define-structure <module>      (symbols env))

(define-form define-externs args
  `(let ()
     ,@(map (lambda (libc-name)
              (let ((maru-name (concat-symbol 'libc/ libc-name)))
                `(define ,maru-name (extern ,(symbol->string libc-name)))))
            args)))

(define-function structure-field-count (type)
  (list-length (array-at %structure-fields type)))
