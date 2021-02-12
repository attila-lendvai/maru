;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; generic/multimethod: a function that dispatches on the type of all its arguments, aka multiple dispatch
;;;

(define-record <generic> () (name methods default))

(define-function generic (name default)
  (let ((self (new <generic>)))
    (set (<generic>-name    self) name)
    (set (<generic>-methods self) (array))
    (set (<generic>-default self) default)
    self))

(define-print-method <generic>
  (print-all -stream- "<multimethod:"self.name">"))

(define-form define-generic (name . default)
  (or default (set default `(args (error "no method in generic "',name" corresponding to: "args", of types: " (map type-of args)))))
  `(define ,name (generic ',name (lambda ,@default))))

;; we store the no-dispatch case at index 0
(define-constant +multimethod-type-id-offset+ 1)

(define-function %add-multimethod (mm types method)
  (when-at-expand (and feature/track-expr-names
                       (not bootstrapping?))
    ;; expr's (lambdas) are instantiated by the host, so let's not assume anything about their object layout.
    (or (<expr>-name method) (set (<expr>-name method) (<generic>-name mm))))
  (if types
      (let ((methods (or (<generic>-methods mm)
                         (set (<generic>-methods mm) (array 32)))))
        (while (cdr types)
          (let* ((type	(awhen (car types)
                          (eval it)))
                 (index	(if type
                            (+ (<type>-id type) +multimethod-type-id-offset+)
                          ;; we store the no-dispatch case at index 0
                          0)))
            (set methods (or (array-at methods index)
                             (set (array-at methods index) (array 32)))))
          (set types (cdr types)))
        ;; the last one:
        (set (array-at methods (aif (car types)
                                   (+ (<type>-id (eval it))
                                      +multimethod-type-id-offset+)
                                 0))
             method))
    (set (<generic>-methods mm) method)))

(define-form define-multimethod (method typed-args . body)
  (let ((args  (map (lambda (x) (if (pair? x) (second x) x))	typed-args))
        (types (map (lambda (x) (when (pair? x) (first x)))	typed-args)))
    (or (defined? method) (eval (list 'define-generic method)))
    `(%add-multimethod ,method (list ,@types) (lambda ,args ,@body))))

(define %generic-lookup/inheritance) ; forward

(define-function %generic-lookup (method arg)
  (if (and arg (array? method))
      (or (%generic-lookup (array-at method (+ +multimethod-type-id-offset+ (type-id-of (car arg))))
                           (cdr arg))
          ;; if failed then also try the inheritance chain upwards
          (%generic-lookup/inheritance (type-of (car arg)) method arg)
          ;; when all else failed, try the no-dispatch path
          (%generic-lookup (array-at method 0)
                           (cdr arg)))
    method))

(define-function %generic-lookup/inheritance (type method arg)
  (awhen (and type
              (is <record> type)
              (<record>-super type))
    (or (%generic-lookup (array-at method (+ +multimethod-type-id-offset+ (<type>-id it)))
                         (cdr arg))
        (%generic-lookup/inheritance it method arg))))

(define-apply <generic> (self . arguments)
  (let ((method (%generic-lookup (<generic>-methods self) arguments)))
    (if (and method (not (array? method)))
        (apply method arguments)
      (let ((default (<generic>-default self)))
        (if default
            (apply default arguments)
          (error "no method in "(<generic>-name self)" corresponding to "arguments))))))
