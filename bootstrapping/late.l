;;; -*- mode: lisp; coding: us-ascii -*-

(warn "--- boostrapping: late\n")

;; we need accessors to expand to a simple OOP-AT, understood by the compiler
;; TODO investigate: this should be fine in (begin-compile), and *is* fine in later stages, but for some reason it's needed here in this stage
(set *force-trivial-accessors* 't)

(switch-to-host-module)

(warn "--- boostrapping: emit.l\n")
