;;; -*- mode: lisp; coding: us-ascii -*-

(define-function ensure-list (obj)
  (if (pair? obj) obj (list obj)))

(define-function member? (key list)
  (while (and (pair? list)
              (not (= key (car list))))
    (set list (cdr list)))
  (car list))

(define-form push (list element)
  `(set ,list (cons ,element ,list)))

(define-form pop (list)
  `(let* ((_list_ ,list)
          (_head_ (car _list_)))
     (set ,list (cdr _list_))
     _head_))
