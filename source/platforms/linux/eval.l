;;; -*- mode: lisp; coding: us-ascii -*-

(load "source/evaluator/vm-early.l")
(load "source/debug-min.l")
(load "source/evaluator/vm.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")
(load "source/evaluator/eval.l")

(define-function %syscall-rc-assert (syscall-number rc)
  (or (<= 0 rc) (error "syscall*: "(box <long> syscall-number)" returned with: "(box <long> rc)"\n"))
  rc)

(load "source/platforms/linux/vm-functions.l")
(load "source/platforms/linux/streams.l")
(load "source/evaluator/vm-with-file-support.l")

(define-function main (argc argv)
  (debug (platform/diag-print "linux main is alive\n"))
  (main/common argc argv
               linux/STDIN_FILENO linux/STDOUT_FILENO linux/STDERR_FILENO
               (lambda ()
                 (environment-define *maru*
                                     (string->symbol "feature/platform/linux")
                                     symbol/true)
                 (environment-define *maru*
                                     (string->symbol "feature/platform/posix")
                                     symbol/true))))

(load "source/evaluator/vm-late.l")
