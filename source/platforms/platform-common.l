;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Common defs for all platforms.

(define-form align-address-up (var page-size)
  `(bitwise-and (+ ,var (- ,page-size 1))
                (- ,page-size)))

(define-form align-address-down (var page-size)
  `(bitwise-and ,var (- ,page-size)))
