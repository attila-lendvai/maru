;;; -*- mode: lisp; coding: us-ascii -*-

(define-form define-macro (name args . body)
  `(define-form ,name ,args (cons 'let (cons () (macro-expand (zip-assocs ',args (list ,@args)) ',body)))))

(define-function macro-expand (bindings exp)
  (if (pair? exp)
      (cons (macro-expand bindings (car exp))
            (macro-expand bindings (cdr exp)))
    (if (symbol? exp)
        (let ((a (assq exp bindings)))
          (if a (cdr a) exp))
      exp)))

(require "source/iteration.l")

;;; namespace

(define-form define-namespace (name parent)	`(define ,name (environment ,parent)))

(define-form namespace (name)			`(set *globals* ,name))
