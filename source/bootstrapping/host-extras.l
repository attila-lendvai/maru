;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host module while evolving from the previous stage.
;;;

;; Mark the fact that we are evolving from the previous stage.
(set evolving? true)
(eval-in-slave '(set evolving? true))

;;;
;;; Temporary definitions that are needed to enable our host to bootstrap us.
;;;
(define-function current-globals ()
  (<module>-globals (current-module)))

(define-function set-current-globals (value)
  (set (<module>-globals (current-module)) value))
