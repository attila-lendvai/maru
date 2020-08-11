;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

(warn "--- boostrapping: host extras\n")

;; Mark the fact that we are evolving from the previous stage.
(eval-in-module slave '(slave:set slave:evolving? (slave:quote slave:t)))
