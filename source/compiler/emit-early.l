;;; -*- mode: lisp; coding: us-ascii -*-

;;; Naming:
;;;   - EMIT: emit instructions into the output stream
;;;   - COMPILE: something more involved than a simple emit
;;;   - -foo- is an implicit var in the lexenv
;;;   - +foo+ is a constant
;;;   - *foo* is a global
;;;
;;; See *special-operators* and *special-forms* for the list of
;;; specially handled constructs

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

;;;
;;; Utils
;;;

;; TODO this is naive, should also deal with varargs explicitly instead of just returning nil
(define-function expr-n-required-parameters (op)
  (let ((params		(<expr>-parameters op))
        (n-params	()))
    (cond
      ((not params))                   ; (lambda () ...)
      ((symbol? params))               ; (lambda args ...)
      ((pair? params)
       (set n-params 1)
       (while (pair? (set params (rest params)))
         (incr n-params))
       (when (symbol? params)          ; (lambda (arg1 . rest) ...)
         (set n-params ())))
      (else
       (error "expr-n-required-parameters: error parsing <expr> " op ", parameters " params)))
    n-params))
