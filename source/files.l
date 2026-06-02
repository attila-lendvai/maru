;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/streams-min-late.l")

(define-form with-open-file (args . body)
  (let ((var (pop args))
        (path (pop args))
        (mode (pop args)))
    `(let ((,var (file-open-or-die ,path ,mode)))
       (let ((result (begin ,@body)))
         (file-close-or-die ,var)
         result))))

(define-form with-open-stream (args . body)
  `(with-open-file (__file__ ,@(rest args))
     (let ((,(first args) (file-stream __file__)))
       ,@body)))

;; (when (= "-L" (car *command-line-arguments*))
;;   (pop *command-line-arguments*)
;;   (set *load-path* (pop *command-line-arguments*)))

;; (define-function read-file-at-path (path)
;;   (read (concat-string (or *load-path* "") path)))

;; (define-function contents-to-file-named (string path . options)
;;   (let ((f (or (file-open-or-die path "w")
;;                (error "cannot open for writing: "path)))
;;         (p (or (car options) file-write-byte-or-die)))
;;     (for (i 0 (length string))
;;       (p (at string i) f))
;;     (close f)))

;; there's another impl in streams.l
;; (define-function contents-of-file-named (path)
;;   (let ((file	(file-open-or-die path "r"))
;;         (res	(string))
;;         c)
;;     (while (set c (file-read-byte file))
;;       (string-append res c))
;;     (file-close-or-die file)
;;     res))
