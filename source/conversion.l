;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")

(define-function array->string (arr)
  (let* ((ind 0)
         (lim (array-length arr))
         (str (string lim)))
    (while (< ind lim)
      (set-string-at str ind (array-at arr ind))
      (set ind (+ 1 ind)))
    str))

(define-function array->list (arr)
  (let* ((ind (array-length arr))
         (lst ()))
    (while (<= 0 (set ind (- ind 1)))
      (set lst (cons (array-at arr ind) lst)))
    lst))

(define-function list->string (list)
  (let* ((len (list-length list))
         (str (string len))
         (idx 0))
    (while (< idx len)
      (set-string-at str idx (car list))
      (set idx (+ idx 1))
      (set list (cdr list)))
    str))

(define-function character->string (c)
  (let ((s (string 1)))
    (set (string-at s 0) c)
    s))
