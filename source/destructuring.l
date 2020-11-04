;;; -*- mode: lisp; coding: us-ascii -*-

;;; let* with destructuring

(define-function %let*getters (vars getter rest)
  (if (pair? vars)
      (cons (list (car vars) (list 'car getter))
            (%let*getters (cdr vars) (list 'cdr getter) rest))
    (if (symbol? vars)
        (cons (list vars getter) rest)
      rest)))

(define-function %let*unpack (vars val rest)
    (cons (cons '_%let_values_ val)
          (%let*getters vars '_%let_values_ rest)))

(define-function %let*bindings (bindings)
  (when (pair? bindings)
    (let ((entry (first bindings)))
      (unless (pair? entry)
        (set entry (list entry)))
      (let ((var-name	(first entry))
            (value	(rest entry)))
        (if (pair? var-name)
            (%let*unpack var-name value (%let*bindings (cdr bindings)))
          (cons (cons var-name value)
                (%let*bindings (cdr bindings))))))))

(define-function %let* (bindings body)
  (if (pair? (cdr bindings))
      `(let (,(car bindings)) ,(%let* (cdr bindings) body))
    `(let ,bindings ,@body)))

(define-form let* bindings-body
  (%let* (%let*bindings (car bindings-body)) (cdr bindings-body)))
