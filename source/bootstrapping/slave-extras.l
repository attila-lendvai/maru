;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave in the first iteration of the bootstrap, when we are
;;; building using the executable of the previous stage.
;;;

(define bitwise-and	&)
(define bitwise-or	|)
(define bitwise-xor	^)

(define-function bitwise-shift (value shift)
  ;; we can't call << and >> here because the compiler redefines them with stubs.
  ;; a nice way to solve it would be to have a separate module for the meta-level of the slave
  ;; and then we would only define this for the object level. then it would work.
  ;; (cond
  ;;   ((< 0 shift)	(<< value shift))
  ;;   ((< shift 0)	(>> value (- shift)))
  ;;   (else		value))
  ;; something like that happens here, essentially, although managed by hand: we call the host module
  ;; to evaluate it for us. ideally form expansion should be evaluated in a different module.
  (eval-in-module host `(host:bitwise-shift ,value ,shift)))

;; this one is new in this stage, so let's give it a simple implementation that can be executed in the meta-level code.
;; when used in compiled code, it will be recognized by the compiler.
(define-function bitwise-not (value)
  (^ value -1))

;; we are introducing these two in this stage
(define byte-at		string-at)
(define set-byte-at	set-string-at)
