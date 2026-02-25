;;; -*- mode: lisp; coding: us-ascii -*-

(load (concat-strings "source/platforms/libc/vm-functions.l"))

(define-vm-function posix/dlsym (handle (name <string>))
  (assert (or (is <lower-cell> handle) (is <long> handle)))
  (let* ((lower/handle (typecase handle
                         (<long>	(unbox <long> handle))
                         (<lower-cell>	(unbox <lower-cell> handle))
                         (else (error "unexpected type for posix/dlsym: "handle))))
         (ptr (lower/posix/dlsym lower/handle (string->C-string name))))
    (when ptr
      (box <lower-cell> ptr))))

(define-vm-function posix/fork ((flags <long> posix/SIGCHLD))
  (let ((pid (lower/posix/fork)))
    (if (<= 0 pid)
        (box <long> pid)
      (fatal "fork returned with error: "pid))))

(define-vm-function posix/execve ((path <string>))
  (let* ((argv 0)
         (envp 0)
         (result (lower/posix/execve (string->C-string path)
                                     (address-of argv)
                                     (address-of envp))))
    ;; result is -errno
    (fatal "execve returned with "result)))

(define-vm-function posix/waitpid ((pid <long>) (options <long> 0))
  (let* ((status 0)
         (result (lower/posix/waitpid pid (address-of status) options)))
    (if (<= result 0)
        (fatal "waitpid returned with "result)
      (box <long> status))))
