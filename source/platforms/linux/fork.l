;;; -*- mode: lisp; coding: us-ascii -*-

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
  (let ((pid (linux-syscall linux/clone flags 0 0 0 0 0)))
    (if (<= 0 pid)
        (box <long> pid)
      (fatal "clone syscall returned with error "pid))))

(define-vm-function execve ((path <string>))
  (let* ((argv 0)
         (envp 0)
         (result (linux-syscall linux/execve
                                (<string>-elements path)
                                (address-of argv)
                                (address-of envp))))
    ;; result is -errno
    (fatal "execve returned with "result)))

(define-vm-function waitpid ((pid <long>))
  (let* ((status 0)
         (result (linux-syscall linux/wait4 pid (address-of status) 0 0)))
    (if (<= result 0)
        (fatal "wait4 syscall returned with "result)
      (box <long> status))))
