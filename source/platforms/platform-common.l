;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Common defs for all platforms.

(define-form align-address-up (var page-size)
  `(bitwise-and (+ ,var (- ,page-size 1))
                (- ,page-size)))

(define-form align-address-down (var page-size)
  `(bitwise-and ,var (- ,page-size)))

(define-form platform/diag-print forms
  ;; full syntax: (platform/diag-print "literal" (string form2) (pointer
  ;; form3) (long form4) ...), but it defaults to long, and it
  ;; recognizes string literals.
  `(let ()
     ,@(map (lambda (form)
              (cond
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
