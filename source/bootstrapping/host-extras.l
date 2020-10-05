;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

;; Mark the fact that we are evolving from the previous stage.
(eval-in-slave '(set evolving? true))

;;;
;;; Temporary definitions that are needed to enable our host to bootstrap us.
;;;

;; in the new module setup, where all modules share the identity-same maru primitives,
;; we now need a new eval-encoded that only calls k/eval (as opposed to k/expand-encode-eval
;; that expects a sexp). it would have always been the correct way, but the old setup was
;; permissive enough for the bootstrap to work.
(define eval-encoded eval)
