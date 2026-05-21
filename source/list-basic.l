;;; -*- mode: lisp; coding: us-ascii -*-

(define-function ensure-list (obj)
  (if (pair? obj) obj (list obj)))

(define-function member? (key list)
  (while (and (pair? list)
              (not (= key (car list))))
    (set list (cdr list)))
  (car list))

;; TODO ? usually push is (push element list), i.e. the opposite order
;; but this way it could support an &rest API
(define-form push (place element)
  `(set ,place (cons ,element ,place)))

(define-form pop (list)
  `(let* ((_list_ ,list)
          (_head_ (car _list_)))
     (set ,list (cdr _list_))
     _head_))

(define-function concat-lists args
  (let ((result (pop args)))
    (while (pair? args)
      (set result (concat-list result (pop args))))
    result))
