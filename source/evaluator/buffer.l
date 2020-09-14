;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A simple memory buffer with dynamic reallocation

(define-record <buffer> () (size elements))

(define-vector-accessors <buffer>	buffer	t	string-at	copy-bytes	1)

(define-function new-<buffer> ()
  (let ((initial-capacity 32))
    (with-instance-accessors self <buffer>
      (gc/let* ((self (new-record-instance <buffer>)))
        (set self.elements (gc/allocate-opaque <data> initial-capacity))
        (set self.size (new-<long> 0))
        self))))

(define-function buffer-contents (self)
  (buffer-ensure-zero-terminated self)
  (<buffer>-elements self))

(define-function buffer-append-string (buf str)
  (let ((i 0)
        (c 0))
    (while (set c (string-at str i))
      (buffer-append buf c)
      (incr i))))
