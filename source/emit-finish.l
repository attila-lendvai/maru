;;; -*- mode: lisp; coding: us-ascii -*-

(primitive/eval `(compile-env ,*target-env* (compiler 1)) *host-env*)
