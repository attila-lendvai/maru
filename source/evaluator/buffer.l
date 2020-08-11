;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; A simple memory buffer with dynamic reallocation, based on malloc

;; TODO FIXME this crashes the gc when inside (compile-begin)
;;(define-record <buffer> () (contents capacity position))

(define-function new_buffer ()
  (let ((buf (libc/malloc (byte-size-of <buffer>))))
    (set (<buffer>-contents buf) (libc/malloc 32))
    (set (<buffer>-capacity buf) 32)
    (set (<buffer>-position buf) 0)
    buf))

(define-function buffer_delete (buf)
  (libc/free (<buffer>-contents buf))
  (libc/free buf))

(define-function buffer_grow (buf)
  (let* ((size     (<buffer>-capacity buf))
         (contents (libc/malloc (* 2 size))))
    (libc/memcpy contents (<buffer>-contents buf) size)
    (libc/free (<buffer>-contents buf))
    (set (<buffer>-contents buf) contents)
    (set (<buffer>-capacity buf) (* 2 size))))

(define-function buffer_append (buf c)
  (and (= (<buffer>-position buf) (<buffer>-capacity buf))
       (buffer_grow buf))
  (let ((posn (<buffer>-position buf)))
    (set-string-at (<buffer>-contents buf) posn c)
    (set (<buffer>-position buf) (+ 1 posn))))

(define-function buffer_append_all (buf s)
  (let ((i 0)
        (c 0))
    (while (set c (string-at s i))
      (buffer_append buf c)
      (set i (+ 1 i)))))

(define-function buffer_contents (buf)
  (buffer_append buf 0)
  (decr (<buffer>-position buf))
  (<buffer>-contents buf))
