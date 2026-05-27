;;; -*- mode: lisp; coding: us-ascii -*-

(define-form WIFEXITED   (status) `(= 0 (bitwise-and ,status 0x7f)))
(define-form WEXITSTATUS (status) `(bitwise-and (bitwise-shift ,status -8) 0xff))
(define-form WIFSIGNALED (status) `(>= (+ 1 (bitwise-and ,status 0x7f)) 2))
(define-form WTERMSIG    (status) `(bitwise-and ,status 0x7f))

;; NOTE these are here because BOX and other VM stuff is not yet
;; available in linux.l
(define-function posix/waitpid (pid options)
  (let ((status 0)
        result)
    (while (= (- linux/EINTR)
              (set result (syscall linux/SYS_wait4 pid (address-of status) options 0)))
      ;; keep trying
      )
    (if (< result 0)
        (fatal "waitpid returned with "result)
      (cond
        ((WIFEXITED status)	(WEXITSTATUS status))
        ((WIFSIGNALED status)	(+ 128 (WTERMSIG status)))
        (else			-1)))))

(define-function posix/spawn-program (path argv envp stdout-fd stderr-fd)
  ;; (debug (platform/diag-print "posix/spawn-program is about to spawn '"(string path)"'\n"))
  (let ((pid (syscall linux/SYS_clone linux/SIGCHLD 0)))
    (if (= 0 pid)
        (begin
          (when (< 0 stdout-fd)
            (syscall* linux/SYS_dup2 stdout-fd linux/STDOUT_FILENO)
            (syscall* linux/SYS_close stdout-fd))
          (when (< 0 stderr-fd)
            (syscall* linux/SYS_dup2 stderr-fd linux/STDERR_FILENO)
            (syscall* linux/SYS_close stderr-fd))
          (syscall* linux/SYS_execve path argv envp)
          (syscall linux/SYS_exit 127))
      ;; (debug (platform/diag-print "child spawned\n"))
      pid)))

(define-form posix/pipe (ptr)
  `(syscall* linux/SYS_pipe ,ptr))

(define-vm-function working-directory ()
  (gc/let* ((buffer (allocate-data linux/PATH_MAX)))
    (let ((len (syscall* linux/SYS_getcwd buffer linux/PATH_MAX)))
      ;; len contains the terminating zero byte
      (C-string->string* buffer (- len 1)))))

(define-vm-function set-working-directory ((path <string>))
  (verbosity 1 (print-all *debug-output* "changing working directory to: "path"\n"))
  (syscall* linux/SYS_chdir (string->C-string path)))

;;
;; !!!
;;
;; The raw system call interface on x86-64 and some other
;; architectures (including sh, tile, and alpha) is:
;;
;;     long clone(unsigned long flags, void *stack,
;;                int *parent_tid, int *child_tid,
;;                unsigned long tls);
;;
;; On x86-32, and several other common architectures (including score,
;; ARM, ARM 64, PA-RISC, arc, Power PC, xtensa, and MIPS), the order
;; of the last two arguments is reversed:
;;
;;     long clone(unsigned long flags, void *stack,
;;               int *parent_tid, unsigned long tls,
;;               int *child_tid);

;; (define-vm-function fork ((flags <long> linux/SIGCHLD))
;;   (box <long> (syscall* linux/SYS_clone flags 0 0 0 0 0)))

;; (define-vm-function execve ((path <string>))
;;   (let* ((argv 0)
;;          (envp 0)
;;          (result (syscall linux/SYS_execve
;;                                 (<string>-elements path)
;;                                 (address-of argv)
;;                                 (address-of envp))))
;;     ;; result is -errno
;;     (fatal "execve returned with "result)))

;; (define-vm-function waitpid ((pid <long>))
;;   (let (status)
;;     (syscall* linux/SYS_wait4 pid (address-of status) 0 0)
;;     (box <long> status)))
