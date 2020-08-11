;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

;; Mark the fact that we are evolving from the previous stage.
(eval-in-module slave '(slave:set slave:evolving? (slave:quote slave:t)))

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

(eval-in-module slave '(slave:let ()
                        (slave:define slave:environment        (slave:lambda args (slave:eval (slave:quote (slave:error "bootstrap stub called: environment\n"))) (slave:abort)))
                        (slave:define slave:environment-define (slave:lambda args (slave:eval (slave:quote (slave:error "bootstrap stub called: environment-define\n")))))))
