;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

;; Mark the fact that we are evolving from the previous stage.
(eval-in-module slave '(slave:set slave:evolving? (slave:quote slave:true)))

;;;
;;; Temporary definitions that are needed to enable our host to bootstrap us.
;;;
(eval-in-module slave '(slave:define slave:true (slave:quote slave:true)))
(define true 'true)

;; we have changed the layout of <expr> to contain the parsed elements of what used to be a list in the defn slot.
;; we need to provide the new API/accessors when the previous stage is running our compiler and passing it <expr>'s
;; that are instantiated with the old layout.
(define-function <expr>-parameters (obj)
  (second (<expr>-defn obj)))

(define-function <expr>-body (obj)
  (cddr (<expr>-defn obj)))

;; only some of these are used in the compiler, or the meta-level code (that runs in the host)
(define bitwise-and	&)
;;(define bitwise-or	|)
;;(define bitwise-xor	^)
(define bitwise-asl	<<)
(define bitwise-asr	>>)
