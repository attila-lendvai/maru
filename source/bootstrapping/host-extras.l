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
(define-function current-globals ()
  (<module>-globals (current-module)))

(define-function set-current-globals (value)
  (set (<module>-globals (current-module)) value))

;; slave-extras.l is too late for these
(eval-in-slave
 '(let ()
   (define current-globals
     (lambda ()
       ;; KLUDGE the <module>-globals accessor in the host
       (oop-at (current-module) 0)))

   (define set-current-globals
     (lambda (value)
       ;; KLUDGE the <module>-globals accessor in the host
       (set (oop-at (current-module) 0) value)))))

;; Make sure that the profiler is not compiled in when evolving. This
;; may only be necessary for maru.9 -> maru.10 because the profiler
;; seems to be broken in maru.9, and the --define interface is not
;; compatible (maru.9 lacks the true/false recognition). (evolving)
(define feature/profiler/build false)

(define-form begin body
  `(let ()
     ,@body))

(define-function print-list (lst . etc)
  (let ((separator (or (pop etc) " "))
        (stream    (or (pop etc) *standard-output*)))
    ;; PUNT: we ignore the supplied separator
    (%print-list stream lst false)))

(define-function lower-cell->long (value)
  (error "lower-cell->long stub called"))

(define-function long->lower-cell (value)
  (error "long->lower-cell stub called"))

;; slave-extras.l is too late
(eval-in-slave
 '(let ()
   (define lower-cell->long
    (lambda (value)
      (warn "lower-cell->long stub called")
      (exit -1)))

   (define long->lower-cell
    (lambda (value)
      (warn "long->lower-cell stub called")
      (exit -1)))))
