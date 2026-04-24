;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the host env while evolving from the previous evolutionary
;;; stage.
;;;

;; Mark the fact that we are evolving from the previous stage.
(set evolving? true)
(eval-in-slave '(set evolving? true))

;;;
;;; Temporary definitions that are needed to enable our host to bootstrap us.
;;;

;; Make sure that the profiler is not compiled in when evolving. This
;; may only be necessary for maru.9 -> maru.10 because the profiler
;; seems to be broken in maru.9, and the --define interface is not
;; compatible (maru.9 lacks the true/false recognition). (evolving)
(define feature/profiler/build false)
