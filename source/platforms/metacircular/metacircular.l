;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Platform API when running under a Maru evaluator.
;;;
;;; TODO:
;;;  - find out how to deal with strings. the libc platform provides cstring (zero terminated ASCII bytes)
;;;  - how to hook into the allocate of the super's GC
