;;; -*- mode: lisp; coding: us-ascii -*-

(define-function require-cgrov (base-path)
  (require (concat-strings base-path ".cgrov." +target-triple+ ".l")))
