;;; -*- mode: lisp; coding: us-ascii -*-

;;(define-type <stream>)
(define-record <stream> () ())

;; we need to override the default error form so that the compiler can eat them
(define-selector $at-end?	(stream) (error "missing method for $at-end?"))
(define-selector $peek		(stream) (error "missing method for $peek"))
(define-selector $next		(stream) (error "missing method for $next"))
