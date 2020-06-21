;;; -*- mode: lisp; coding: us-ascii -*-

(warn "--- boostrapping: early\n")

(switch-to-slave-module)

;; we must force the struct accessors to be unsafe, i.e. don't have any
;; typechecking in their expansion, just a simple oop-at.
(or bootstrapping?
    ;; KLUDGE eval: see comment in eval.l: otherwise the EXPAND of SET fails with an undefined variable
    (eval '(set *optimised* 1)))

(warn "--- boostrapping: boot.l\n")
