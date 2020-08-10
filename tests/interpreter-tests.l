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
(define-function maru/let/1/helper (env)
  (let ((env env))
    (set env 42))
  env)

(define-test maru/let/1 ()
  (test-assert (= 9979 (maru/let/1/helper 9979))))

(define-function run-tests ()
  (println "\nAbout to run the interpreter tests.")
  (let ((tests *tests*)
        (test))
    (while (set test (pop tests))
      (print test ", ")
      (eval `(,test)))
    (println "\nFinished running the interpreter tests.")))

(run-tests)
