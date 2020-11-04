;;; -*- mode: lisp; coding: us-ascii -*-

;; this is very similar in effect to read-time evaluation in CL, aka #.(foo)
(define-form eval-at-expand (form)
  (eval form))

(define-form if-at-expand (cond true-form . false-forms)
  (if (eval cond)
      true-form
    (if (and false-forms
             (cdr false-forms))
        `(let () ,@false-forms)
      (car false-forms))))

(define-form when-at-expand (cond . true-forms)
  (if (eval cond)
      (if (and true-forms
               (cdr true-forms))
          `(let ()
             ,@true-forms)
        (car true-forms))))

(define-form when (test . body)
  `(if ,test (let () ,@body)))

(define-form unless (test . body)
  `(if ,test () ,@body))

(define-form awhen (test . body)
  `(let (it)
     ;; this allows SETting IT from inside TEST
     (when (set it ,test)
       ,@body)))

(define-form aif (test true-form . false-forms)
  `(let (it)
     (set it ,test)
     (if it
         ,true-form
       ,@false-forms)))

;;; cond

(define-function %maybe-progn (prog)
  (if (cdr prog)
      (cons 'let (cons '() prog))
    (car prog)))

(define-function %cond (clauses)
  (if (pair? clauses)
      (let* ((clause (car clauses))
             (test   (car clause))
             (body   (cdr clause)))
        (if (= 'else test)
            (%maybe-progn body)
          (if (= '=> (car body)) ; scheme syntax to funcall the body
              `(let ((_ ,test))
                 (if _
                     (,(%maybe-progn (cdr body)) _)
                   ,(%cond (cdr clauses))))
            `(if ,test
                 ,(%maybe-progn body)
               ,(%cond (cdr clauses))))))))

(define-form cond clauses (%cond clauses))

;;; case

(define self-evaluating-value?) ; forward

(define-function %case-test (values)
  (if (pair? values)
      (let ((value (car values)))
        (unless (self-evaluating-value? value)
          (set value `(quote ,value)))
        (cons `(= __value__ ,value)
              (%case-test (cdr values))))))

(define-function %case (clauses)
  (if (pair? clauses)
      (let* ((clause (car clauses))
             (value  (car clause))
             (body   (cdr clause)))
        (if (= 'else value)
            (%maybe-progn body)
          `(if (or ,@(%case-test (if (pair? value) value (list value))))
               ,(%maybe-progn body)
             ,(%case (cdr clauses)))))))

(define-form case (value . clauses)
  `(let ((__value__ ,value))
     ,(%case clauses)))
