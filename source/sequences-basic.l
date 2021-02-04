;;; -*- mode: lisp; coding: us-ascii -*-

;; (define-function array-append-all (arr . vals)
;;   (list-do val vals (array-append arr val)))
;; (define-function array-append-all (a s)
;;   (string-do e s (array-append a e))
;;   s)

(define concat-string
  (lambda (x y)
    (let ((x-len (string-length x))
          (y-len (string-length y)))
      (let ((res (string (+ x-len y-len)))
            (res-idx 0))
        (let ((i 0))
          (while (< i x-len)
            (set-string-at res res-idx (string-at x i))
            (set i (+ i 1))
            (set res-idx (+ res-idx 1))))
        (let ((i 0))
          (while (< i y-len)
            (set-string-at res res-idx (string-at y i))
            (set i (+ i 1))
            (set res-idx (+ res-idx 1))))
        res))))

(define concat-strings
  (lambda args
    (let ((result (car args)))
      (while (set args (cdr args))
        (set result (concat-string result (car args))))
      result)))

(define concat-symbol
  (lambda (x y)
    (string->symbol (concat-string (symbol->string x) (symbol->string y)))))

(define concat-symbols
  (lambda args
    (let ((result (car args)))
      (while (symbol? (car (set args (cdr args))))
        (set result (concat-symbol result (car args))))
      result)))

(define-function list-length (list)
  (assert (or (not list) (pair? list)) "LIST-LENGTH called with an improper list: " list)
  (if (pair? list)
      (let ((len 1))
        (while (set list (cdr list))
          (set len (+ len 1)))
        len)
    0))

(define-function list-remove (key list)
  (let ((result ())
        (last ()))
    (while list
      (unless (= key (car list))
        (let ((new (cons (car list))))
          (if last
              (set (cdr last) new)
            (set result new))
          (set last new)))
      (set list (cdr list)))
    result))

(define-function list-reverse (lst)
  (let ((result ()))
    (while (pair? lst)
      (push result (pop lst)))
    result))

(define-function list-reverse! (head)
  (let ((curr head)
        (prev ())
        (next ()))
    (while curr
      (set next (cdr curr))
      (set (cdr curr) prev)
      (set prev curr)
      (set curr next))
    prev))

(define-function map1 (function list)
  (let ((head (cons)))
    (let ((tail head))
      (while (pair? list)
        (set tail (set (cdr tail) (cons (function (car list)) ())))
        (set list (cdr list))))
    (cdr head)))

(define-function mapN (function lists)
  (and (pair? (car lists))
       (cons (apply function (map1 car lists))
             (mapN function (map1 cdr lists)))))

(define-function map (function . lists)
  (if (pair? (cdr lists))
      (mapN function lists)
    (map1 function (car lists))))

(define-function map-with (function list a)
  (if (pair? list)
      (let ((head (function (car list) a)))
        (cons head (map-with function (cdr list) a)))))
