;;; -*- mode: lisp; coding: us-ascii -*-

(define-form host-value (form)
  `(eval-in-host ',form))

(switch-to-host-module)
