;;; -*- mode: lisp; coding: us-ascii -*-

(require "source/compiler/emit-early.l")

(when (and (equal "x86" *compiler-backend*)
           (= 64 (slave-value +word-size-in-bits+)))
  (set *compiler-backend* "x86-64"))

(require (concat-strings "source/compiler/emit-" *compiler-backend* ".l"))
