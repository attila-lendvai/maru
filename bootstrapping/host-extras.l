;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

;; The variable evolving? denotes that the host running the bootstrapping process is
;; the previous stage, i.e. not fully compatible with us.
(eval-in-module slave '(slave:define slave:evolving?      (slave:quote slave:t)))

;; in the level-shift compile (define foo) as (define foo 0). this is part of the
;; evolved emit.l, but not that of the previous stage.
(define-method gen-definition <undefined> (name comp)
  (gen-definition 0 name comp))

;; these are new variables and functions that are defined by the evolved eval.l
(eval-in-module slave '(slave:let ()
                        (slave:define slave:*command-line-arguments* ())
                        (slave:define slave:*verbosity* 0)
                        (slave:define slave:*optimised* 0)
                        (slave:define slave:read)
                        (slave:define slave:libc/fopen)
                        (slave:define slave:libc/fclose)
                        (slave:define slave:libc/fgetc)
                        (slave:define slave:libc/fputc)
                        (slave:define slave:libc/format)))
