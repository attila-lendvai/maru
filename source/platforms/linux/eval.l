;;; -*- mode: lisp; coding: us-ascii -*-

(load (concat-strings "source/emit-" *compiler-backend* ".l"))

(load (concat-strings "source/platforms/linux/syscall-" *compiler-backend* ".l"))

(switch-to-target-env)

(load "source/platforms/linux/linux.l")

(load "source/evaluator/vm-early.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")
(load "source/evaluator/eval.l")

(define-primitive-function set-working-directory ((path <string>))
  (verbosity 1 (print-all *debug-output* "changing working directory to: "path"\n"))
  (unless (= 0 (linux-syscall linux/chdir (string->C-string path)))
    (error "set-working-directory: linux/chdir failed for "path)))

(load "source/platforms/linux/streams.l")
(load "source/evaluator/vm-with-file-support.l")
(load "source/evaluator/vm-late.l")

;; https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;; http://www.dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html
;; https://0xax.gitbooks.io/linux-insides/content/Misc/linux-misc-4.html
;; https://stackoverflow.com/questions/50260855/how-get-arguments-value-using-inline-assembly-in-c-without-glibc
;; i386: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/i386/start.S;h=91035fa83fb7ee38a0ca5834ba1d215b4a7f78e8;hb=HEAD
;; x86_64: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/x86_64/start.S;h=354d2e6ec78f0eaf9ab0f8ed665c2e5499388df0;hb=HEAD
;; argc and argv position on the stack: https://briancallahan.net/blog/20200808.html
(define-function _start ()
  (let ((argc (oop-at (stack-pointer-on-entry) 0))
        (argv (+ (stack-pointer-on-entry)
                 (words-to-bytes 1))))

    (initialize-vm)
    (initialize-streams linux/stdin linux/stdout linux/stderr)

    (process-command-line-arguments argc argv)

    (debug-print "main is on the way out")

    (verbosity 1
      (gc/collect)
      (let ((out *error-output*))
        (print-all *error-output*
                   (box <long> gc/objects-live)" objects in "
                   (box <long> gc/bytes-used)" bytes, "
                   (box <long> gc/bytes-free)" bytes free\n")))
    (when-at-expand feature/profiler
      (profiler/disable))
    (platform/flush-streams)

    (debug-print "main is returning normally")
    (linux-syscall linux/exit 0)))
