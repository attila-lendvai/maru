;;; -*- mode: lisp; coding: us-ascii -*-

(switch-to-slave-env)

;; TODO? this should be done for all the needed features
(define feature/profiler/build (eval-in-host 'feature/profiler/build))
