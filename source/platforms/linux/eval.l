;;; -*- mode: lisp; coding: us-ascii -*-

(define *standard-input*)
(define *standard-output*)
(define *standard-error*)
(define *debug-output*)

(require "source/platforms/linux/linux.l")

(load "source/evaluator/vm-early.l")

;;;
;;; garbage collector
;;; ----------------------------------------------------------------

(load "source/evaluator/gc.l")

(define-function allocate (type slot-count)
  (gc/allocate type (words-to-bytes slot-count)))

(load "source/evaluator/eval.l")
(load "source/platforms/linux/streams.l")

;; TODO eventually we could do something like this... note that this would access the current module!
;; NOTE binding this into the interpreter's env is only useful/meaningful if its LIBC-STREAM type is also
;; properly initialized in the interpreter's env. otherwise it would be there an object of an unknown type.
;; TODO add compilation of symbols and drop the string->symbol call
;; (define-symbol-form *standard-input*  (global-variable-value (u/string->symbol "*standard-input*")))
;; (define-symbol-form *standard-output* (global-variable-value (u/string->symbol "*standard-output*")))
;; (define-symbol-form *standard-error*  (global-variable-value (u/string->symbol "*standard-error*")))

(define-function initialize-streams ()
  (gc/let* (tmp)
    (with-forms ((doit ((fd our-name)
                        `(let ()
                           (set tmp (file-stream (box <target-vm-pointer> ,fd)))
                           (set ,our-name tmp)
                           ;; TODO add support for compiling symbols
                           (set (global-variable-value (u/string->symbol ,(symbol->string our-name))) tmp)))))
      (doit linux/stdin  *standard-input*)
      (doit linux/stdout *standard-output*)
      (doit linux/stderr *standard-error*)
      (set *debug-output* *standard-error*))))

(load "source/evaluator/vm-with-file-support.l")
(load "source/evaluator/vm-late.l")

(define-function main (argc argv)
  (initialize-vm)
  (initialize-streams)

  (process-command-line-arguments argc argv)

  (debug-print "main is on the way out")

  (verbosity 1
    (gc/collect)
    (let ((out *standard-error*))
      (do-print out (box <long> gc/objects-live) false)
      (do-print out (string-from-cstring " objects in ") false)
      (do-print out (box <long> gc/bytes-used) false)
      (do-print out (string-from-cstring "  bytes,  ") false)
      (do-print out (box <long> gc/bytes-free) false)
      (do-print out (string-from-cstring " bytes free\n") false)))
  (when-at-expand feature/profiler
    (profiler/disable))
  (platform/flush-streams)

  (debug-print "main is returning normally")
  0)

;; http://www.dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html
;; https://0xax.gitbooks.io/linux-insides/content/Misc/linux-misc-4.html
;; https://stackoverflow.com/questions/50260855/how-get-arguments-value-using-inline-assembly-in-c-without-glibc
;; i386: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/i386/start.S;h=91035fa83fb7ee38a0ca5834ba1d215b4a7f78e8;hb=HEAD
;; x86_64: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/x86_64/start.S;h=354d2e6ec78f0eaf9ab0f8ed665c2e5499388df0;hb=HEAD
(define-function __libc_start_main (main argc argv init fini rtld_fini stack_end)
  (linux-syscall linux/exit (main argc argv)))

(define-function __libc_csu_init ())
(define-function __libc_csu_fini ())
