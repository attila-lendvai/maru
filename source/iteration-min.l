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
  `(for (__i__ 0 ,count)
     ,@body))

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
