;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/conversion.l")
(require "source/c/cffi.l")

(define-function string->type-name (str) (string->symbol (concat-string "<" (concat-string str ">"))))
(define-function symbol->type-name (sym) (string->type-name (symbol->string sym)))

(define-constant +maru-label-prefix+ "m_")

;; FIXME only works at 1 and below. comments need to be escaped:
;; there's only single-line comment syntax in llvm and gas. escape
;; newlines and the comment syntax chars.
(define *compiler-verbosity* 0)

;; this is faster than (emit COMMENT ...) by skipping the evaluation early
(define-form emit-comment (level . args)
  `(when (<= ,level *compiler-verbosity*)
     (emit COMMENT (list ,@args))))

(define-function features->print-forms (names)
  (let ((elements ())
        (first-time true))
    (map (lambda (name)
           (if first-time
               (set first-time false)
             (push elements ", "))
           (push elements (symbol->string name))
           (push elements "=")
           (push elements `(feature ,name)))
         names)
    (list-reverse! elements)))

(define-form comment-features ()
  `(emit-comment 0 "features: "
                 ,@(features->print-forms
                    '(emit-with-object-headers
                      redefinable-functions-in-target
                      strict-semantics-for-compiled-set
                      profiler
                      track-expr-names
                      object-canary
                      debug-info))))
