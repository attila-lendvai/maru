;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave module while evolving from the previous stage.
;;;

(define-function current-globals ()
  ;; KLUDGE the <module>-globals accessor in the host
  (oop-at (current-module) 0))

(define-function set-current-globals (value)
  ;; KLUDGE the <module>-globals accessor in the host
  (set (oop-at (current-module) 0) value))

(eval-in-host
 `(when-at-expand feature/debug-info
    (assert (= "slave" (<env>-name ,*globals*)))))
