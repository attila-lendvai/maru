;;; -*- mode: lisp; coding: us-ascii -*-

(define-function eval-in-host (form)
  (eval-in-module host form))

(define-form host-value (form)
  `(eval-in-host ',form))

(switch-to-host-module)
