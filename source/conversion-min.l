;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO clarify boxed/unboxed for the arg and return value; entire file

;; KLUDGE implement closure compilation and delme
(define %long->string/buffer)

(define-function digit->string (digit emitter)
  (emitter (if (<= digit 9)
               (+ ?0 digit)
             (+ ?a (- digit 10)))))

(define-function long->string/positive (num radix emitter)
  (if (< num radix)
      (digit->string num emitter)
    (let ((next	(/ num radix)))
      (long->string/positive next radix emitter)
      (digit->string (- num (* next radix)) emitter)))
  num)

(define-function long->string/emit (num radix emitter)
  (safety 1 (assert (and (< 0 radix) (<= radix 35))))
  (if (<= 0 num)
      (long->string/positive num radix emitter)
    (emitter ?-)
    (long->string/positive (- num) radix emitter))
  num)

;; TODO the GC/LET* makes it useless for the evaluator.
;; a temp solution could be to simply expand to a let* in the evaluator?
(define-function long->string* (num radix)
  (safety 1 (assert (and (< 0 radix) (<= radix 35))))
  (gc/let* ((result (string 10)))
    (set %long->string/buffer result)   ; KLUDGE
    (long->string/emit num radix
                       (lambda (char)
                         ;; TODO (string-append result char)
                         (string-append %long->string/buffer char)))
    result))

;; TODO or is this number->string? how shall we call word-sized integers in the target? long? or is <long> the wrong name on the interpreter side?
(define-function long->string (num)
  (long->string* num 10))

(define-function string->long* (str radix)
  ;; KLUDGE this is ugly: we use +END+ as a marker that the parsing
  ;; didn't finish cleanly. to clean this up the compiler needs to
  ;; support returning multiple values, or something else to
  ;; communicate success/failure.
  (safety 1 (assert (and (< 0 radix) (<= radix 35))))
  (let ((num	0)
        (i	0)
        (len	(string-length str))
        (sign 1))
    (when (and (< i len)
               (= ?- (string-at str i)))
      (set sign (- sign))
      (incr i))
    (if (= 0 (- len i))
        +end+               ; nothing left after a possible minus sign
      (while (< i len)
        (let* ((c (string-at str i))
               (d (cond
                    ((and (<= ?0 c) (<= c ?9))	      (- c ?0) )
                    ((and (<= ?A c) (<= c ?Z))	(+ 10 (- c ?A)))
                    ((and (<= ?a c) (<= c ?z))	(+ 10 (- c ?a)))
                    (else
		     (return +end+)))))
          (unless (< d radix)
            (return +end+))
          (set num (+ (* radix num) d))
          (incr i)))
      (* sign num))))

(define-function string->long (str)
  (let ((res (string->long* str 10)))
    (when (= res +end+)
      (error "string->long: failed for "str))
    res))
