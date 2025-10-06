;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")
(require "source/streams.l")

(define *tests* ())

(define-form define-test (name args . body)
  (push *tests* name)
  `(define-function ,name ,args
     ,@body))

(define-form test-assert (condition . printing)
  `(unless ,condition
     (println "\n\n\033[1;31m*** FAILURE\033[0m form: " ',condition " " ,@printing)
     (println)))

(define-function run-tests ()
  (println "\nAbout to run the tests.")
  (let ((tests *tests*)
        (test))
    (while (set test (pop tests))
      (print test ", ")
      (eval `(,test)))
    (println "\nFinished running the tests.")))
