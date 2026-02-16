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
