;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Common defs needed by all C based platforms.

(require "source/platforms/platform-common.l")

(define-form string->C-string (obj)
  ;; OPTIMIZATION: use a compiler special form to emit cstrings when
  ;; literals are immediately passed to string->C-string. ideally it
  ;; should be done by some compiler macro like facility.
  (if (is <string> obj)
      `(C-string ,obj)
    `(%string->C-string ,obj)))

;; NOTE libc.l may choose to replace this with libc/strlen
(define-function C-string-length (cstr)
  (let ((i 0))
    (while (char-at cstr i)
      (incr i))
    i))
