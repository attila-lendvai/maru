;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

;; The variable evolving? denotes that the host running the bootstrapping process is
;; the previous stage, i.e. not fully compatible with us.
(eval-in-module slave '(slave:define slave:evolving?      (slave:quote slave:t)))
