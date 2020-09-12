;;; -*- mode: lisp; coding: us-ascii -*-

(define *tests* ())

(define-form define-test (name args . body)
  (push *tests* name)
  `(define-function ,name ,args
     ,@body))

(define-form test-assert (condition . printing)
  `(let ((__cond__ ,condition))
     (unless __cond__
       (println "\n\n\033[1;31m*** FAILURE\033[0m form: " ',condition " " ,@printing))))

(define-form run-tests ()
  (let ((tests *tests*)
        (test)
        (forms ()))
    (while (set test (first tests))
      (push forms `(,test))
      (set tests (rest tests)))
    `(let ()
       ,@forms)))

;;;
;;; Tests
;;;
(define-test maru/arithmetic/- ()
  (test-assert (= -42 (- 42)))
  (test-assert (= 0   (- 2 2)))
  (test-assert (= -3  (- 2 2 3))))

(define-test maru/arithmetic/+ ()
  (test-assert (= 0 (+)))
  (test-assert (= 42 (+ 42)))
  (test-assert (= 42 (+ 40 2)))
  (test-assert (= 42 (+ 20 21 1))))

(define-test maru/arithmetic// ()
  (test-assert (= 1   (/ 1)))
  (test-assert (= 100 (/ 1000 10)))
  (test-assert (= 5   (/ 1000 20 10))))

(define-test maru/arithmetic/* ()
  (test-assert (= 1   (*)))
  (test-assert (= 42  (* 42)))
  (test-assert (= 24  (* 1 2 3 4))))

(define-test maru/string/insert ()
  (let ((x "alma"))
    (string-insert x 2 ?z)
    (test-assert (= x "alzma"))
    (string-insert x 5 ?x)
    (test-assert (= x "alzmax"))))

(define-test maru/array/insert ()
  (let ((x (list->array '(1 2 3 4))))
    (array-insert x 2 42)
    (test-assert (equal (array->list x) '(1 2 42 3 4)))
    (array-insert x 5 43)
    (test-assert (equal (array->list x) '(1 2 42 3 4 43)))))

(define-function maru/let/1/helper (env)
  (let ((env env))
    (set env 42))
  env)

(define-test maru/let/1 ()
  (test-assert (= 9979 (maru/let/1/helper 9979))))

(define-form %_eval-at-expand-time body
  (eval `(let ()
           ,@body)))

(define *a-global-visible-at-expand-time* 1)

(define-test maru/bug/eval-at-expand-time ()
  (%_eval-at-expand-time
   (if *a-global-visible-at-expand-time*
       (define-form maru/bug/at-expand-time/true ()
         43)
     (define-function maru/bug/at-expand-time/false ()
       42)))
  (test-assert (= 43 (maru/bug/at-expand-time/true)))
  (test-assert (= () maru/bug/at-expand-time/false)))

(define-test maru/if-at-expand/1 ()
  (let ((x 999)
        (< (lambda args (error "this should not be visible inside if-at-expand at expand time"))))
    (if-at-expand (< 5 4)
        (this form should be dropped as if it wasnt even here)
      (incr x))
    (test-assert (= x 1000))))

(define-function run-tests ()
  (println "\nAbout to run the interpreter tests.")
  (let ((tests *tests*)
        (test))
    (while (set test (pop tests))
      (print test ", ")
      (eval `(,test)))
    (println "\nFinished running the interpreter tests.")))

(run-tests)
