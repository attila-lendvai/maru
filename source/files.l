;;; -*- mode: lisp; coding: us-ascii -*-

;; (define *load-path* ())

;; (when (= "-L" (car *command-line-arguments*))
;;   (pop *command-line-arguments*)
;;   (set *load-path* (pop *command-line-arguments*)))

;; KLUDGE the following is not well designed, they are here just to remain compatible with the original eval.l for the time being
(define-function file-open (path)
  ;;(assert (= <string> (type-of path)) "file-open: non-string path argument: " path)
  (libc/fopen path "r"))

(define-function file-close (handle)
  ;;(assert (= <target-vm-pointer> (type-of stream)) "close: inappropriate handle: " handle)
  (libc/fclose handle))

;; (define-function read-file-at-path (path)
;;   (read (concat-string (or *load-path* "") path)))

(define-function file-read-character (handle)
  ;;(assert (= <target-vm-pointer> (type-of handle)) "file-read-character: inappropriate handle: " handle)
  (libc/fgetc handle))

;; (define-function file-write-character (stream char)
;;   ;;(assert (= <target-vm-pointer> (type-of stream)) "file-write-character: inappropriate stream argument: " stream)
;;   (libc/fputc char stream))

;; (define-function contents-to-file-named (string path . options)
;;   (let ((f (or (file-open path "w")
;;                (error "cannot open for writing: "path)))
;;         (p (or (car options) file-write-character)))
;;     (for (i 0 (length string))
;;       (p (at string i) f))
;;     (close f)))

(define-function contents-of-file-named (path)
  (let ((f (or (file-open path)
               (error "cannot open for reading: "path)))
        (s (array))
        (c))
    (while (set c (file-read-character f))
      (array-append s c))
    (file-close f)
    (array->string s)))

;; TODO doesn't really belong here
(define-function format (fmt arg)
  ;;(assert (= <string> (type-of fmt)) "format: non-string fmt argument: " fmt)
  (libc/format fmt arg))
