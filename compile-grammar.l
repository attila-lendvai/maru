;;; compile-grammar.l									-*- coke -*-
;;;
;;; ./eval compile-grammar.l <filename>.g ... | tee <filename>.l

(require "parser.l")
(require "peg.l")

(let* ((p (parse-files <peg> $definition $space *arguments*))
       (q (parse-list  <peg> $gen_cola p)))
  (or q (error "could not generate parser implementation"))
  (map dumpln q))

(exit 0)
