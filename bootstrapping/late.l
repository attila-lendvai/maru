;;; -*- mode: lisp; coding: us-ascii -*-

(warn "--- boostrapping: late\n")

;; we need accessors to expand to a simple OOP-AT, understood by the compiler
;; TODO investigate: this should be fine in (begin-compile), but for some reason it's not early enough there
(set *force-bootstrap-structure-accessors* 't)

(switch-to-host-module)

(warn "--- boostrapping: emit.l\n")
