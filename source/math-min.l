;;; -*- mode: lisp; coding: us-ascii -*-

(define-function max (a b)
  (if (> a b) a b))

(define-function min (a b)
  (if (< a b) a b))

(define-function zero? (x)
  (= 0 x))
