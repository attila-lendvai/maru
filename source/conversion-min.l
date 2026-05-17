;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO clarify boxed/unboxed for the arg and return value; entire file

(define-function digit->char (digit)
  (if (<= digit 9)
      (+ ?0 digit)
    (+ ?a (- digit 10))))

(define-function positive-long->string (num radix emitter)
  (if (< num radix)
      (emitter (digit->char num))
    (let ((next	(/ num radix)))
      (positive-long->string next radix emitter)
      (emitter (digit->char (- num (* next radix))))))
  num)

(define-function long->string/emit (num radix emitter)
  (safety 1 (assert (and (< 0 radix) (<= radix 35))))
  (if (<= 0 num)
      (positive-long->string num radix emitter)
    (emitter ?-)
    (positive-long->string (- num) radix emitter))
  num)
