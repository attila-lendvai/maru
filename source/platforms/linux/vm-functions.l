;;; -*- mode: lisp; coding: us-ascii -*-

(define-function spawn-program (path argv envp)
  ;; (debug (platform/diag-print "spawn-program is about to spawn '"(string path)"'\n"))
  (let ((pid (linux-syscall linux/SYS_clone linux/SIGCHLD 0)))
    (if (= 0 pid)
        (let ((rc (linux-syscall linux/SYS_execve path argv envp)))
          ;; (platform/diag-print "execve error: "(long rc)"\n")
          (linux-syscall linux/SYS_exit 127))
      ;; (debug (platform/diag-print "child spawned\n"))
      pid)))

(define-function run-program (path argv envp)
  (let ((child-pid (spawn-program path argv envp))
        (status 0))
    (linux-syscall linux/SYS_wait4 child-pid (address-of status) 0 0)
    (let ((termsig (bitwise-and status 0x7f))
          (rc (bitwise-and (bitwise-shift status -8) 0xff)))
      (if (= 0 termsig)
          rc
        (+ 128 termsig)))))

(define-vm-function (spawn-program ()) ((path <string>))
  (box <long> (spawn-program (string->C-string path) 0 0)))

(define-vm-function (run-program ()) ((path <string>))
  (box <long> (run-program (string->C-string path) 0 0)))

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

(define-vm-function fork ((flags <long> linux/SIGCHLD))
  (let ((pid (linux-syscall linux/SYS_clone flags 0 0 0 0 0)))
    (if (<= 0 pid)
        (box <long> pid)
      (fatal "clone syscall returned with error "pid))))

(define-vm-function execve ((path <string>))
  (let* ((argv 0)
         (envp 0)
         (result (linux-syscall linux/SYS_execve
                                (<string>-elements path)
                                (address-of argv)
                                (address-of envp))))
    ;; result is -errno
    (fatal "execve returned with "result)))

(define-vm-function waitpid ((pid <long>))
  (let* ((status 0)
         (result (linux-syscall linux/SYS_wait4 pid (address-of status) 0 0)))
    (if (<= result 0)
        (fatal "wait4 syscall returned with "result)
      (box <long> status))))
