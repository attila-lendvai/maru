;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave in the first iteration of the bootstrap, when we are
;;; building using the executable of the previous stage.
;;;

(warn "--- boostrapping: slave extras\n")

(define bitwise-and	&)
(define bitwise-or	|)
(define bitwise-xor	^)
(define bitwise-asl	<<)
(define bitwise-asr	>>)

;; this one is new in this stage, so let's give it a simple implementation that can be executed in the meta-level code.
;; when used in compiled code, it will be recognized by the compiler.
(define-function bitwise-not (value)
  (^ value -1))

;; we are introducing these two in this stage
(define byte-at		string-at)
(define set-byte-at	set-string-at)
