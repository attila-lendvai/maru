;;; -*- mode: lisp; coding: us-ascii -*-

;;;
;;; The posix platform is some extras on top of libc, so we load it,
;;; and then define and redefine some more.
;;;

(set (feature platform/posix) true)

(require "source/platforms/libc/libc.l")

(require-cgrov "source/platforms/posix/posix")

(define-C-functions posix/
  ;;(* getcwd (* size_t))
  (* fdopen (int *))
  (int open (* int mode_t))
  (int close (int))
  (ssize_t read (int * size_t))
  (int mprotect (* size_t int))
  (* mmap (* size_t int int int off_t))
  (long sysconf (int))
  (pid_t fork ())
  (pid_t execve (* * *))
  (pid_t waitpid (pid_t * int))
  (* dlsym (* *))
  (int pipe (*))
  )

(define-function platform/acquire-memory (size)
  ;; KLUDGE we make all allocated memory executable.
  ;; some tests generate machine code and want to call it...
  (let* ((page-size (posix/sysconf posix/_SC_PAGESIZE))
         (buf (posix/mmap 0 (align-address-up size page-size)
                          (+ (+ posix/PROT_READ posix/PROT_WRITE)
                             posix/PROT_EXEC)
                          (+ posix/MAP_PRIVATE posix/MAP_ANONYMOUS)
                          -1 0)))
    ;;(platform/diag-print "mmap returned with "(pointer buf)"\n")
    (when (= buf posix/MAP_FAILED)
      (platform/diag-print "mmap returned with an error\n")
      (platform/halt))
    buf))
