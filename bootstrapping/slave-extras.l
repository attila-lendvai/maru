;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave in the first iteration of the bootstrap, when we are
;;; building using the executable of the previous stage.
;;;

(warn "--- boostrapping: slave extras\n")

;; in the first iteration of the bootstrap we need to deal with the new
;; >= operator because the emit.l of the previous stage doesn't understand it yet.
;; it's a safe bet to install a macro that will turn any accidental use of it
;; into a runtime error.
(define-form >= args
  '(fatal "This is a bootstrapping dummy in place of the >= operator."))

;; let's shadow the new map function in boot.l, because it requires
;; set-car/set-cdr, and the previous stage doesn't have them yet.
(define-function map (function list)
  (if (pair? list)
      (let ((head (function (car list))))
        (cons head (map function (cdr list))))))
