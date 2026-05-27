;;; -*- mode: lisp; coding: us-ascii -*-

(load (concat-strings "source/platforms/libc/vm-functions.l"))

;; functions implemented in posix.c
(define-C-functions ()
  (pid_t posix/spawn-program (* * * int int))
  (pid_t posix/waitpid (pid_t int))
  (* posix/envp ())
  )

(define-form posix/close-fd (fd)
  `(posix/close ,fd))

(define-function posix/read-byte (fd)
  (let ((byte 0)
        rc)
    ;; man 2 read
    (while (= (- posix/EINTR)
              (set rc (posix/read fd (address-of byte) 1)))
      ;; then try again
      )
    (case rc
      (0	-1)
      (1	byte)
      (else	(- rc)))))

(define-form posix/pipe (ptr)
  `(posix/pipe ,ptr))

(define-vm-function (posix/dlsym ()) (handle (name <string>))
  (let* ((lower/handle (typecase handle
                         (<long>	(unbox <long> handle))
                         (<lower-cell>	(unbox <lower-cell> handle))
                         (else (error "unexpected type for posix/dlsym: "handle))))
         (ptr (posix/dlsym lower/handle (string->C-string name))))
    (when ptr
      (box <lower-cell> ptr))))

;; (define-vm-function (fork ()) ()
;;   (let ((pid (posix/fork)))
;;     (if (<= 0 pid)
;;         (box <long> pid)
;;       (fatal "fork returned with error: "pid))))
;;
;; (define-vm-function (execve ()) ((path <string>) argv envp)
;;   (let* ((result (posix/execve (string->C-string path)
;;                                argv
;;                                envp)))
;;     ;; result is -errno
;;     (fatal "execve returned with "result)))
;;
;; (define-vm-function (waitpid ()) ((pid <long>) (options <long> 0))
;;   use lower_waitpid
;;   (let* ((status 0)
;;          (result 0))
;;     (while (= posix/EINTR
;;               (set result (posix/waitpid pid (address-of status) options)))
;;       ;; keep trying
;;       )
;;     (if (<= result 0)
;;         (fatal "waitpid returned with "result)
;;       (box <long> status))))
