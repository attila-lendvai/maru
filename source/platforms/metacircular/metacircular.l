;;; -*- mode: lisp; coding: us-ascii -*-
;;;
;;; Platform API for running inside a Maru VM.
;;;
;;; TODO:
;;;  - eliminate the need for the gc/let* primitive
;;;  - find out how to deal with strings. the libc platform provides cstring (zero terminated ASCII bytes)
;;;  - how to hook into the allocate of the super's GC
