;;; -*- mode: lisp; coding: us-ascii -*-

(warn "--- boostrapping: late\n")

(define-form define-externs args ()) ; expand to nothing

(switch-to-host-module)

(warn "--- boostrapping: emit.l\n")
