;;; -*- mode: lisp; coding: us-ascii -*-

(define-form for (var-init-limit-step . body)
  (let ((var       (car    var-init-limit-step)    )
        (init      (cadr   var-init-limit-step)    )
        (limit     (caddr  var-init-limit-step)    )
        (step  (or (cadddr var-init-limit-step) 1)))
    `(let ((,var ,init)
           (_limit_ ,limit))
       (while (not (= ,var _limit_))
         ,@body
         (set ,var (+ ,var ,step))))))

(define-form list-do (var list . body)
  `(let ((_list_ ,list))
     (while _list_
       (let* ((,var (car _list_))) ,@body) ; let* allows (list-do (var1 var2...) list-of-lists)
       (set _list_ (cdr _list_)))))

(define-form until (condition . body)
  `(while (not ,condition) ,@body))

(define-form times-do (count . body)
  `(let ((__i__ ,count))
     (while (<= 0 (decr __i__))
       ,@body)))

(define-function %loop-inits (bindings)
  (and bindings
       (cons (list (caar bindings) (cadar bindings))
             (%loop-inits (cdr bindings)))))

(define-function %loop-steps (bindings)
  (and bindings
       (cons (list 'set (caar bindings) (caddar bindings))
             (%loop-steps (cdr bindings)))))

(define-form loop (bindings test . body)
  `(let ,(%loop-inits bindings)
     (while ,test
       ,@body
       ,@(%loop-steps bindings))))

(define-function %vector-do (get len var col body)
  `(let* ((_col_ ,col)
          (_idx_ 0)
          (_end_ (,len _col_)))
     (while (< _idx_ _end_)
       (let ((,var (,get _col_ _idx_))) ,@body)
       (set _idx_ (+ _idx_ 1)))))

(define-form array-do	(var arr . body)	(%vector-do array-at  array-length  var arr body))
(define-form string-do	(var str . body)	(%vector-do string-at string-length var str body))
