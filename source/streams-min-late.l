;;; -*- mode: lisp; coding: us-ascii -*-

(define-function file-open-or-die (path mode)
  (or (file-open path mode)
      (error "file-open failed for path "path", mode "mode)))

(define-function file-close-or-die (handle)
  (or (file-close handle)
      (error "file-close failed for handle "handle)))

(define-function file-write-character-or-die (char stream)
  (or (file-write-character char stream)
      (error "file-write-character failed for stream "stream", char "char)))
