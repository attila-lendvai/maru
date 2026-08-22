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
  ;; FIXME posix open is in fact (int open (* int ...)) i.e. mode_t is
  ;; passed as variadic, which has different ABI rules, and it's not
  ;; implemented by our the compiler backends.
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

;; functions implemented in posix.c
(define-C-functions ()
  (pid_t posix/spawn-program (* * * int int))
  (pid_t posix/waitpid (pid_t int))
  (int posix/open (* int int)) ; KLUDGE to avoid variadic passing of mode_t
  (* posix/envp ())
  )

(define-function platform/acquire-memory (size)
  ;; KLUDGE we make all allocated memory executable.
  ;; some tests generate machine code and want to call it...
  (let* ((page-size	(posix/sysconf posix/_SC_PAGESIZE))
         (prot-flags	(+ (+ posix/PROT_READ posix/PROT_WRITE)
                           ;; FIXME darwin refuses to mmap WRITE +
                           ;; EXEC region. for now we only need
                           ;; exec for the JIT experiments, which
                           ;; only works on x86-64.
                           (eval-at-expand
                            (case +architecture+
                              (x86-64	posix/PROT_EXEC)
                              (else	0)))))
         (buf		(posix/mmap 0 (align-address-up size page-size)
                                    prot-flags
                                    (+ posix/MAP_PRIVATE posix/MAP_ANONYMOUS)
                                    -1 0)))
    ;;(platform/diag-print "mmap returned with "(pointer buf)"\n")
    (when (= buf posix/MAP_FAILED)
      (libc/diag-printf "mmap with prot %ld has returned with error %ld\n"
                        prot-flags libc/errno)
      (platform/halt 38))
    buf))
