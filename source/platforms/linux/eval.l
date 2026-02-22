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

;; https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;; http://www.dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html
;; https://0xax.gitbooks.io/linux-insides/content/Misc/linux-misc-4.html
;; https://stackoverflow.com/questions/50260855/how-get-arguments-value-using-inline-assembly-in-c-without-glibc
;; i386: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/i386/start.S;h=91035fa83fb7ee38a0ca5834ba1d215b4a7f78e8;hb=HEAD
;; x86_64: https://sourceware.org/git/?p=glibc.git;a=blob;f=sysdeps/x86_64/start.S;h=354d2e6ec78f0eaf9ab0f8ed665c2e5499388df0;hb=HEAD
;; argc and argv position on the stack: https://briancallahan.net/blog/20200808.html
;;
;; auxv, ELF auxiliary vector: contains information about the memory page size, metadata from the ELF file, etc
;;   https://amit.prasad.me/blog/before-main
;;   How programs get run: ELF binaries
;;   https://lwn.net/Articles/631631/
(define-function _start ()
  (debug (platform/diag-print "_start is alive\n"))

  ;; Stack layout, High memory
  ;; +---------------------+
  ;; | auxv[0].a_type = 0  | ; some AT_NULL nonsense, #defined as 0
  ;; | auxv[0].a_val = 0   |
  ;; +---------------------+
  ;; | ...                 |
  ;; +---------------------+
  ;; | auxv[0].a_type      |
  ;; | auxv[0].a_val       |
  ;; +---------------------+
  ;; | NULL                |
  ;; +---------------------+
  ;; | ...                 |
  ;; +---------------------+
  ;; | envp pointers       |
  ;; +---------------------+
  ;; | NULL                |
  ;; +---------------------+
  ;; | ... (argc times)    |
  ;; +---------------------+
  ;; | argv[0]             |
  ;; +---------------------+
  ;; | argc (int)          | <-- stack pointer points to argc
  ;; +---------------------+
  ;; Lower memory

  ;; TODO parse AT_PAGESZ (the page size)
  (let* ((sp (stack-pointer-on-entry))
         (argc (oop-at sp 0))
         (argv (+ sp (words-to-bytes 1))))
    (linux-syscall linux/SYS_exit
     (main/common argc argv
                  linux/STDIN_FILENO linux/STDOUT_FILENO linux/STDERR_FILENO
                  (lambda ()
                    (environment-define *maru*
                                        (string->symbol "feature/platform/linux")
                                        symbol/true))))))

(load "source/evaluator/vm-late.l")
