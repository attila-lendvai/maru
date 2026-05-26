;;; -*- mode: lisp; coding: us-ascii -*-

;; (define-vm-function (libc/format ()) ((fmt <string>) oarg)
;;   (let ((typ (type-of oarg))
;;         (arg ()))
;;     ;; TODO use typecase
;;     (cond
;;       ((= typ <undefined>))
;;       ((= typ <long>)		(set arg (unbox <long> oarg)))
;;       ((= typ <string>)		(set arg (string->C-string oarg)))
;;       ((= typ <symbol>)		(set arg (unbox <symbol> oarg)))
;;       (else			(set arg oarg)))
;;     (let ((size 100)
;;           (result ()))
;;       (gc/let* ((buf ()))
;;         (while (not result)
;;           (set buf (allocate-data size))
;;           (let ((n (libc/snprintf buf size fmt arg)))
;;             (if (and (<= 0 n)
;;                      (< n size))
;;                 (set result (C-string->string buf))
;;               (set size (* size 2))))))
;;       result)))

;; NOTE: strictly speaking, the concept of cwd doesn't exist in the C
;; standard, but that makes the libc platform unable to bootstrap, so
;; we cheat and "introduce" it through a C wrapper function.
(define-vm-function working-directory ()
  (gc/let* ((buffer (allocate-data libc/PATH_MAX)))
    (C-string->string (or (libc/getcwd buffer libc/PATH_MAX)
                          (error "libc/getcwd failed")))))

(define-vm-function set-working-directory ((path <string>))
  (verbosity 1 (print-all *debug-output* "changing working directory to: "path"\n"))
  (unless (= 0 (libc/chdir (string->C-string path)))
    (error "set-working-directory: libc/chdir failed for: "path)))
