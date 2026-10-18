;;; -*- mode: lisp; coding: us-ascii -*-
(define-record <embedded-stream> <stream> (data position))

(define-function embedded-stream (data)
  (make/opaque <embedded-stream> (data (string->C-string data)) (position 0)))

(define-method $at-end? <embedded-stream> ()
  (= 0 (byte-at self.data self.position)))

(define-method $peek <embedded-stream> ()
  (let ((c (byte-at self.data self.position)))
    (if (= c 0) +end+ c)))

(define-method $next <embedded-stream> ()
  (let ((c (byte-at self.data self.position)))
    (if (= c 0) +end+
      (begin (set self.position (+ self.position 1)) c))))

(define-function embedded-path=? (a b)
  (let ((i 0) (b (string->C-string b)))
    (while (and (!= 0 (byte-at a i)) (= (byte-at a i) (byte-at b i)))
      (set i (+ i 1)))
    (= (byte-at a i) (byte-at b i))))

