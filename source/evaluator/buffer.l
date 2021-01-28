;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A simple memory buffer with dynamic reallocation

(define-record <buffer> () (size elements))

(define-vector-accessors <buffer> buffer- () byte-at copy-bytes platform/move-bytes 1)

(define-constant +buffer-initial-capacity+ 32)

(define-function buffer ()
  (make <buffer>
    (size	(box <long> 0))
    (elements	(allocate-data +buffer-initial-capacity+))))

(define-function buffer-contents (self)
  (buffer-ensure-zero-terminated self)
  (<buffer>-elements self))

(define-function buffer-append-string (buf str)
  (let ((i 0)
        (c 0))
    (while (set c (char-at str i))
      (buffer-append buf c)
      (incr i))))
