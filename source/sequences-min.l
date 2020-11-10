;;; -*- mode: lisp; coding: us-ascii -*-

;; (define-function string-reverse! (str)
;;   (let* ((len	(string-length str))
;;          (limit	(- len 1))
;;          tmp)
;;     (for (i 0 (/ len 2))
;;       (set tmp (char-at str i))
;;       (set (char-at str i) (char-at str (- limit i)))
;;       (set (char-at str (- limit i)) tmp)))
;;   str)

;; TODO is this useless in this form if the caller needs to gc/let* the return value?
;; TODO or is this number->string? how shall we call word-sized integers in the target? long? or is <long> the wrong name on the interpreter side?
(define-function long->string (num)
  (let ((radix		10)
        (negative?	false))
    (gc/let* ((result (string 8)))
      (when (< num 0)
        (set negative? true)
        (set num (- num)))
      (if (= 0 num)
          (string-insert result 0 ?0)
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
