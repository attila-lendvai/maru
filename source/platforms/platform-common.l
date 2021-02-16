;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Common defs for all platforms.

(define-form platform/print-diag strs
  `(let ()
     (platform/print-diag* ,@strs)
     (platform/print-diag* "\n")))

(define-form platform/print-diag-fmt (format . args)
  `(let ()
     (platform/print-diag-fmt* ,format ,@args)
     (platform/print-diag* "\n")))
