;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Common defs needed by all C based platforms.

(require "source/platforms/platform-common.l")

;;;
;;; API visible in the target
;;;
(define-form define-C-function (maru-name return-type foreign-name parameter-types)
  (let ((ff (eval-in-host `(C-function ',return-type ,(symbol->string foreign-name) ',parameter-types))))
    `(define ,maru-name ,ff)))

(define-form define-C-functions (maru-prefix . entries)
  `(let ()
     ,@(map (lambda (entry)
              (let* ((foreign-name (second entry))
                     (maru-name (if maru-prefix
                                    (concat-symbol maru-prefix foreign-name)
                                  foreign-name)))
                `(define-C-function ,maru-name ,@entry)))
            entries)))

(define-form define-C-variable (maru-name foreign-name type)
  (let ((fv (eval-in-host `(C-variable ,(symbol->string foreign-name) ',type))))
    `(define ,maru-name ,fv)))

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
