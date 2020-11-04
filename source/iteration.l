;;; -*- mode: lisp; coding: us-ascii -*-

(define-form list-detect (name list expr)
  `(let ((_ ())
         (__ ,list))
     (while (and __ (not _))
       (let ((,name (car __)))
         (and ,expr (set _ (car __)))
         (set __ (cdr __))))
     _))

(define-form array-detect (name arr expr)
  `(let* ((_ ())
          (_a ,arr)
          (_l (array-length _a)))
     (for (_i 0 _l)
       (let ((,name (array-at _a _i)))
         (and ,expr (let () (set _ ,name) (set _i _l)))))
     _))

;; TODO use key-var value-var instead?
;; (define-form alist-do (var alist . body)
;;   `(let ((_list_ ,alist))
;;      (while _list_
;;        (let*  ((,var (cdar _list_))) ,@body)
;;        (set _list_ (cdr _list_)))))

;;; generic iteration

(define-method for-each <pair>   (function)	(list-do   _elt_ self (function _elt_)))
(define-method for-each <array>  (function)	(array-do  _elt_ self (function _elt_)))
(define-method for-each <string> (function)	(string-do _elt_ self (function _elt_)))

(define-function for-each-with (collection function value)
  (for-each collection (lambda (x) (function x value))))
