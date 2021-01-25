;;; -*- mode: lisp; coding: us-ascii -*-

;;(define-type <stream>)
(define-record <stream> () ())

;; TODO we need to override the default error if we want to be able to compile these
(define-selector $at-end?	(stream) (error "missing method for $at-end?"))
(define-selector $peek		(stream) (error "missing method for $peek"))
(define-selector $next		(stream) (error "missing method for $next"))
