;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave module while evolving from the previous stage.
;;;

(eval-in-host
 `(when-at-expand (feature debug-info)
    (assert (= "slave" (<env>-name ,*globals*)))))

(define-function repl-stream _
  ;; just a stub
  )

;; just some dummies to accommodate for the bootstrap
(define-function cell-at (obj idx)
  (error "dummy cell-at called"))

(define-function set-cell-at (obj idx value)
  (error "dummy set-cell-at called"))
