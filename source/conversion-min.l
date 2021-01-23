;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO is this useless in this form if the caller needs to gc/let* the return value?
;; TODO or is this number->string? how shall we call word-sized integers in the target? long? or is <long> the wrong name on the interpreter side?
;; TODO clarify boxed/unboxed for the arg and return value; entire file
(define-function long->string (num)
  (let ((radix		10)
        (negative?	false))
    (gc/let* ((result (string 10)))
      (when (< num 0)
        (set negative? true)
        (set num (- num)))
      (if (= 0 num)
          (string-append result ?0)
        (while (< 0 num)
          (let* ((next	(/ num radix))
                 (digit	(- num (* next radix))))
            (string-insert result 0 (+ ?0 digit))
            (set num next)))
        ;; or alternatively, we can append, and then reverse in one go
        ;;(string-reverse! result)
        )
      (when negative?
        (string-insert result 0 ?-))
      result)))

(define-function string->long (str)
  (let ((radix	10)
        (num	0)
        (i	0)
        (len	(string-length str))
        (sign 1))
    (when (and (< i len)
               (= ?- (string-at str i)))
      (set sign (- sign))
      (incr i))
    (while (< i len)
      (let* ((c (string-at str i))
             (d (cond
                  ((and (<= ?0 c) (<= c ?9))	      (- c ?0) )
                  ((and (<= ?A c) (<= c ?Z))	(+ 10 (- c ?A)))
                  ((and (<= ?a c) (<= c ?z))	(+ 10 (- c ?a)))
                  (else				radix          ))))
        (if (< d radix)
            (let ()
              (set num (+ (* radix num) d))
              (incr i))
          (set len i))))
    (* sign num)))
