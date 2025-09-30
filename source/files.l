;;; -*- mode: lisp; coding: us-ascii -*-

;; TODO delme?

;; (define *load-path* ())

;; (when (= "-L" (car *command-line-arguments*))
;;   (pop *command-line-arguments*)
;;   (set *load-path* (pop *command-line-arguments*)))

;; (define-function read-file-at-path (path)
;;   (read (concat-string (or *load-path* "") path)))

;; (define-function contents-to-file-named (string path . options)
;;   (let ((f (or (file-open-or-die path "w")
;;                (error "cannot open for writing: "path)))
;;         (p (or (car options) file-write-character-or-die)))
;;     (for (i 0 (length string))
;;       (p (at string i) f))
;;     (close f)))

;; there's another impl in streams.l
;; (define-function contents-of-file-named (path)
;;   (let ((file	(file-open-or-die path "r"))
;;         (res	(string))
;;         c)
;;     (while (set c (file-read-character file))
;;       (string-append res c))
;;     (file-close-or-die file)
;;     res))
