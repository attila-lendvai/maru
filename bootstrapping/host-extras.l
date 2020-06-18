;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

(eval-in-module slave '(slave:define slave:bootstrapping? (slave:quote slave:t)))

;; this is an approximation of how to bootstrap the subr defined?, but i couldn't
;; make it work trying for hours... while adding it to the previous stage was
;; a couple of minutes. so, i decided to stop trying and add it to the previouss stage...
;;
;; (eval-in-module slave
;;   `(slave:define slave:defined?
;;        (slave:lambda (name)
;;          ;; this will be a subr in our stage, but until then we need a substitute.
;;          ;; we need it in the slave module, for our boot.l
;;          (slave:eval-in-module slave:host `(and (assq ',name (<module>-env (current-module)))
;;                                                 'slave:t)))))

(define-structure <variable>	(name value env index type))		(define-function variable? (obj) (= <variable> (type-of obj)))
(define-structure <env>		(parent level offset bindings stable))
(define-structure <context>	(home env bindings callee pc))
