;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A simple memory buffer with dynamic reallocation

;; TODO all the new-<long> and get/long could be simplified if the gc supported opaque slots (as opposed to entire objects being opaque)

(define-record <buffer> () (contents capacity position))

(define-constant buffer/initial-capacity 32)

(define-function new-<buffer> ()
  (gc/let* ((buf (new-record-instance <buffer>)))
    (set (<buffer>-contents buf) (gc/allocate-opaque <data> buffer/initial-capacity))
    (set (<buffer>-capacity buf) (new-<long> buffer/initial-capacity))
    (set (<buffer>-position buf) (new-<long> 0))
    buf))

(define-function buffer/grow (buf)
  (let* ((capacity (get/long (<buffer>-capacity buf)))
         (contents (gc/allocate-opaque <data> (* 2 capacity))))
    (libc/memcpy contents (<buffer>-contents buf) capacity)
    (set (<buffer>-contents buf) contents)
    (set (<buffer>-capacity buf) (new-<long> (* 2 capacity)))))

(define-function buffer/append (buf c)
  (let ((pos (get/long (<buffer>-position buf)))
        (cap (get/long (<buffer>-capacity buf))))
    (when (= pos cap)
      (buffer/grow buf))
    (set (string-at (<buffer>-contents buf) pos) c)
    (set (<buffer>-position buf) (new-<long> (+ 1 pos)))))

(define-function buffer/append-all (buf cstr)
  (let ((i 0)
        (c 0))
    (while (set c (string-at cstr i))
      (buffer/append buf c)
      (incr i))))

(define-function buffer/contents (buf)
  (buffer/append buf 0)
  (let ((pos (get/long (<buffer>-position buf))))
    (set (<buffer>-position buf) (new-<long> (- pos 1))))
  (<buffer>-contents buf))

(define-function buffer/position (buf)
  (get/long (<buffer>-position buf)))
