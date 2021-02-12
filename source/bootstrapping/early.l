;;; -*- mode: lisp; coding: us-ascii -*-

(switch-to-slave-module)

;; these create only copies. we could/should add some form of
;; references to the same <variable> instances, but that kinda
;; stinks...
(define *standard-input*  (if (not evolving?) (eval-in-host '*standard-input*)))
(define *standard-output* (if (not evolving?) (eval-in-host '*standard-output*)))
(define *error-output*    (if (not evolving?) (eval-in-host '*error-output*)))
(define *debug-output*    (if (not evolving?) (eval-in-host '*debug-output*)))
(define *verbosity*       (eval-in-host '*verbosity*))
(define *optimised*       (eval-in-host '*optimised*))
