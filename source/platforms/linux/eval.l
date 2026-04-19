;;; -*- mode: lisp; coding: us-ascii -*-

(load "source/evaluator/vm-early.l")
(load "source/debug-min.l")
(load "source/evaluator/vm.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")
(load "source/evaluator/eval.l")

(define-vm-function set-working-directory ((path <string>))
  (verbosity 1 (print-all *debug-output* "changing working directory to: "path"\n"))
  (unless (= 0 (linux-syscall linux/SYS_chdir (string->C-string path)))
    (error "set-working-directory: linux/SYS_chdir failed for "path)))

(load "source/platforms/linux/streams.l")
(load "source/platforms/linux/vm-functions.l")
(load "source/evaluator/vm-with-file-support.l")

(define-function main (argc argv)
  (debug (platform/diag-print "linux main is alive\n"))
  (main/common argc argv
               linux/STDIN_FILENO linux/STDOUT_FILENO linux/STDERR_FILENO
               (lambda ()
                 (environment-define *maru*
                                     (string->symbol "feature/platform/linux")
                                     symbol/true))))

(load "source/evaluator/vm-late.l")
