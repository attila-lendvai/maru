;;; -*- mode: lisp; coding: us-ascii -*-

;; this whole file is just a load-order KLUDGE waiting to be cleaned up...

(load "source/evaluator/vm-late.l")

(eval-in-host
 '(case *compiler-backend*
   (("i686" "x86-64")
    (load "source/compiler/emit-x86-objects.l"))))

(eval-in-host `(run-compiler ,*target-env*))
