;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Common defs for all platforms.

;; 420 is "rw-r--r--"
(define-constant posix/default-umask 420)

(define-form align-address-up (var page-size)
  `(bitwise-and (+ ,var (- ,page-size 1))
                (- ,page-size)))

(define-form align-address-down (var page-size)
  `(bitwise-and ,var (- ,page-size)))

(define-form platform/diag-print forms
  ;; print arguments as diagnotic output. argument expressions can be
  ;; wrapped into STRING, POINTER, LONG, which is the default when omitted.
  ;; e.g.: (platform/diag-print "literal" (string form2) (pointer form3)
  ;; (long form4) form5 ...).
  `(let ()
     ,@(map (lambda (form)
              (cond
                ;; maybe, eventually, evaluate DEFINE-CONSTANTs...
                ;; ((and (symbol? form)
                ;;       (defined? form *env*)
                ;;       (is <form> (global-variable-value *env* form)))
                ;;  `(platform/diag-print-string ,(eval form *env*) 10 platform/diag-print-char))
                ((string? form)
                 `(platform/diag-print-string ,form))
                ((and (pair? form)
                      (= 'string (first form)))
                 `(platform/diag-print-string ,(second form)))
                ((and (pair? form)
                      (= 'pointer (first form)))
                 `(let ()
                    (platform/diag-print-string "0x")
                    ;; TODO properly deal with negative numbers
                    (long->string/emit ,(second form) 16 platform/diag-print-char)))
                ((and (pair? form)
                      (= 'long (first form)))
                 `(long->string/emit ,(second form) 10 platform/diag-print-char))
                (else
                 `(long->string/emit ,form 10 platform/diag-print-char))))
            forms)))
