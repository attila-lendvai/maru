;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; This file contains any temporary extra definitions that are needed
;;; in the slave in the first iteration of the bootstrap, when we are
;;; building using the executable of the previous stage.
;;;

(warn "--- boostrapping: slave extras\n")

(define-constant libc/EOF -1)

(define-form define-foreign-functions/libc args ()) ; expand to nothing

;; these definitions have been moved into emit-early.l, so we need to
;; provide them when we are evolving from a previous stage.
(define-constant target-word-size/bits	32)
(define-constant target-word-size/bytes	(/ target-word-size/bits 8))

(define-form bytes-to-words (value)
  (if (long? value)
      (/  value  target-word-size/bytes)
     `(/ ,value ,target-word-size/bytes)))

(define-form words-to-bytes (value)
  (if (long? value)
      (* value   target-word-size/bytes)
     `(* ,value ,target-word-size/bytes)))

(define-constant target-boolean/true  1)
(define-constant target-boolean/false 0)

(define-function target-boolean (value)
  (if value target-boolean/true target-boolean/false))
