;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host env while evolving from the previous stage (i.e. when
;;; eval0 is hosting the bootstrap).
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

;; Make sure that the profiler is not compiled in when evolving. This
;; may only be necessary for maru.9 -> maru.10 because the profiler
;; seems to be broken in maru.9.
(define-constant feature/profiler false)

(define-function print-list (lst . etc)
  (let ((separator (or (pop etc) " "))
        (stream    (or (pop etc) *standard-output*)))
    ;; PUNT: we ignore the supplied separator
    (%print-list stream lst false)))
