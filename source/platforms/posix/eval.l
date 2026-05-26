;;; -*- mode: lisp; coding: us-ascii -*-

(load "source/platforms/libc/eval.l")

;; replace libc's main to define both features
(define-function main (argc argv)
  (main/common argc argv
               libc/stdin libc/stdout libc/stderr
               (lambda ()
                 (environment-define *maru*
                                     (string->symbol "feature/platform/libc")
                                     symbol/true)
                 (environment-define *maru*
                                     (string->symbol "feature/platform/posix")
                                     symbol/true))))
