;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host for bootstrapping.
;;;

;; Mark the fact that we are evolving from the previous stage.
(set evolving? true)
(eval-in-slave '(set evolving? true))

;;;
;;; Temporary definitions that are needed to enable our host to bootstrap us.
;;;
