;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO this is a copy-paste from evaluator-tests.l
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

(define *test-module-1* (create-module "test-module-1"))
(define *test-module-2* (create-module "test-module-2"))

(eval-in-module *test-module-1* `(define *test-module-2* ,*test-module-2*))
(eval-in-module *test-module-2* `(define *test-module-1* ,*test-module-1*))

;;;
;;; Tests
;;;
(define-test modules/1 ()
  (eval-in-module *test-module-1* '(define fn-in-1 (lambda ()
                                                     40)))
  (eval-in-module *test-module-2* '(define fn-in-2 (lambda ()
                                                     (+ 2 (eval-in-module *test-module-1*
                                                            '(fn-in-1))))))
  (test-assert (= 42 (eval-in-module *test-module-2* '(fn-in-2)))))

(define-test modules/2 ()
  (eval-in-module *test-module-1* '(let ()
                                    (define *global-in-1* -1)
                                    (define fn-in-1 (lambda (x)
                                                      (+ x *global-in-1*)))))
  (test-assert (= 42 (eval-in-module *test-module-2* '(eval-in-module *test-module-1*
                                                       '(let ()
                                                         (set *global-in-1* 2)
                                                         (fn-in-1 40))))))
  ;; evaluate fn-in-1 with *test-module-2* as current-module.
  (test-assert (= 52 (eval-in-module *test-module-2* '((eval-in-module *test-module-1*
                                                         '(let ()
                                                           (set *global-in-1* 10)
                                                           fn-in-1))
                                                       42))))
  (test-assert (= 53 (eval-in-module *test-module-2* '((eval-in-module *test-module-1*
                                                         '(let ()
                                                           ;; TODO should define silently just set, or actually redefine? should it warn?
                                                           (define *global-in-1* 10)
                                                           fn-in-1))
                                                       43)))))

(define-function run-tests ()
  (println "\nAbout to run the module tests.")
  (let ((tests *tests*)
        (test))
    (while (set test (pop tests))
      (print test ", ")
      (eval `(,test)))
    (println "\nFinished running the module tests.")))

(run-tests)
