;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

(eval-in-module slave '(slave:define slave:bootstrapping? (slave:quote slave:t)))

(define-structure <variable>	(name value env index type))		(define-function variable? (obj) (= <variable> (type-of obj)))
(define-structure <env>		(parent level offset bindings stable))
(define-structure <context>	(home env bindings callee pc))
