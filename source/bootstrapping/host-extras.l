;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host module while evolving from the previous stage.
;;;

;; Mark the fact that we are evolving from the previous stage.
(set evolving? true)
(eval-in-slave '(set evolving? true))

;;;
;;; Temporary definitions that are needed to enable our host to bootstrap us.
;;;

;; changed the semantics
(define-form define-symbol-form (name replacement)
  ;; NOTE unless we instantiate the FORM in the body of the macro
  ;; then in the bootstrap environment it will be bound to the target
  ;; implementation of FORM.
  (let ((replacement (eval replacement *env*)))
    `(define ,name ,(form () (lambda _ replacement)))))

;; this got renamed
(define number->string long->string)

;; these are new. let's just drop the stream arg for the host.
(define print-all (lambda args (apply print (cdr args))))
(define dump-all  (lambda args (apply dump  (cdr args))))

(define-form define-print-method (type . body)
  `(define-method do-print ,type ()
     (let ((-stream- ()))
       ,@body)))

(define-function %typecase (clauses)
  (when (pair? clauses)
    (let* ((clause	(car clauses))
           (type	(car clause))
           (body	(cdr clause)))
      (if (= 'else type)
          (%maybe-progn body)
        `(if (is ,type __value__)
             (let ()
               ,@body)
           ,(%typecase (cdr clauses)))))))

(define-form typecase (value . clauses)
  `(let ((__value__ ,value))
     ,(%typecase clauses)))
