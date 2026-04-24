;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Common defs needed by all C based platforms.

(require "source/platforms/platform-common.l")

;; A simple toplevel REQUIRE would mean it's a call to require that
;; should be compiled to the target. What we need is the cgrov
;; definitions to be available in the slave to be used while loading
;; the code.
(eval-in-slave '(require "source/c/cgrov.l"))

;;;
;;; API visible in the target
;;;

;; NOTE C-string is a compiler special form to emit a constant c
;; string in the read-only data segment.

(define-form define-C-function (maru-name return-type foreign-name parameter-types)
  (let ((ff (eval-in-host `(C-function ',return-type ,(symbol->string foreign-name) ',parameter-types))))
    `(define ,maru-name ,ff)))

(define-form define-C-functions (prefixes . entries)
  (let ((maru-prefix	(first  (ensure-list prefixes)))
        (foreign-prefix	(second (ensure-list prefixes))))
    `(let ()
       ,@(map (lambda (entry)
                (let* ((return-type (first entry))
                       (base-name   (second entry))
                       (param-types (third entry))
                       (foreign-name (if foreign-prefix
                                         (concat-symbol foreign-prefix base-name)
                                       base-name))
                       (maru-name (if maru-prefix
                                      (concat-symbol maru-prefix base-name)
                                    base-name)))
                  `(define-C-function ,maru-name ,return-type ,foreign-name ,param-types)))
              entries))))

(define-form define-C-variable (maru-name foreign-name type . attributes)
  (let ((fv (eval-in-host `(C-variable ,(symbol->string foreign-name)
                                       ',type ,@attributes))))
    `(define ,maru-name ,fv)))

(define-form string->C-string (obj)
  ;; OPTIMIZATION: use the C-string compiler special form to emit cstrings when
  ;; literals are immediately passed to string->C-string. ideally it
  ;; should be done by some compiler macro like facility.
  (cond
    ((is <string> obj)
     `(C-string ,obj))
    ;; FIXME WTF is going on here? can't use (feature
    ;; emit-with-object-headers) directly, because it evaluates to
    ;; false. but how? only the slave env should have that variable
    ;; defined, and it's true while compiling eval.l
    ((eval '(feature emit-with-object-headers))
      `(%string->C-string ,obj))
    (else obj)))

;; NOTE libc.l may choose to replace this with libc/strlen
(define-function C-string-length (cstr)
  (let ((i 0))
    (while (char-at cstr i)
      (incr i))
    i))
