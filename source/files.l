;;; -*- mode: lisp; coding: us-ascii -*-

;; (define *load-path* ())

;; (when (= "-L" (car *command-line-arguments*))
;;   (pop *command-line-arguments*)
;;   (set *load-path* (pop *command-line-arguments*)))

;; (define-function read-file-at-path (path)
;;   (read (concat-string (or *load-path* "") path)))

;; (define-function contents-to-file-named (string path . options)
;;   (let ((f (or (file-open path "w")
;;                (error "cannot open for writing: "path)))
;;         (p (or (car options) file-write-character)))
;;     (for (i 0 (length string))
;;       (p (at string i) f))
;;     (close f)))

;; (define-function contents-of-file-named (path)
;;   (let ((file	(or (file-open path "r")
;;                     (error "cannot open for reading: "path)))
;;         (res	(string))
;;         c)
;;     (while (set c (file-read-character file))
;;       (string-append res c))
;;     (file-close file)
;;     res))
