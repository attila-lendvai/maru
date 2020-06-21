;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

(eval-in-module slave '(slave:define slave:bootstrapping? (slave:quote slave:t)))

(define-method gen-definition <undefined> (name comp)
  (gen-definition 0 name comp))
