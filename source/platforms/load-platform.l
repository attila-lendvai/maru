;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/compiler/emit-early.l")

(when (equal "x86" *compiler-backend*)
  (case (slave-value +word-size-in-bits+)
    (32 (set *compiler-backend* "i686"))
    (64 (set *compiler-backend* "x86-64"))))

(require (concat-strings "source/compiler/emit-" *compiler-backend* ".l"))

(switch-to-target-env)

(load (host-value (concat-strings "source/platforms/"target/platform"/"target/platform".l")))
