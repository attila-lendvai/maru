;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A simple memory buffer with dynamic reallocation, based on malloc

(define-record <buffer> () (contents capacity position))

(define-function new-<buffer> ()
  (let ((buf (libc/malloc (byte-size-of <buffer>))))
    (set (<buffer>-contents buf) (libc/malloc 32))
    (set (<buffer>-capacity buf) 32)
    (set (<buffer>-position buf) 0)
    buf))

(define-function buffer_delete (buf)
  (libc/free (<buffer>-contents buf))
  (libc/free buf))

(define-function buffer/grow (buf)
  (let* ((capacity (<buffer>-capacity buf))
         (contents (libc/malloc (* 2 capacity))))
    (libc/memcpy contents (<buffer>-contents buf) capacity)
    (libc/free (<buffer>-contents buf))
    (set (<buffer>-contents buf) contents)
    (set (<buffer>-capacity buf) (* 2 capacity))))

(define-function buffer/append (buf c)
  (and (= (<buffer>-position buf) (<buffer>-capacity buf))
       (buffer/grow buf))
  (let ((pos (<buffer>-position buf)))
    (set (string-at (<buffer>-contents buf) pos) c)
    (set (<buffer>-position buf) (+ 1 pos))))

(define-function buffer/append-all (buf cstr)
  (let ((i 0)
        (c 0))
    (while (set c (string-at cstr i))
      (buffer/append buf c)
      (incr i))))

(define-function buffer/contents (buf)
  (buffer/append buf 0)
  (decr (<buffer>-position buf))
  (<buffer>-contents buf))
