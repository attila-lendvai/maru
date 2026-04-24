;;; -*- mode: lisp; coding: us-ascii -*-

(load "source/compiler/target.l")

(require (concat-strings "source/compiler/emit-" *compiler-backend* ".l"))

(switch-to-target-env)

(load (host-value (concat-strings "source/platforms/"target/platform"/"target/platform".l")))
