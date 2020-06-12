;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave when using the previous stage for bootstrapping.
;;;

(warn "--- boostrapping: slave extras\n")

;; in the first iteration of the bootstrap we need to deal with the new
;; >= operator because the emit.l of the previous stage doesn't understand it yet.
;; it's a safe bet to install a macro that will turn any accidental use of it
;; into a runtime error.
(define-form >= args
  '(fatal "This is a bootstrapping dummy in place of the >= operator."))
