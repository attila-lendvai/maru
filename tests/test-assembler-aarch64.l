;;; -*- mode: lisp; coding: us-ascii -*-

;;; Tests for the aarch64 assembler instruction emitters.
;;; TODO: requires arm-instructions.l to be evaluator-compatible

;; (require "source/assembler/arm-instructions.l")

;; TODO: add aarch64 instruction tests once arm-instructions.l loads in evaluator

(define *tests* ())

(define-form define-test (name args . body)
  (push *tests* name)
  `(define-function ,name ,args ,@body))

(define-form test-assert (condition . printing)
  `(unless ,condition
     (println "\n\n*** FAILURE form: " ',condition " " ,@printing)
     (println)))

(define-function run-tests ()
  (println "\nAbout to run the tests.")
  (let ((tests *tests*)
        (test))
    (while (set test (pop tests))
      (print test ", ")
      (eval `(,test)))
    (println "\nFinished running the tests.")))

(define-test aarch64-placeholder ()
  (println "aarch64 assembler tests coming soon"))

(run-tests)
