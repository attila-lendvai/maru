;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave when using the previous stage for bootstrapping.
;;;

(warn "--- boostrapping: slave extras\n")

;; in the first iteration of the bootstrap we need to deal with the new
;; >= operator because the previous stage's emit.l doesn't understand it yet.
;; it's a safe bet to turn any accidental use into a runtime error.
(define-form >= args
  '(fatal "This is a bootstrapping dummy instead of the >= operator."))
