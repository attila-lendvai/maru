;;; -*- mode: lisp; coding: us-ascii -*-

(load "source/evaluator/vm-early.l")
(load "source/debug-min.l")
(load "source/evaluator/vm.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")
(load "source/evaluator/eval.l")

;; TODO possible #optimization: even in the current setup, libc.l can override number->string with its own.
;; (define-function long->string (num radix)
;;   ;; TODO introduce alloca?
;;   ;; TODO handle radix
;;   (let ((buf (allocate-data 32)))       ; safe up until 64 bits
;;     (libc/sprintf buf "%ld" num)
;;     (C-string->string buf)))

;; TODO possible #optimization
;; (define-function string->long (str radix)
;;   ;; TODO handle radix
;;   (let* ((cstr		(string->C-string str))
;;          (endptr	cstr)
;;          (result	(libc/strtol cstr (address-of endptr) 10)))
;;     (if (= (char-at endptr 0) ?\x00)
;;         (box <long> result)
;;       (error "invalid number in string->long, libc/strtol has failed for string " str))))

(load "source/platforms/libc/streams.l")
;; use target/platform so that we can override it from posix
(load (host-value (concat-strings "source/platforms/"target/platform"/vm-functions.l")))
(load "source/evaluator/vm-with-file-support.l")

(define-function main (argc argv)
  (main/common argc argv
               libc/stdin libc/stdout libc/stderr
               (lambda ()
                 (environment-define *maru*
                                     (string->symbol "feature/platform/libc")
                                     symbol/true))))

(load "source/evaluator/vm-late.l")
