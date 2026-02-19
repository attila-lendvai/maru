;;; -*- mode: lisp; coding: us-ascii -*-

(load (concat-strings "source/platforms/libc/vm-functions.l"))

(define-vm-function fork ((flags <long> posix/SIGCHLD))
  (let ((pid (posix/fork)))
    (if (<= 0 pid)
        (box <long> pid)
      (fatal "fork returned with error: "pid))))

(define-vm-function execve ((path <string>))
  (let* ((argv 0)
         (envp 0)
         (result (posix/execve (string->C-string path)
                               (address-of argv)
                               (address-of envp))))
    ;; result is -errno
    (fatal "execve returned with "result)))

(define-vm-function waitpid ((pid <long>) (options <long> 0))
  (let* ((status 0)
         (result (posix/waitpid pid (address-of status) options)))
    (if (<= result 0)
        (fatal "waitpid returned with "result)
      (box <long> status))))
