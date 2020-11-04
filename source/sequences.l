;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/sequences-basic.l")

(define-function reverse-map (function list)
  (and list
       (let ((tail (reverse-map function (cdr list))))
         (cons (function (car list)) tail))))

(define-function reverse-with-map (function arg list)
  (and list
       (let ((tail (reverse-with-map function arg (cdr list))))
         (cons (function arg (car list)) tail))))

(define-function reverse-map-with (function list arg)
  (and list
       (let ((tail (reverse-map-with function (cdr list) arg)))
         (cons (function (car list) arg) tail))))

(define-function with-map (function a list)
  (if (pair? list)
      (let ((head (function a (car list))))
        (cons head (with-map function a (cdr list))))))

(define-function map-with2 (function list a b)
  (if (pair? list)
      (let ((head (function (car list) a b)))
        (cons head (map-with2 function (cdr list) a b)))))

(define-function with2-map (function a b list)
  (if (pair? list)
      (let ((head (function a b (car list))))
        (cons head (with2-map function a b (cdr list))))))

(define-function with-map2 (function a alist blist)
  (if (pair? alist)
      (let ((head (function a (car alist) (car blist))))
        (cons head (with-map2 function a (cdr alist) (cdr blist))))))

(define-function map2-with (function alist blist a)
  (if (pair? alist)
      (let ((head (function (car alist) (car blist) a)))
        (cons head (map2-with function (cdr alist) (cdr blist) a)))))

(define-function map* (function . lists)
  (if (pair? (car lists))
      (let ((head (apply function (map car lists))))
        (cons head (apply map* (cons function (map cdr lists)))))))

(define-function foldr (op value list)
  (if (pair? list)
      (op (car list) (foldr op value (cdr list)))
    value))

(define-function zip lists
  (apply map (cons list lists)))

(define-function zip-assocs (a b)
  (if (and (pair? a) (pair? b))
      (cons (cons (car a) (car b)) (zip-assocs (cdr a) (cdr b)))
    (or a b)))

;;; sequences

(define-method length <string> ()		(string-length self))
(define-method length <array> ()		(array-length self))

(define-method at <string> (index)		(string-at self index))
(define-method at <array> (index)		(array-at self index))

(define-method set-at <string> (index value)	(set-string-at self index value))
(define-method set-at <array> (index value)	(set-array-at self index value))

;;; sorting and searching

(define-function %partition (items at set-at compare left pivot right)
  (let ((index left)
        (value (at items pivot)))
    (set-at items pivot (at items right))
    (set-at items right value)
    (for (i left right)
      (and (compare (at items i) value)
           (let ((item (at items i)))
             (set-at items i (at items index))
             (set-at items index item)
             (set index (+ index 1)))))
    (set value (at items index))
    (set-at items index (at items right))
    (set-at items right value)
    index))

(define-function %sort (items at set-at compare left right)
  (and (< left right)
       (let* ((pivot (/ (+ left right) 2))
              (index (%partition items at set-at compare left pivot right)))
         (%sort items at set-at compare left (- index 1))
         (%sort items at set-at compare (+ index 1) right))))

(define-function array-sort (items . options)
  (%sort items array-at set-array-at (or (car options) <) 0 (- (array-length items) 1))
  items)

(define-function string-sort (items . options)
  (%sort items string-at set-string-at (or (car options) <) 0 (- (string-length items) 1))
  items)

(define-function %search (items length at obj compare)
  (let ((lo 0)
        (hi (- (length items) 1))
        (ix ()))
    (while (<= lo hi)
      (let* ((m (/ (+ lo hi) 2))
             (s (at items m))
             (c (compare obj s)))
        (cond
          ((< c 0)	(set hi (- m 1)))
          ((> c 0)	(set lo (+ m 1)))
          (else		(set ix m) (set lo (+ hi 1))))))
    ix))

(define-function array-search  (arr obj . options)	(%search arr array-length  array-at  obj (or (car options) -)))
(define-function string-search (str obj . options)	(%search str string-length string-at obj (or (car options) -)))
